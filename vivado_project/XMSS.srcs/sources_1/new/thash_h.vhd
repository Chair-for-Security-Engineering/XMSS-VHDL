----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.xmss_main_typedef.ALL;
use work.params.ALL;
use ieee.numeric_std.all;


entity thash_h is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_thash_h_input_type;
           q     : out xmss_thash_h_output_type);
end thash_h;

architecture Behavioral of thash_h is
    alias m_in : xmss_thash_h_input_type_small is d.module_input;
    alias m_out : xmss_thash_h_output_type_small is q.module_output;

    type state_type is (S_IDLE, S_KEY, S_BITMASK_2, S_BITMASK_1, S_CORE_HASH_INIT, S_CORE_HASH, S_WAIT_FOR_HASH);
    type reg_type is record
        state : state_type;
        mask_input_1, mask_input_2, key : std_logic_vector(n*8-1 downto 0);
        done : std_logic;
    end record;
    
    signal hash_enable : std_logic;
    signal r, r_in : reg_type;
    signal block_ctr : unsigned(2 downto 0);
    
    signal DEBUG_THASH_EN : std_logic;
    signal DEBUG_THASH_DONE : std_logic;
begin
    
    -- Static output wiring    
	m_out.o <= r.key;
	m_out.done <= r.done;
	
	q.hash.id.block_ctr <= block_ctr;
    DEBUG_THASH_EN <= m_in.enable;
    combinational : process (r, d)
	   variable v : reg_type;
    begin
        v := r;
        DEBUG_THASH_DONE <= '0';
        -- Default assignments
        q.hash.len <= 768;
        q.hash.enable <= '0';
        
        block_ctr <= d.hash.id.block_ctr;
        q.hash.id.ctr <= to_unsigned(0, ID_CTR_LEN);
        
        v.done := '0';
        	    
     	case r.state is
     	      when S_IDLE =>
                  if m_in.enable = '1' then
                       -- Store the inputs
                       v.mask_input_1 := m_in.input_1;
                       v.mask_input_2 := m_in.input_2;
                       v.state := S_KEY;
                  end if;
              when S_KEY =>
                  -- Enable Hash for the key generation
                  q.hash.enable <= '1';
                  block_ctr <= "000";
                  
                  v.state := S_BITMASK_1;
              when S_BITMASK_1 =>
                  -- Generate the first bitmask
                  if d.hash.busy = '0' then
                        q.hash.enable <= '1';
                        q.hash.id.ctr <= to_unsigned(1, ID_CTR_LEN);
                        block_ctr <= "000";
                        v.state := S_BITMASK_2;
                  end if;
                  -- [Constant check]
                  -- if only one hash core is available, wait until key gen is done
                  -- Otherwise hash.busy =/= 1 in this stage
                  if HASH_CORES = 1 then
                      if d.hash.done = '1' then 
                            v.key := d.hash.o;
                      end if;
                  end if;
              when S_BITMASK_2 =>
                  -- Generate the 2. Bitmask
                  if d.hash.busy = '0' then
                        q.hash.enable <= '1';
                        q.hash.id.ctr <= to_unsigned(2, ID_CTR_LEN);
                        block_ctr <= "000";
                        v.state := S_WAIT_FOR_HASH;
                  end if;
                  -- [Constant check]
                  -- if less than 3 hash cores are connected, the next hash call
                  -- will not compute in paralell -> wait until hash done
                  if d.hash.done = '1' then
                        if d.hash.done_id.ctr = to_unsigned(0, ID_CTR_LEN) then
                            v.key := d.hash.o;
                        else
                            v.mask_input_1 := r.mask_input_1 xor d.hash.o;
                        end if;
                  end if;
              when S_WAIT_FOR_HASH =>
                  -- wait until key and Bitmask are generated
                  if d.hash.done = '1' then
                    if d.hash.done_id.ctr = to_unsigned(0, ID_CTR_LEN) then
                            v.key := d.hash.o;
                        elsif d.hash.done_id.ctr= to_unsigned(1, ID_CTR_LEN) then
                            v.mask_input_1 := r.mask_input_1 xor d.hash.o;
                        else
                            v.mask_input_2 := r.mask_input_2 xor d.hash.o;
                            v.state := S_CORE_HASH_INIT;
                        end if;
                   end if;
              when S_CORE_HASH_INIT =>
                    -- Hash the inputs with keys and bitmasks
                    q.hash.enable <= '1';
                    q.hash.len <= 1024;
                    q.hash.id.ctr <= to_unsigned(3, ID_CTR_LEN);
                    block_ctr <= "100";
                    v.state := S_CORE_HASH;
              when S_CORE_HASH =>
                  if d.hash.done = '1' then
                      v.key := d.hash.o;
                      v.done := '1';
                      DEBUG_THASH_DONE <= '1';
                      v.state := S_IDLE;
                  end if;
    end case;
    r_in <= v;
end process; 

-- Multiplex the hash input based on block_ctr signal
hash_mux : process(block_ctr, m_in, r.mask_input_1, r.mask_input_2, d.pub_seed, r.key, d.hash.id.ctr)
begin
    case block_ctr is
        when "000" =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));      
        when "001" =>
                q.hash.input <= d.pub_seed;
        when "010"=>
                q.hash.input <= x"00000000" & x"00000000" & x"00000000" & m_in.address_3 & m_in.address_4 
                                & m_in.address_5 & m_in.address_6 & std_logic_vector(resize(d.hash.id.ctr, 32));
        when "100"  => 
                q.hash.input <= std_logic_vector(to_unsigned(1, n*8));
        when "101" => 
                q.hash.input <= r.key;
        when "110" =>
                q.hash.input <= r.mask_input_1;
        when "111" =>
                q.hash.input <= r.mask_input_2;
        when others => -- Dont care in others case
                q.hash.input <= (others => '-');
    end case;
end process;

sequential : process(clk)
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;
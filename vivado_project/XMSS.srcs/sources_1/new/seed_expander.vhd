----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.params.ALL;
use work.wots_comp.ALL;

entity seed_expander is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in seed_expander_input_type;
           q     : out seed_expander_output_type);
end seed_expander;

-- Private Key Generation for WOTS

architecture Behavioral of seed_expander is
    type state_type is (S_IDLE, S_KEYGEN);
    type reg_type is record 
        state : state_type;
        ctr : integer range 0 to wots_len+1;        
    end record;
    
    signal block_ctr : unsigned(1 downto 0);
    signal last : std_logic;
    signal r, r_in : reg_type;	   
begin

    -- Assign out signals
	q.bram.en <= '1';
	q.bram.din <= d.hash.o;
	q.bram.addr <= std_logic_vector(BRAM_WOTS_KEY + resize(d.hash.done_id.ctr, BRAM_ADDR_SIZE));
	
	q.hash.len <= 768;
	q.hash.id.block_ctr <= (others => '0');
	q.hash.id.ctr <= to_unsigned(r.ctr, ID_CTR_LEN);
	
	last <= '1' when r.ctr = wots_len else '0';
	
	combinational : process (r, d, last)
	   variable v : reg_type;
	begin
	    v := r;
	    
	    -- Default assignments        
        q.bram.wen <= '0';
        q.hash.enable <= '0';
	    q.done <= '0';
	    
	    block_ctr <= d.hash.id.block_ctr(1 downto 0);

        case r.state is
            when S_IDLE =>
               if d.enable = '1' then
                    v.ctr := 0;
                    v.state := S_KEYGEN;
                end if;
             when S_KEYGEN =>
                -- If a hash core is available, start a new SK Gen as long as last = 0
                if d.hash.busy = '0' and last = '0' then
                    block_ctr <= "00";
                    q.hash.enable <= '1';
                    v.ctr := r.ctr + 1;
                end if;
                
                -- When the hash core is done, write SK[i] to an address dependent on the d.hash.id.ctr
                q.bram.wen <= d.hash.done;
                
                -- When all hash cores are ideling, done = 1 and return ideling.
                if d.hash.idle = '1' and last = '1' then
                    q.done <= '1';
                    v.state := S_IDLE;
                end if;
        end case;
            
        r_in <= v;
	end process;
	
	
	hash_mux : process(block_ctr, d.input, d.hash.id.ctr) 
	begin
	   case block_ctr is
            when "00" =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));      
            when "01" =>
                q.hash.input <= d.input;
            when "10" => -- 10
                q.hash.input <= std_logic_vector(to_unsigned(0, 256-ID_CTR_LEN) & d.hash.id.ctr);
            when others => 
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

----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.params.ALL;
use work.xmss_main_typedef.ALL;
use IEEE.NUMERIC_STD.ALL;


entity hash_message is
    port(
        clk   : in std_logic;
        reset : in std_logic;
        d     : in hash_message_input_type;
        q     : out hash_message_output_type);
end hash_message;

architecture Behavioral of hash_message is
    alias m_in : hash_message_input_type_small is d.module_input;
    alias m_out : hash_message_output_type_small is q.module_output;
        
    type state_type is (S_IDLE, S_HASH_MESSAGE_INIT, S_HASH_MESSAGE_CORE, S_WAIT, S_ABSORB_R, S_ABSORB_INDEX, S_ABSORB_ROOT, S_ABSORB_MESSAGE);
    type reg_type is record
        state : state_type;
        ctr : integer range 0 to 1023;
        mhash : std_logic_vector(n*8-1 downto 0);
    end record;
    signal bram_select : unsigned(1 downto 0);
    signal hash_select : unsigned(1 downto 0);
    signal r, r_in : reg_type;
begin

    -- Static output wiring
    q.hash.len <= 4*8*n + m_in.mlen;
    q.hash.id.ctr <= to_unsigned(0, ID_CTR_LEN);
    q.hash.id.block_ctr <= "000";
    
    q.bram.en <= '1';
    q.bram.wen <= '0';
    q.bram.din <= (others => '-');
    
    m_out.mhash <= r.mhash;
    
    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;
	    
	    -- Default assignments
	    m_out.done <= '0';
	    q.hash.enable <= '0';
	    bram_select <= "00";
	    hash_select <= "00";
	    
	    if HASH_FUNCTION = "SHA" then
	        -- When using SHA, the data can be loaded from BRAM between mnext signals
	        -- For SHAKE, the mnext signals are too close for BRAM access, thus we need wait cycles
	        -- The SHAKE version of this algorithm works for SHA as well but is obviously slower and
	        -- larger.
            case r.state is
               when S_IDLE =>
                   if m_in.enable = '1' then
                       v.ctr := 0;
                       v.state := S_HASH_MESSAGE_INIT;
                   end if;                  
                 when S_HASH_MESSAGE_INIT =>
                       -- Start hashing
                       q.hash.enable <= '1';
                       v.state := S_ABSORB_R;
                 when S_ABSORB_R =>
                       hash_select <= "01";
                       if d.hash.mnext = '1' then
                          v.state := S_ABSORB_ROOT;
                      end if;
                 when S_ABSORB_ROOT =>
                       hash_select <= "01";
                       bram_select <= "01"; -- ROOT
                       if d.hash.mnext = '1' then
                          v.state := S_ABSORB_INDEX;
                      end if;
                 when S_ABSORB_INDEX =>
                      hash_select <= "10"; -- INDEX
                      if d.hash.mnext = '1' then
                         v.state := S_ABSORB_MESSAGE;
                      end if;
                 when S_ABSORB_MESSAGE =>
                      hash_select <= "01"; -- BRAM
                      bram_select <= "10"; -- MESSAGE
                      -- on every mnext, increase cnt by 1 undtil done = 1
                      if d.hash.mnext = '1' then
                          v.ctr := r.ctr + 1;
                      end if;
                      if d.hash.done = '1' then
                          v.mhash := d.hash.o;
                          m_out.done <= '1';
                          v.state := S_IDLE;
                      end if;     
                  when others => null;	          
            end case;
	    else -- SHAKE version
	        case r.state is
	           when S_IDLE =>
	               if m_in.enable = '1' then
                       v.ctr := 0;
                       v.state := S_WAIT;
                   end if; 
               when S_WAIT =>
                    v.state := S_HASH_MESSAGE_INIT;
               when S_HASH_MESSAGE_INIT =>  -- Prefix absorb
                       -- Start hashing
                       q.hash.enable <= '1';
                       bram_select <= "01"; -- ROOT
                       v.state := S_ABSORB_R;  
	           when S_ABSORB_R =>
	               hash_select <= "01"; -- BRAM
	               bram_select <= "10"; -- Message
	               v.state := S_ABSORB_ROOT;
	           when S_ABSORB_ROOT =>
	               hash_select <= "01"; -- BRAM
	               bram_select <= "10"; -- MESSAGE
	               v.state := S_ABSORB_INDEX;
	           when S_ABSORB_INDEX =>
	               hash_select <= "10";  -- Index
	               bram_select <= "10"; -- MESSAGE
	               v.state := S_ABSORB_MESSAGE;
	           when S_ABSORB_MESSAGE =>
	               hash_select <= "01"; -- BRAM
	               if d.hash.done = '1' then
                          v.mhash := d.hash.o;
                          m_out.done <= '1';
                          v.state := S_IDLE;
                   end if;    
	           when others => null;
	        end case;  
	    end if;
	    
	    
     	r_in <= v;
    end process; 
    
    -- Select the input to the hash function
    hash_mux : process(hash_select, m_in.index, d.bram.dout)
    begin
        case hash_select is
            when "00" =>
                    q.hash.input <= std_logic_vector(to_unsigned(2, n*8));
            when "10" =>
                    q.hash.input <= std_logic_vector(resize(m_in.index, n*8));
            when others =>
                    q.hash.input <= d.bram.dout; -- Root node or message block
        end case;
    end process; 
    
    -- Select the bram address
    bram_mux : process(bram_select, r.ctr)
    begin
        case bram_select is
            when "00" =>
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 1, BRAM_ADDR_SIZE)); -- R
            when "01" =>
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_PK, BRAM_ADDR_SIZE)); -- Root
            when "10" => -- 3...
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_MESSAGE + r.ctr, BRAM_ADDR_SIZE)); -- Message
            when others =>
                    q.bram.addr <= (others => '-');
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

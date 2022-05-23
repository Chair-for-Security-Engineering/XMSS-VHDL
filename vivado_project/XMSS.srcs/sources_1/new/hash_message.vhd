----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.04.2020 08:32:00
-- Design Name: 
-- Module Name: hash_message - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.params.ALL;
use work.xmss_main_typedef.ALL;
--use work.wots_comp.ALL;
use work.xmss_functions.ALL;
use work.wots_functions.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
    type state_type is (S_IDLE, S_HASH_MESSAGE_INIT, S_HASH_MESSAGE_CORE);
    type reg_type is record
        state : state_type;
        block_ctr : integer range 0 to 4;
       -- bram_state : integer range 0 to 4;
        ctr : integer range 0 to 1023;
        hash_enable : std_logic;
    end record;
    signal r, r_in : reg_type;
begin

    q.hash.len <= 4*8*n + m_in.mlen;
    q.hash.enable <= '1' when r.hash_enable = '1' else '0';
    
    q.bram.en <= '1';
    q.bram.wen <= '0';
    q.bram.din <= (others => '0');
    
    m_out.o <= d.hash.o;
    
    
    combinational : process (r, d)
	   variable v : reg_type;

	begin
	    v := r;
	    
	    v.hash_enable := '0';
	    m_out.done <= '0';
	    case v.state is
	       when S_IDLE =>
	           if m_in.enable = '1' then
	               v.block_ctr := 0;
	               --v.bram_state := 0;
	               v.ctr := 0;
	               v.state := S_HASH_MESSAGE_INIT;
	               v.hash_enable := '1';            
	           end if;                  
     	     when S_HASH_MESSAGE_INIT =>
     	          if d.hash.mnext = '1' then
     	              v.block_ctr := r.block_ctr +1;
     	              if v.block_ctr = 4 then
     	                  v.state := S_HASH_MESSAGE_CORE;
     	              end if;
     	          end if;
     	     when S_HASH_MESSAGE_CORE =>
     	          if d.hash.mnext = '1' then
     	              v.ctr := r.ctr + 1;
     	          end if;
     	          if d.hash.done = '1' then
     	              m_out.done <= '1';
     	              v.state := S_IDLE;
     	          end if;     	          
	    end case;
	    
	    
     	r_in <= v;
    end process; 
    
    hash_mux : process(r.block_ctr, m_in.index, d.bram.dout)
    begin
        case r.block_ctr is
            when 0 =>
                    q.hash.input <= std_logic_vector(to_unsigned(2, n*8));
            when 3 =>
                    q.hash.input <= std_logic_vector(to_unsigned(0, n*7)) & m_in.index;
            when others =>
                    q.hash.input <= d.bram.dout;
        end case;
    end process; 
    
    bram_mux : process(r.block_ctr, r.ctr)
    begin
        case r.block_ctr is
            when 0|1 =>
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG +1, BRAM_ADDR_SIZE)); -- R
            when 2 =>
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_PK, BRAM_ADDR_SIZE)); -- Root
            --when 3 =>
            --        q.bram.addr <= std_logic_vector(to_unsigned(BRAM_MESSAGE, BRAM_ADDR_SIZE)); -- Message
            when others => -- 3 / 4
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_MESSAGE + r.ctr, BRAM_ADDR_SIZE)); -- Message
        end case;
    end process;
    

    
    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       --r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;

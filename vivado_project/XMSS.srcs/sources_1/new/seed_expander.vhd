----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.02.2020 11:48:25
-- Design Name: 
-- Module Name: seed_expander - Behavioral
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
use ieee.numeric_std.all;
use work.params.ALL;
use work.wots_comp.ALL;


entity seed_expander is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in seed_expander_input_type;
           q     : out seed_expander_output_type);
end seed_expander;

architecture Behavioral of seed_expander is
    type state_type is (S_IDLE, S_KEYGEN_INIT, S_KEYGEN);
    type reg_type is record 
        state : state_type;
        cnt : integer range 0 to wots_len-1;
        block_ctr : unsigned(1 downto 0);
    end record;

    signal r, r_in : reg_type;	   
begin

	q.bram.en <= '1';
	q.bram.din <= d.hash.o;
	q.hash.len <= 768;
	
	combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;
	    -- BRAM
        q.bram.wen <= '0';

	    -- Hash
        q.hash.enable <= '0';
        
        -- Self
	    q.done <= '0';

        case r.state is
            when S_IDLE =>
               q.hash.enable <= '0';
               v.cnt := 0;
               if d.enable = '1' then
                    v.block_ctr := "00";
                    v.state := S_KEYGEN_INIT;
                end if;
             when S_KEYGEN_INIT =>
                q.hash.enable <= '1';
                v.state := S_KEYGEN;
             when S_KEYGEN =>
                if d.hash.mnext = '1' then
                    v.block_ctr := r.block_ctr + 1;
                end if;
                if d.hash.done = '1' then
                    q.bram.wen <= '1';
                    if r.cnt = wots_len-1 then
                        q.done <= '1';
                        v.state := S_IDLE;
                    else
                        v.state := S_KEYGEN_INIT;
                        v.cnt := r.cnt + 1;
                        v.block_ctr := "00";
                    end if;
                end if;
        end case;
        
           q.bram.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_SK + r.cnt, BRAM_ADDR_SIZE)); 
        r_in <= v;
	end process;
	
	hash_mux : process(r.block_ctr, d.input) 
	begin
	   case r.block_ctr is
            when "00" =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));      
            when "01" =>
                q.hash.input <= d.input;
            when others => -- 10
                q.hash.input <= std_logic_vector(to_unsigned(r.cnt, 256));
        end case;
	end process;
	
	
	
	
    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       --v.state := S_IDLE;
	       --v.block_ctr := "00";
	       --v.cnt := 0;
	       --r <= v;
	       r.state <= S_IDLE;
	    else
		   r <= r_in;
        end if;
       end if;
	end process;
	
	
end Behavioral;

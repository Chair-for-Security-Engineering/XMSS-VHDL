----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.02.2020 09:46:29
-- Design Name: 
-- Module Name: wots_chain - Behavioral
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
use work.wots_comp.ALL;
use work.wots_functions.ALL;
use work.sha_comp.ALL;
use work.params.ALL;

entity wots_chain is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in wots_chain_input_type;
           q     : out wots_chain_output_type);
end wots_chain;
    
architecture Behavioral of wots_chain is
    constant cnt_padding : std_logic_vector(31-WOTS_W downto 0) := std_logic_vector(to_unsigned(0, 32-WOTS_W));
    
    type state_type is (S_IDLE, S_KEY, S_LOOP, S_BITMASK_INIT, S_BITMASK, S_CORE_HASH_INIT, S_CORE_HASH, S_DELAY);
    type reg_type is record 
        state : state_type;
        block_ctr : unsigned(3 downto 0);
        cnt : unsigned(WOTS_W-1 downto 0);-- range 0 to WOTS_W-1;
        X : std_logic_vector(n*8-1 downto 0);
        key : std_logic_vector(n*8-1 downto 0);
        --ADDR : addr;
        
    end record;
    --signal absorb_input : absorb_message_input_type;
    signal r, r_in : reg_type;
    --signal address : addr;  


begin
    
    q.hash.len <= 768;

    combinational : process (r, d)
	   variable v : reg_type;
	begin
	   v := r;
	  
	   -- hash
	   q.hash.enable <= '0';
	   
	   -- self
	   q.done <= '0';
	   q.done_inter <= '0';
	   q.result <= r.X;
	     	       
	   case r.state is	   
	       when S_IDLE =>
	           --address := d.address;
	           v.block_ctr := "0000";
	           if d.enable = '1' then
	               v.X := d.X;
	               v.cnt := to_unsigned(d.start,WOTS_W);
	               v.state := S_LOOP;
	               if d.steps = 0 then
	                   v.state := S_DELAY;
	               end if;
	           end if;
	       when S_DELAY =>
	           v.state := S_LOOP; -- Chain must take at least two clock cycles
           when S_LOOP =>
              -- Loop bound also checks whether we have increased block_ctr already and thus only need to absorb the next block
              -- Entry point of the loop
              if r.cnt = d.signature_step then
                    q.done_inter <= '1';
              end if;
              if (r.cnt < (d.start + d.steps)) then --and r.cnt < WOTS_W) then
                    q.hash.enable <= '1';
                    v.state := S_KEY;                    
              else 
                    q.done <= '1';
                    v.state := S_IDLE;
              end if;
           when S_KEY =>
                if d.hash.mnext = '1' then
                    v.block_ctr := r.block_ctr + 1;
                end if;
                if d.hash.done = '1' then
                    v.state := S_BITMASK_INIT;
                    v.block_ctr := r.block_ctr + 1;
                end if;
           when S_BITMASK_INIT =>
                  v.key := d.hash.o;                        
                  q.hash.enable <= '1';
                  
                  v.state := S_BITMASK;
           when S_BITMASK =>
              if d.hash.mnext = '1' then
                  v.block_ctr := r.block_ctr + 1;
              end if;
              if d.hash.done = '1' then
                  v.state := S_CORE_HASH_INIT;
                  v.block_ctr := r.block_ctr + 1;
              end if;
           when S_CORE_HASH_INIT =>
                q.hash.enable <= '1';
                v.state := S_CORE_HASH;
           when S_CORE_HASH =>
              -- Generate the output of the chaining iteration by hahsing the masked input together with the generated key
              --v.bitmask := d.hash.o;
              if d.hash.mnext = '1' then
                  v.block_ctr := r.block_ctr + 1;
              end if;
              if d.hash.done = '1' then
                    v.cnt := r.cnt + 1;
                    v.X := d.hash.o;   
                    v.block_ctr := "0000";                    
                    v.state := S_LOOP;
              end if;
	   end case;
	   
       --q.result <= r.X;
	   r_in <= v;
	end process;
	
	hash_mux : process(r.block_ctr, d) is
	begin
	   case r.block_ctr is
            when "0000"|"0011" =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));      
            when "0001"|"0100" =>
                q.hash.input <= d.SEED;
            when "0010" =>
                q.hash.input <= x"00000000" & x"00000000" & x"00000000" & x"00000000" & d.address_4 
                                & d.address_5 & cnt_padding & std_logic_vector(r.cnt) & x"00000000";
            when "0101" =>
                q.hash.input <= x"00000000" & x"00000000" & x"00000000" & x"00000000" & d.address_4 
                                & d.address_5 & cnt_padding & std_logic_vector(r.cnt) & x"00000001";
            when "0110" =>
                q.hash.input <= std_logic_vector(to_unsigned(0, n*8));
            when "0111" => 
                q.hash.input <= r.key;
            when others => -- when "1000"=> 
                q.hash.input <= r.X xor d.hash.o;
       end case;
	end process;
	
    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       --v.block_ctr := (others => '0');
	       --v.X := (others => '0');
	       --v.key := (others => '0');
	       --v.cnt := (others => '0');
	       --r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
       
	end process;
	
	
end Behavioral;

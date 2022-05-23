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

entity wots_key_and_mask_gen is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in wots_k_and_m_input_type;
           q     : out wots_k_and_m_output_type);
end wots_key_and_mask_gen;
    
architecture Behavioral of wots_key_and_mask_gen is
    type state_type is (S_WAIT, S_IDLE, S_MSG_ABSORB, S_WAIT_FOR_MNEXT);
    type reg_type is record 
        state : state_type;
        X : std_logic_vector(255 downto 0);
        start : integer;
        steps : integer;
        cnt : integer;
        o : std_logic_vector(255 downto 0);
        --hash_input : sha_input_type;
        --hash_output: sha_output_type;
        --hash_reset: std_logic;
        hash_enable: std_logic;
        wait_ctr : Integer; -- Todo: Remove Wait Cycles for SHA
        absorb_ctr : Integer;
    end record;
    signal r, r_in : reg_type;
    signal hash_message : std_logic_vector(31 downto 0);
    signal hash_last, hash_done, hash_mnext : std_logic;
    signal hash : std_logic_vector(255 downto 0);
    
    
begin

    --------- Wire up the hash module:
	sha : entity work.sha256
	port map(
		clk     => clk,
		reset   => reset,
		d.enable  => r.hash_enable,
		d.last    => hash_last,
		d.message => hash_message,
		q.done    => hash_done,
		q.mnext   => hash_mnext,
		q.hash    => q.o);

    combinational : process (r, d, hash_mnext, hash_done)
	   variable v : reg_type;
	   
	begin
	   v := r;
	   -- TODO XMMS_HASH_PADDING FEHLT NOCH
	   case r.state is
	       when S_IDLE =>
	           if d.enable = '1' then
	               v.State := S_MSG_ABSORB;
                   v.hash_enable := '1';
                   v.absorb_ctr := 0;
               else
                   v.hash_enable := '0';
	           end if;
	           q.done <= '0';
	           hash_last <= '0';
           when S_MSG_ABSORB =>
              -- PUB SEED
              v.wait_ctr := 0;
              if v.absorb_ctr < 8 then
                hash_message <= d.input((8*n)-(v.absorb_ctr)*32-1 downto (8*n)-(v.absorb_ctr)*32- 32);
              elsif v.absorb_ctr < 16 then
                hash_message <= d.key((8*n)-(v.absorb_ctr-8)*32-1 downto (8*n)-(v.absorb_ctr-8)*32- 32);
                if v.absorb_ctr = 15 then
                    v.state := S_WAIT_FOR_MNEXT;
                end if;
              elsif v.absorb_ctr = 23 then
                hash_message <= (31 => '1', others => '0');
              elsif v.absorb_ctr < 31 then
                hash_message <= (others => '0');
              elsif v.absorb_ctr = 31 then
                hash_message <= (10 => '1', others => '0');
                hash_last <= '1';
                v.hash_enable := '0';
                v.state := S_WAIT;
                -- absorb padding
              end if;
              v.absorb_ctr := v.absorb_ctr + 1;
              
              
              --v.state := S_WAIT;
           when S_WAIT_FOR_MNEXT => 
              if v.wait_ctr = 0 and hash_mnext = '1' then
                v.wait_ctr := v.wait_ctr +1;
              elsif v.wait_ctr /= 0 then
                if v.wait_ctr = 2 then
                    v.state := S_MSG_ABSORB;
                end if;
                v.wait_ctr := v.wait_ctr +1;
              end if;
	       when S_WAIT =>
	           hash_last <= '1';
	           if hash_done ='1' then
	               q.done <= '1';
	               v.state := S_IDLE;
	           end if;
	   end case;
        r_in <= v;
	end process;
	
    sequential : process(clk)
    variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       v.state := S_IDLE;
	       v.cnt := 0;
	       r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
	end process;
	
	
end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.01.2020 09:47:24
-- Design Name: 
-- Module Name: wots_fsm - Behavioral
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
use IEEE.STD_LOGIC_MISC;

entity wots_fsm is
    Port (  clk : in STD_LOGIC;
            reset  : in  std_logic;
            enable : in STD_LOGIC;
            mode : in STD_LOGIC_VECTOR(3 downto 0));
end wots_fsm;

architecture Behavioral of wots_fsm is
    type states is (S_IDLE, S_SK_GEN, S_PK_GEN, S_SIGN, S_VRFY);
    signal state, next_state : states;
begin
    fsm : process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= S_IDLE;
			else
				state <= next_state;
			end if;
		end if;
	end process;
	
	-- FSM Transition Logic for WOTS 
	-- Default State is IDLE, the mode Signal selects the mode if enable is high
	--
	-- Listing of states
	-- Mode 000    IDLE: The module is waiting for input
	-- Mode 001    S_SK_GEN: The secret key is being generated
	-- Mode 010    S_PK_GEN: The public key is being generated
	-- Mode 011    S_SIGN:   Compuatation of signature
	-- Mode 100    S_VRFY:   Signature verification 
	
	transition : process(state, enable)
	begin
		next_state <= state;

		case state is
		
		when S_IDLE =>
			if enable = '1' then
				 if mode = "001" then
				    next_state <= S_SK_GEN;
				 elsif mode = "010" then
				    next_state <= S_PK_GEN;
				 elsif mode = "011" then
				    next_state <= S_SIGN;
				 elsif mode = "100" then
				    next_state <= S_VRFY;
				 end if;
			else
			     next_state <= S_IDLE;
			end if;

		end case;
	end process;

end Behavioral;

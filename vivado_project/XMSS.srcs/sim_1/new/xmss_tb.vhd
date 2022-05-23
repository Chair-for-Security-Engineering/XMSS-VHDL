----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.04.2020 09:13:53
-- Design Name: 
-- Module Name: xmss_tb - Behavioral
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

entity xmss_tb is
    constant clk_period : time := 5 ns;

	signal clk, reset : std_logic;
	
	signal message : std_logic_vector(n*2*8-1 downto 0);
	
	--signal pk_out : xmss_pk;
	
    
    signal xmss_interface_in : xmss_input_type;
    signal xmss_interface_out : xmss_output_type;
end xmss_tb;

architecture Behavioral of xmss_tb is

begin
    uut : entity work.xmss
	port map(
		clk     => clk,
		reset => reset,
		d => xmss_interface_in,
		q => xmss_interface_out);
    
    process
    begin
		clk <= '1';
		wait for clk_period / 2;
    
		clk <= '0';
		wait for clk_period / 2;
	end process;

    process
    begin
        reset <= '1';
        xmss_interface_in.enable <= '0';
        wait for 2 * clk_period;
        reset <= '0';
        wait for 2 * clk_period;
        xmss_interface_in.message <= x"3833653732376265633437323133363862663265306563666666303931333461";
        xmss_interface_in.mlen <= 32*8;
        --xmss_interface_in.signature <= xmss_sig;
        xmss_interface_in.true_random <= x"373163643365323665313163666664346165326164373833666631326137373065306265326133656330353161613938383333616161666664646364626339626464393536353639653131323064643730343635333461663034393838373266";
        xmss_interface_in.mode <= "00";
        xmss_interface_in.enable <= '1';
        
        wait for 1*clk_period;
        xmss_interface_in.enable <= '0';
        
        wait until xmss_interface_out.done ='1';
                
        wait for 1*clk_period;
        xmss_interface_in.mode <= "01";
       -- xmss_interface_in.pk <= pk_out;
        xmss_interface_in.enable <= '1';
        wait for 1*clk_period;
        xmss_interface_in.enable <= '0';
        
        wait until xmss_interface_out.done ='1';
        
        
        wait for 1*clk_period;
        xmss_interface_in.mode <= "10";
        xmss_interface_in.enable <= '1';
        wait for 1*clk_period;
        xmss_interface_in.enable <= '0';
        
         wait until xmss_interface_out.done ='1';
         
--         wait for 1*clk_period;
--        xmss_interface_in.mode <= "01";
--       -- xmss_interface_in.pk <= pk_out;
--        xmss_interface_in.enable <= '1';
--        wait for 1*clk_period;
--        xmss_interface_in.enable <= '0';
        
--        wait until xmss_interface_out.done ='1';
        
        
--        wait for 1*clk_period;
--        xmss_interface_in.mode <= "10";
--        xmss_interface_in.enable <= '1';
--        wait for 1*clk_period;
--        xmss_interface_in.enable <= '0';
        
--         wait until xmss_interface_out.done ='1';
         
--         wait for 1*clk_period;
--        xmss_interface_in.mode <= "01";
--       -- xmss_interface_in.pk <= pk_out;
--        xmss_interface_in.enable <= '1';
--        wait for 1*clk_period;
--        xmss_interface_in.enable <= '0';
        
--        wait until xmss_interface_out.done ='1';
        
        
--        wait for 1*clk_period;
--        xmss_interface_in.mode <= "10";
--        xmss_interface_in.enable <= '1';
--        wait for 1*clk_period;
--        xmss_interface_in.enable <= '0';
        
--         wait until xmss_interface_out.done ='1';
         
--          wait for 1*clk_period;
--        xmss_interface_in.mode <= "01";
--       -- xmss_interface_in.pk <= pk_out;
--        xmss_interface_in.enable <= '1';
--        wait for 1*clk_period;
--        xmss_interface_in.enable <= '0';
        
--        wait until xmss_interface_out.done ='1';
        
        
--        wait for 1*clk_period;
--        xmss_interface_in.mode <= "10";
--        xmss_interface_in.enable <= '1';
--        wait for 1*clk_period;
--        xmss_interface_in.enable <= '0';
        
--         wait until xmss_interface_out.done ='1';
         
         
        wait;
    end process;
end Behavioral;


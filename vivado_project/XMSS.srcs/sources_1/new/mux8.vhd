----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.07.2020 10:50:20
-- Design Name: 
-- Module Name: mux8 - Behavioral
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


entity mux8 is
--Generic (SIGNAL_SIZE : integer := 255); -- must be multiple of n
port(
  a0      : in  std_logic_vector(255 downto 0);
  a1      : in  std_logic_vector(255 downto 0);
  a2      : in  std_logic_vector(255 downto 0);
  a3      : in  std_logic_vector(255 downto 0);
  a4      : in  std_logic_vector(255 downto 0);
  a5      : in  std_logic_vector(255 downto 0);
  a6      : in  std_logic_vector(255 downto 0);
  a7      : in  std_logic_vector(255 downto 0);
  sel     : in  std_logic_vector(2 downto 0);
  b       : out std_logic_vector(255 downto 0));
end mux8;

architecture Behavioral of mux8 is

begin
  
  p_mux : process(a1,a2,a3,a4, a5, a6, a7, a0,sel)
begin
  case sel is
    when "000" => b <= a0 ;
    when "001" => b <= a1 ;
    when "010" => b <= a2 ;
    when "011" => b <= a3 ;
    when "100" => b <= a4 ;
    when "101" => b <= a5 ;
    when "110" => b <= a6 ;
    when "111" => b <= a7 ;
  end case;
end process p_mux;

end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.06.2020 15:53:43
-- Design Name: 
-- Module Name: io_wrapper - Behavioral
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
use work.xmss_main_typedef.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity io_wrapper is
      port (
           clk   : in std_logic;
           d     : in xmss_io_input_type;
           q     : out xmss_io_output_type);
end io_wrapper;

architecture Behavioral of io_wrapper is
    type state_type is (S_IDLE, S_RAND,S_LEN,S_EN);
    type reg_type is record 
        state : state_type;
        xmss_in : xmss_input_type;
        reset : std_logic;
        ctr : integer;
    end record;
    signal r, r_in : reg_type;
    signal xmss_out : xmss_output_type;
begin

    xmss : entity work.xmss
    port map(
       clk        => clk,
       reset      => r.reset,
       d  => r.xmss_in,
       q => xmss_out );
    
    
    comb : process(r.state, d, xmss_out)
    variable v : reg_type;
    begin
        v := r;
        q.done <= '0';
        case r.state is
            when S_IDLE =>
                if d.enable = '1' then
                    v.reset := '1';
                    v.state := S_RAND;
                    v.ctr := 0;
                end if;
            when S_RAND =>
                v.xmss_in.true_random(r.ctr*64+63 downto r.ctr*64) := d.data_in;
                v.xmss_in.message(r.ctr*64+63 downto r.ctr*64) := d.data_in; -- todo
                v.ctr := r.ctr +1;
                if r.ctr = 11 then
                    v.state := S_LEN;
                end if;
            when S_LEN =>
                v.xmss_in.mlen := to_integer(unsigned(d.data_in(10 downto 0)));
                v.xmss_in.mode := d.data_in(12 downto 11);
                v.xmss_in.enable := '1';
                v.state := S_EN;
            when S_EN =>
                if xmss_out.done = '1' then
                    q.done <= '1';
                    v.state := S_IDLE;
                end if;
        end case;
        r_in <= v;
    end process;

    sequential : process(clk)
	begin
	   if rising_edge(clk) then
	       r <= r_in;
	   end if;
    end process;
end Behavioral;

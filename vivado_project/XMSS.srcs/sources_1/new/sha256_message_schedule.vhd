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
use work.sha_fast_comp.all;
use work.sha_functions.all;
use IEEE.NUMERIC_STD.ALL;

entity sha256_message_schedule is
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;
        d       : in  sha_m_input_type;
        q       : out sha_m_output_type);
end sha256_message_schedule;

architecture Behavioral of sha256_message_schedule is
    constant state_init : unsigned(479 downto 0) := (others => '0');
    type reg_type is record 
        state : unsigned(479 downto 0);
        w : unsigned(31 downto 0);
    end record;
    signal r, r_in : reg_type;
    
begin

   
   q.w <= r.state(479 downto 448);-- when d.ctr < 17 else r.w;
   
   combinational : process (r, d)
	variable v : reg_type;
	begin
	   v := r;
	   v.state := SHIFT_RIGHT(r.state, 32);
	   v.w := sig1(r.state(479 downto 448)) + r.state(319 downto 288) + sig0(r.state(63 downto 32)) + r.state(31 downto 0);
	   if d.init = '1' then
	       v.state := state_init;
	   elsif d.ctr < 15 then
           v.state(479 downto 448) := unsigned(d.message);
       else
           v.state(479 downto 448) := r.w;
       end if;
       r_in <= v;
	end process;

   sequential : process(clk)
    variable v : reg_type;
	begin
		if rising_edge(clk) then
            if d.halt = '0' then
                r <= r_in;
            end if;
        end if;
	end process;

end Behavioral;

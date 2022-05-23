library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha_comp.all;

entity sha256_m is
port(
	clk     : in  std_logic;
	d       : in sha_m_input_type;
    q       : out sha_m_output_type);
end entity;

architecture default of sha256_m is
	-- Define the registers
	type reg_type is record
	   ssig0, ssig1   : unsigned(31 downto 0);
	   state          : std_logic_vector(511 downto 0);
	   wt, w0         : std_logic_vector(31 downto 0);
	end record;  
	signal r, r_in : reg_type;
begin
    combinational : process (r, d)  
    variable v : reg_type;
    begin
        -- Shadow copy of r
        v := r;
        
        v.ssig0 := unsigned((v.state(454 downto 448) & v.state(479 downto 455)) xor (v.state(465 downto 448) & v.state(479 downto 466)) xor ("000" & v.state(479 downto 451)));
        v.ssig1 := unsigned((v.state(48 downto 32) & v.state(63 downto 49)) xor (v.state(50 downto 32) & v.state(63 downto 51)) xor ("0000000000" & v.state(63 downto 42)));
        v.wt := std_logic_vector(v.ssig0 + unsigned(r.state(223 downto 192)) + v.ssig1 + unsigned(r.state(511 downto 480)));
        
        if d.prep = '1' then 
            if v.w0 = "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" then
                q.w <=  unsigned(d.message);
            else
                q.w <=  unsigned(r.w0);
            end if;
            v.w0 := d.message;
        else
            v.w0 := v.wt;
            q.w <= unsigned(r.state(31 downto 0));
        end if;
        
        -- Update the register state
                
        v.state := r.state(479 downto 0) & v.w0;
        
        r_in <= v;

    end process;

	sequential : process(clk)
	begin
		if rising_edge(clk) then
			r <= r_in;
		end if;
	end process;
end architecture;

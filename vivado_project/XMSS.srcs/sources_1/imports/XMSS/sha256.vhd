library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha_comp.all;
use work.params.all;

entity sha256 is
generic(
    SHA_LEN : integer := n);
port(
	clk     : in  std_logic;
	reset   : in  std_logic;
	d       : in  sha_input_type;
	q       : out sha_output_type);
end entity;

architecture default of sha256 is
    type state_type is (S_IDLE, S_ROUND, S_NEXT, S_LAST);
    type reg_type is record 
        state : state_type;
        prep, init, save : std_logic;
        ctr : unsigned(5 downto 0);
        t : unsigned(5 downto 0);
    end record;
    signal  w     : unsigned(31 downto 0);
    signal hash_intermediate : std_logic_vector(n*8 -1 downto 0);
    signal r, r_in : reg_type;
begin
	-- SHA256 message schedule
	sha256_m : entity work.sha256_m
	port map(
		clk       => clk,
		d.prep    => r.prep,
		d.message => d.message,
		q.w       => w);



	sha256_h : entity work.sha256_h
	generic map(
	   SHA_LEN => SHA_LEN)
	port map(
		clk   => clk,
		d.init  => r.init,
		d.save  => r.save,
		d.t     => r.t,
		d.w     => w,
		q.hash  => hash_intermediate);
	
	q.hash <= hash_intermediate;
	
	combinational : process (r, d)
	   variable v : reg_type;
	begin
	   v := r;
	   
	   
	   v.init := '0';
	   v.save := '0';
	   --v.done := '0';
	   q.mnext <= '0';
	   
	   
	   q.done <= '0';
	   
       
	   case r.state is
	     when S_IDLE =>
			v.init := '1';
			if d.enable = '1' then
				v.state := S_ROUND;
				v.init := '0';
			end if;

		 when S_ROUND =>
			if v.ctr = 63 then
				if d.last = '1' then
					v.state := S_LAST;
					v.init := '1';
				else
				    q.mnext <= '1';
					v.state := S_NEXT;
					v.save := '1';
				end if;			     
			end if;
			v.ctr := r.ctr + 1;

		 when S_NEXT =>
			
			v.state := S_ROUND;

		 when S_LAST =>
			--v.done := '1';
			q.done <= '1';

			if d.enable = '1' then
				v.state := S_ROUND;
				
			else
				v.state := S_IDLE;
			end if;
	   end case;
	   
	   -- Output
	   --if r.ctr > 63 then
	   --    q.mnext <= '1';
	   --else
	   --    q.mnext <= '0';
	   --end if;
	   
	   if v.ctr < 15 then
	       v.prep := '1';
	   else 
	       v.prep := '0';
	   end if;
	   v.t := v.ctr; 

	   -- Update the register state
       r_in <= v;
	end process;
		
    sequential : process(clk)
    variable v : reg_type;
	begin
		if rising_edge(clk) then
		    if reset = '1' then
		        v := r_in;
				v.state := S_IDLE;
				v.ctr := (others => '0');
				r <= v;
             else
                r <= r_in;
             end if;
        end if;
	end process;
end architecture;

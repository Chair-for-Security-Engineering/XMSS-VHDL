library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_fsm is
port(
	clk    : in  std_logic;
	reset  : in  std_logic;
	enable : in  std_logic;
	last   : in  std_logic;
	done   : out std_logic;
	mnext  : out std_logic;
	prep   : out std_logic;
	init   : out std_logic;
	save   : out std_logic;
	t      : out unsigned(5 downto 0));
end entity;

architecture default of sha256_fsm is
	type states is (S_INIT, S_ROUND, S_NEXT, S_LAST);
	signal state, snext : states;
	signal ctr, cnext : unsigned(5 downto 0);
begin
	fsm : process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= S_INIT;
				ctr <= (others => '0');
			else
				state <= snext;
				ctr <= cnext;
			end if;
		end if;
	end process;

	mnext <= '1' when ctr > 60 else '0';
	prep <= '1' when ctr < 15 else '0';
	t <= ctr;

	transition : process(state, ctr, enable, last)
	begin
		done <= '0';

		init <= '0';
		save <= '0';

		snext <= state;
		cnext <= (others => '0');

		case state is
		when S_INIT =>
			init <= '1';

			if enable = '1' then
				snext <= S_ROUND;
			end if;

		when S_ROUND =>
			if ctr = 63 then
				if last = '1' then
					snext <= S_LAST;
				else
					snext <= S_NEXT;
				end if;
			end if;
			cnext <= ctr + 1;

		when S_NEXT =>
			save <= '1';

			snext <= S_ROUND;

		when S_LAST =>
			done <= '1';
			init <= '1';

			if enable = '1' then
				snext <= S_ROUND;
			else
				snext <= S_INIT;
			end if;
		end case;
	end process;
end architecture;


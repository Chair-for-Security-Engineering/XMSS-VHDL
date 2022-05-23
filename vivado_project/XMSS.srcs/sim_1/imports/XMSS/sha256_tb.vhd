library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha_comp.ALL;

entity sha256_tb is
end sha256_tb;

architecture default of sha256_tb is
	constant clk_period : time := 5 ns;

	signal clk, reset, enable, last, done, mnext : std_logic;
	signal message : std_logic_vector(31 downto 0);
	signal hash : std_logic_vector(255 downto 0);
begin
	uut : entity work.sha256
	port map(
		clk     => clk,
		reset   => reset,
		d.enable  => enable,
		d.last    => last,
		d.message => message,
		q.done    => done,
		q.mnext   => mnext,
		q.hash    => hash);

	process
	begin
		clk <= '1';
		wait for clk_period / 2;

		clk <= '0';
		wait for clk_period / 2;
	end process;

	process
	begin
		wait for 10 * clk_period;

		reset <= '1';
		enable <= '0';
		last <= '0';
		wait for 10 * clk_period;
        message <= (31 => '1', others => '0');
        
		-- SHA256()
		reset <= '0';
		enable <= '1';

		
		wait for 1.5 * clk_period;
		message <= (others => '0');
		wait until mnext = '1';

		last <= '1';

		-- SHA256(0xff, ..., 0xff)
		-- not needed: enable <= '1';
		message <= (others => '1');

		-- [Continuation] SHA256()
		wait until done = '1';
		assert hash = x"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" report "sha256()";

		-- [Continuation] SHA256(0xff, ..., 0xff)
		wait until mnext = '1';

		last <= '0';

		message <= (31 => '1', others => '0');
		wait for 4 * clk_period;
		message <= (others => '0');
		wait for 14 * clk_period;
		message <= (9 => '1', others => '0'); -- length = 0x200
		wait until mnext <= '1';

		last <= '1';
		enable <= '0';

		wait until done <= '1';
		wait for clk_period;
		assert hash = x"8667e718294e9e0df1d30600ba3eeb201f764aad2dad72748643e4a285e1d1f7" report "sha256(0xff, ..., 0xff)";
        wait for 15 *clk_period;
        
        --- Additional test SHA256(asdfASDF)
        message <= b"01100001011100110110010001100110"; -- asdf
        enable <= '1';
        wait for clk_period;                            -- Wait until next block can be absorbed
        message <= b"01000001010100110100010001000110"; -- ASDF
        wait for clk_period;
        message <= (31 => '1', others => '0');          -- Padding ||1||00....00||length*64Bit
        wait for clk_period;
        message <= (others => '0');
        wait for 12 *clk_period;
        message <= (6 => '1', others => '0');           -- length = 64
		wait until mnext <= '1';
        last <= '1';                                    -- The message ends here...
		enable <= '0';

		wait until done <= '1';
        
		wait;
	end process;
end default;


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.01.2020 09:47:24
-- Design Name: 
-- Module Name: wots_gen - Behavioral
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

entity wots_gen is
    --------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------
    Generic(
        constant n : INTEGER := 32;         -- output length of hash in bytes
        constant w : INTEGER := 16;         -- Winternitz Parameter may be 4 or 16
        constant len_1 : INTEGER := 64;     -- len_1 = ceil(8n/log2(w))
        constant len_2 : INTEGER := 3;      -- len_2 = floor(log2(len_1*(w-1))/log2(w))
        constant len : INTEGER := 67        -- len = len_1 + len_2
    );
        
    --------------------------------------------------------------
    -- Port Definition
    -------------------------------------------------------------- 
    Port ( clk : in STD_LOGIC;
           seed : in STD_LOGIC_VECTOR (31 downto 0);
           done : out STD_LOGIC);
    end wots_gen;

architecture Behavioral of wots_gen is
    signal done_in, mnext_in : std_logic;
    signal hash_in : std_logic_vector(255 downto 0);
begin
    ------------------------------------------------------------
    -- Port Maps
    ------------------------------------------------------------
    
    -- Wire up the SHA256 Module
	wots_hash : entity work.sha256
	port map(
		clk     => clk,
		reset   => '0',
		enable  => '0',
		last    => '0',
		message => (others => '0'),  -- TODO: Set message to the privkey value
		done    => done_in,
		mnext   => mnext_in,
		hash    => hash_in
		);

    --------------------------------------------------------------
    -- Key Generation
    --------------------------------------------------------------
    
    -- First generate random 32 Byte values for SK (Store them in BRAM)
            -- How do I generate randomness? -> Start with Zero values
    -- Build the hash chains of length len and store PK in BRAM
            -- How do I access the BRAM?
    -- Set Done Signal to high.
end Behavioral;

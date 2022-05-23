----------------------------------------------------------------------------------
-- This file specifies the record types used for the SHA module
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;

package sha_fast_comp is

    -- Main SHA component records
    type sha_input_type is record
       enable  : std_logic;
	   last    : std_logic;
	   halt : std_logic;
	   mode : std_logic_vector(1 downto 0);
	   message : unsigned(31 downto 0);
    end record;
    
    type sha_output_type is record
       done    : std_logic;
	   mnext   : std_logic;
	   hash    : std_logic_vector(n*8 -1 downto 0);
	end record;
	
	component sha
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in sha_input_type;
           q     : out sha_output_type);
	end component;
	
	-- Records for the SHA_M module // Message digest
	type sha_m_input_type is record
	   ctr    :  integer range 0 to 63;
	   init : std_logic;
	   halt : std_logic;
	   message :  unsigned(31 downto 0);
	end record;
	
	type sha_m_output_type is record
	   w       : unsigned(31 downto 0);
	end record;
	
	component sha256_message_schedule
        port (
           clk   : in std_logic;
           d     : in sha_m_input_type;
           q     : out sha_m_output_type);
	end component;
	
	
end package;

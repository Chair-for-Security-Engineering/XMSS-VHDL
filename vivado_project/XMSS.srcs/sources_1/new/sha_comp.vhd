----------------------------------------------------------------------------------
-- This file specifies the record types used for the SHA module
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package sha_comp is

    -- Main SHA component records
    type sha_input_type is record
       enable  : std_logic;
	   last    : std_logic;
	   message : std_logic_vector(31 downto 0);
    end record;
    
    type sha_output_type is record
       done    : std_logic;
	   mnext   : std_logic;
	   hash    : std_logic_vector(255 downto 0);
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
	   prep    :  std_logic;
	   message :  std_logic_vector(31 downto 0);
	   w       :  unsigned(31 downto 0);
	end record;
	
	type sha_m_output_type is record
	   w       : unsigned(31 downto 0);
	end record;
	
	component sha_m
        port (
           clk   : in std_logic;
           d     : in sha_m_input_type;
           q     : out sha_m_output_type);
	end component;
	
	-- Records for the SHA_H module // Main Hash logic
	type sha_h_input_type is record
	   init : std_logic;
	   save : std_logic;
	   t    : unsigned(5 downto 0);
	   w    : unsigned(31 downto 0);
	end record;
	
	type sha_h_output_type is record
	   hash : std_logic_vector(255 downto 0);
	end record;
	
	component sha_h
        port (
           clk   : in std_logic;
           d     : in sha_h_input_type;
           q     : out sha_h_output_type);
	end component;
	
end package;

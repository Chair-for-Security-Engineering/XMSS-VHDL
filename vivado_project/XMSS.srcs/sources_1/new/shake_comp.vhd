----------------------------------------------------------------------------------
-- This file specifies the record types used for the SHAKE module
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;

package shake_comp is

    -- Main SHA component records
    type shake_input_type is record
       start  : std_logic;
	   absorb    : std_logic;
	   din : STD_LOGIC_VECTOR (1343 DOWNTO 0);
    end record;
    
    type shake_output_type is record
       dout : STD_LOGIC_VECTOR (1343 DOWNTO 0);
	   ready   : std_logic;
	end record;

	
end package;

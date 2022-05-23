----------------------------------------------------------------------------------
-- This file specifies the record types used for the WOTS module
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;
use work.xmss_main_typedef.ALL;

package wots_comp is
    subtype logic_vec_len2 is std_logic_vector(wots_len2 - 1 downto 0);
    subtype logic_vec_32 is std_logic_vector(31 downto 0);
    subtype logic_vec_8n is std_logic_vector(8*n -1 downto 0);
    type base_w_array is array (wots_len - 1 downto 0) of std_logic_vector(wots_log_w - 1 downto 0); 
    --type wots_key is array (wots_len -1 downto 0) of std_logic_vector(8*n -1 downto 0);
 
	
	-- WOTS Chain component records
    type wots_chain_input_type is record
        enable : STD_LOGIC;
        X : std_logic_vector((n*8)-1 downto 0);
        start : unsigned(wots_log_w - 1 downto 0);
        signature_step : unsigned(wots_log_w downto 0);
        hash_available : std_logic;
        seed : std_logic_vector((n*8)-1 downto 0);
        address_4 : std_logic_vector(31 downto 0);
        chain_index : integer range 0 to wots_len;
        continue : std_logic;
        
        hash : hash_subsystem_output_type;
    end record;
    
    type wots_chain_output_type is record
        done, done_inter, busy : std_logic;
        result    : std_logic_vector((n*8)-1 downto 0);
        ctr : unsigned(WOTS_LEN_LOG-1 downto 0);
        
        hash : hash_subsystem_input_type;
	end record;
	
	component wots_chain
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in wots_chain_input_type;
           q     : out wots_chain_output_type);
	end component;
	
	
	
	-- WOTS Seed expander
	type seed_expander_input_type is record
        enable: std_logic;
        input : std_logic_vector((n*8)-1 downto 0); -- Input Seed
        hash : hash_subsystem_output_type;
        --bram : bram_interface_out;
    end record;
    
    type seed_expander_output_type is record
        done : std_logic;
        --privkey: wots_key;  
        hash : hash_subsystem_input_type;
        bram : bram_interface_in;
        --first_done : std_logic;
	end record;
	
	component seed_expander
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in seed_expander_input_type;
           q     : out seed_expander_output_type);
	end component;
	
	-- WOTS core module
	type wots_core_input_type is record
	   enable  : std_logic;
	   mode : std_logic_vector(1 downto 0);
	   pub_seed: std_logic_vector((n*8)-1 downto 0);
	   message     : std_logic_vector((n*8)-1 downto 0);
	   address_4 : std_logic_vector(31 downto 0);
	   
	   bram : bram_interface_out;
	   hash : hash_subsystem_output_type;
	end record;
	
	type wots_core_output_type is record
	   done      : std_logic;
	   
	   bram : bram_interface_in;
	   hash : hash_subsystem_input_type;
	end record;
	
	component wots_core
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in wots_core_input_type;
           q     : out wots_core_output_type);
	end component;
	
end package;

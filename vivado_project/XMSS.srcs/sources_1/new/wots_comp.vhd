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
   -- type base_w_msg is array (wots_len1 - 1 downto 0) of std_logic_vector(wots_log_w - 1 downto 0); 
   -- type base_w_csum is array (wots_len2 - 1 downto 0) of std_logic_vector(wots_log_w - 1 downto 0);
    type wots_key is array (wots_len -1 downto 0) of std_logic_vector(8*n -1 downto 0);
    
    
    
	
	
    
    -- Main WOTS component records
    
    
--     type wots_input_type is record
--       enable  : std_logic;
--       seed    : std_logic_vector((n*8)-1 downto 0);
       
--       mode    : std_logic_vector(1 downto 0);
--       message : std_logic_vector((n*8)-1 downto 0);
--       address : addr;
       
--       pub_seed: std_logic_vector((n*8)-1 downto 0);
--       bram : dual_port_bram_out;
--       hash : absorb_message_output_type;
       
--    end record;
--    type wots_output_type is record
--       done     : std_logic;
       
--       hash : absorb_message_input_type;
--       bram : dual_port_bram_in;
--    end record;
   
	
--	component wots
--        port (
--           clk   : in std_logic;
--           reset : in std_logic;
--           d     : in wots_input_type;
--           q     : out wots_output_type);
--	end component;
	
	-- WOTS Chain component records
    type wots_chain_input_type is record
        enable : STD_LOGIC;
        X : std_logic_vector((n*8)-1 downto 0);
        start, steps, signature_step : integer range 0 to WOTS_W;
        seed : std_logic_vector((n*8)-1 downto 0);
        address_4 : std_logic_vector(31 downto 0);
        address_5 : std_logic_vector(31 downto 0);
        
        hash : absorb_message_output_type;
    end record;
    
    type wots_chain_output_type is record
        done, done_inter : std_logic;
        result    : std_logic_vector((n*8)-1 downto 0);
        
        hash : absorb_message_input_type;
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
        hash : absorb_message_output_type;
        --bram : bram_interface_out;
    end record;
    
    type seed_expander_output_type is record
        done : std_logic;
        --privkey: wots_key;  
        hash : absorb_message_input_type;
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
	   hash : absorb_message_output_type;
	end record;
	
	type wots_core_output_type is record
	   done      : std_logic;
	   
	   bram : bram_interface_in;
	   hash : absorb_message_input_type;
	end record;
	
	component wots_core
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in wots_core_input_type;
           q     : out wots_core_output_type);
	end component;
	
end package;

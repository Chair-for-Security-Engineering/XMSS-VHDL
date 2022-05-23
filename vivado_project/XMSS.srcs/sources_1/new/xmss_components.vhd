library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;
use work.xmss_main_typedef.ALL;

package xmss_components is
    component absorb_message
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in absorb_message_input_type;
           q     : out absorb_message_output_type);
	end component;
	
	component xmss
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_input_type;
           q     : out xmss_output_type);
	end component;
    
    component xmss_io
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_io_input_type;
           q     : out xmss_io_output_type);
	end component;
	
	component xmss_thash_h
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_thash_h_input_type;
           q     : out xmss_thash_h_output_type);
	end component;
	
	component xmss_l_tree
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_l_tree_input_type;
           q     : out xmss_l_tree_output_type);
	end component;
	
	component xmss_treehash
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_treehash_input_type;
           q     : out wots_output_type);
	end component;
	
	component xmss_compute_root
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_compute_root_input_type;
           q     : out xmss_compute_root_output_type);
	end component;
	
	component hash_message
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in hash_message_input_type;
           q     : out hash_message_output_type);
	end component;
	
	component xmss_keygen
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_keygen_input_type;
           q     : out xmss_keygen_output_type);
	end component;
	
	component xmss_sign
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_sign_input_type;
           q     : out xmss_sign_output_type);
	end component;
	
	component xmss_verify
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_verify_input_type;
           q     : out xmss_verify_output_type);
	end component;
	
	component wots
        port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in wots_input_type;
           q     : out wots_output_type);
	end component;
	
	
end package;

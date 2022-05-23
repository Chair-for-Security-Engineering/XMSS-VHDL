----------------------------------------------------------------------------------
-- This file specifies global parameters
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package params is
   



   constant n               : Integer := 32;
   constant wots_w          : Integer := 16;
   constant wots_log_w      : Integer := 4;
   constant wots_len1       : Integer := 64;
   constant wots_len2       : Integer := 3;
   constant wots_len        : Integer := wots_len1 + wots_len2;
   constant wots_len_log    : Integer := 7;
   constant wots_sig_bytes  : Integer := 2144;
   constant full_height     : Integer := 2;--10;
   constant tree_height     : Integer := 2;--10;
   constant dim             : Integer := 1;
   constant index_bytes     : Integer := 4;
   constant sig_bytes       : Integer := 2500;
   constant pk_bytes        : Integer := 64;
   constant sk_bytes        : Integer := 132;
   constant bds_k           : Integer := 0;

   -- BRAM Sections
   constant BRAM_SK : integer := 0;
   constant BRAM_PK : integer := 3;
   constant BRAM_TREEHASH_INTER : integer := 5;
   constant BRAM_WOTS_SK : integer := 1029;
   constant BRAM_WOTS_PK : integer := 1096;
   constant BRAM_XMSS_SIG: integer := 1163;
   constant BRAM_XMSS_SIG_AUTH : integer := 1167;
   constant BRAM_XMSS_SIG_WOTS : integer := 1177;
   constant BRAM_MESSAGE : integer := 1244;
   constant BRAM_ADDR_SIZE : integer := 11;
   
   constant MAX_MLEN : integer := 2048;
   
   type treehash_auth_path is array (tree_height-1 downto 0) of std_logic_vector(8*n-1 downto 0);

   type addr is array (7 downto 0) of std_logic_vector(31 downto 0); 
   type xmss_sk is record
        index   : std_logic_vector(n-1 downto 0);
        sk_seed : std_logic_vector(8*n-1 downto 0);
        sk_prf  : std_logic_vector(8*n-1 downto 0);
        root    : std_logic_vector(8*n-1 downto 0);
        pub_seed: std_logic_vector(8*n-1 downto 0);
   end record;
   
   type xmss_pk is record
        root    : std_logic_vector(8*n-1 downto 0);
        pub_seed: std_logic_vector(8*n-1 downto 0);
   end record;
   
--   type xmss_sig is record
--        index   : std_logic_vector(n-1 downto 0);
--        R       : std_logic_vector(8*n-1 downto 0);
--        auth_path: treehash_auth_path;
--        wots_sig : wots_signature;
--        pubkey : xmss_pk;
--   end record;
   
   
  type treehash_stack is array (tree_height downto 0) of std_logic_vector(8*n-1 downto 0);
  type heights is array (tree_height downto 0) of integer range 0 to tree_height; 
   
   
   type bram_interface_in is record
       EN           :  STD_LOGIC;
	   WEN          :  STD_LOGIC;
	   ADDR         :  STD_LOGIC_VECTOR(BRAM_ADDR_SIZE-1 DOWNTO 0);
	   DIN          : STD_LOGIC_VECTOR(n*8-1 DOWNTO 0);
    end record;
    
    type bram_interface_out is record
	   DOUT          :  STD_LOGIC_VECTOR(n*8-1 DOWNTO 0);
    end record;
    
    type dual_port_bram_in is record
        a : bram_interface_in;
        b : bram_interface_in;
    end record;
    
    type dual_port_bram_out is record
        a : bram_interface_out;
        b : bram_interface_out;
    end record;
    
     constant bram_zero : bram_interface_in := (
        en => '0',
        wen => '0',
        addr => (others => '0'),
        din => (others => '0')
     );
     
     constant dual_bram_zero : dual_port_bram_in :=(
        a=> bram_zero,
        b=> bram_zero);
     
     
end package;

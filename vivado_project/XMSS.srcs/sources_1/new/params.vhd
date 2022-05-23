----------------------------------------------------------------------------------
-- This file specifies global parameters
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package params is
   
   constant HASH_CORES : Integer := 1; 
   constant HASH_CHAINS: Integer := 1; 

   constant HASH_FUNCTION : STRING := "SHA"; -- Possible Values are SHA (for SHA2-256) and SHAKE (for SHAKE-128) and SHA_FAST (for optimized SHA2)

   constant n               : Integer := 32;
   constant wots_w          : Integer := 16;
   constant wots_log_w      : Integer := 4;
   constant wots_len1       : Integer := 64;
   constant wots_len2       : Integer := 3;
   constant wots_len        : Integer := wots_len1 + wots_len2;
   constant wots_len_log    : Integer := 7;
   constant tree_height     : Integer := 10;--10;

   -- Lenght of the counter used for hash bus addressing
   constant ID_CTR_LEN : Integer := wots_len_log;

   -- BRAM Sections
   constant BRAM_PK : integer := 0;
   constant BRAM_TREEHASH_INTER : integer := 1;
   constant BRAM_TREEHASH_STACK : integer := BRAM_TREEHASH_INTER + (2**tree_height); -- 5
   constant BRAM_WOTS_KEY : integer := BRAM_TREEHASH_STACK + tree_height + 1; -- 8
   constant BRAM_XMSS_SIG_WOTS: integer := BRAM_WOTS_KEY + WOTS_LEN; -- 66
   constant BRAM_XMSS_SIG_AUTH : integer := BRAM_XMSS_SIG_WOTS + WOTS_LEN; -- 142
   constant BRAM_XMSS_SIG : integer := BRAM_XMSS_SIG_AUTH + tree_height; --144
   constant BRAM_MESSAGE : integer := BRAM_XMSS_SIG + 4; -- 148
   
   -- constant BRAM_PK : integer := 3;
   -- constant BRAM_TREEHASH_INTER : integer := 5;
   -- constant BRAM_WOTS_SK : integer := 1029;
   -- constant BRAM_WOTS_PK : integer := 1096;
   -- constant BRAM_XMSS_SIG: integer := 1163;
   -- constant BRAM_XMSS_SIG_AUTH : integer := 1167;
   -- constant BRAM_XMSS_SIG_WOTS : integer := 1177;
   -- constant BRAM_MESSAGE : integer := 1244;
   -- constant BRAM_TREEHASH_STACK : integer := 1260;
   
   constant BRAM_ADDR_SIZE : integer := 11;
   constant MAX_MLEN : integer := 2048;
      
   type hash_id is record
        block_ctr : unsigned(2 downto 0);
        ctr : unsigned(ID_CTR_LEN-1 downto 0);
   end record;
   constant zero_hash_id : hash_id := (others => (others => '0'));
   constant dont_care_hash_id : hash_id := (others => (others => '-'));
   
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
        addr => (others => '-'),
        din => (others => '-')
     );
     
     constant dual_bram_zero : dual_port_bram_in :=(
        a=> bram_zero,
        b=> bram_zero);
     
     
end package;

----------------------------------------------------------------------------------
-- Contains combinatorical functions of XMSS
----------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use work.xmss_main_typedef.ALL;
use work.params.ALL;

package xmss_functions is
    function copy_subtree_addr (
        address : in addr)
        return addr;
        
    function set_type (
        address : in addr;
        val : in std_logic_vector(31 downto 0))
        return addr;
        
    function set_layer_address (
        address : in addr;
        val : in std_logic_vector(31 downto 0))
        return addr;
        
    function set_tree_height (
        address : in addr;
        val : in integer)
        return addr;
        
    function set_ltree_addr (
        address : in addr;
        val : in integer)
        return addr;
    
    function set_tree_addr (
        address : in addr;
        val : in std_logic_vector(63 downto 0))
        return addr;
        
    function set_ots_addr (
        address : in addr;
        val : in integer)
        return addr;
        
    function set_tree_index (
        address : in addr;
        val : in integer)
        return addr;
        
    function sr(
        i : in integer;
        n : in integer)
        return integer;
end package xmss_functions;


package body xmss_functions is
    function copy_subtree_addr (
        address : in addr)
        return addr is
    variable result : addr;
    begin
        result(0) := address(0);
        result(1) := address(1);
        result(2) := address(2);
        result(3) := x"00000000";
        result(4) := x"00000000";
        result(5) := x"00000000";
        result(6) := x"00000000";
        result(7) := x"00000000";
        return result;
    end function;
    
    function set_tree_height (
        address : in addr;
        val : in integer)
        return addr is
    variable result : addr;
    begin
        result := address;
        result(5) := std_logic_vector(to_unsigned(val, 32));
        return result;
    end function;
    
    function set_type (
        address : in addr;
        val : in std_logic_vector(31 downto 0))
        return addr is
    variable result : addr;
    begin
        result := address;
        result(3) := val;
        return result;
    end function;
    
    function set_tree_index (
        address : in addr;
        val : in integer)
        return addr is
    variable result : addr;
    begin
        result := address;
        result(6) := std_logic_vector(to_unsigned(val, 32));
        return result;
    end function; 
     
    
    function set_ltree_addr (
        address : in addr;
        val : integer)
        return addr is
    variable result : addr;
    begin
        result := address;
        result(4) := std_logic_vector(to_unsigned(val, 32));
        return result;
    end function;
    
    function set_tree_addr (
        address : in addr;
        val : in std_logic_vector(63 downto 0))
        return addr is
    variable result : addr;
    begin
        result := address;
        result(1) := val(63 downto 32);
        result(2) := val(31 downto 0);
        return result;
    end function; 
        
    
    function set_layer_address (
        address : in addr;
        val : in std_logic_vector(31 downto 0))
        return addr is
    variable result : addr;
    begin
        result := address;
        result(0) := val;
        return result;
    end function;
    
    function set_ots_addr (
        address : in addr;
        val : integer)
        return addr is
    variable result : addr;
    begin
        result := address;
        result(4) := std_logic_vector(to_unsigned(val, 32));
        return result;
    end function;
    
     function sr(
        i : in integer;
        n : in integer)
        return integer is
     variable tmp : std_logic_vector(31 downto 0);
     begin
        tmp := std_logic_vector(to_unsigned(i, 32));
        return to_integer(shift_right(unsigned(tmp), n));
     end function;
     
    
end package body xmss_functions;
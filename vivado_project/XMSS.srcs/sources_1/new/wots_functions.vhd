----------------------------------------------------------------------------------
-- Contains combinatorical functions of WOTS
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.wots_comp.ALL;
use work.params.ALL;

package wots_functions is
    
    function set_hash_addr (
        address : in addr;
        hash    : in logic_vec_32)
        return addr;
        
    function set_key_and_mask (
        address : in addr;
        key_and_mask : in logic_vec_32)
        return addr;
    
    function set_chain_addr(
        address : in addr;
        chain_addr : in logic_vec_32)
        return addr;
        
    function base_w(
        msg : in logic_vec_8n)
        return base_w_array;
    
    --function compute_checksum(
    --    msg : in base_w_msg)
    --    return base_w_csum;


end package wots_functions;


package body wots_functions is
    
    

    function set_hash_addr (
        address : in addr;
        hash    : in logic_vec_32)
        return addr is
        variable addr_ret : addr;
    begin
        addr_ret := address;
        addr_ret(6) := hash;
        return addr_ret;
    end;
    
    function set_key_and_mask (
        address : in addr;
        key_and_mask : in logic_vec_32)
        return addr is
        variable addr_ret : addr;
    begin
        addr_ret := address;
        addr_ret(7) := key_and_mask;
        return addr_ret;
    end;
    
    function set_chain_addr(
        address : in addr;
        chain_addr : in logic_vec_32)
        return addr is
        variable addr_ret : addr;
    begin
        addr_ret := address;
        addr_ret(5) := chain_addr;
        return addr_ret;
    end;
    
    function base_w(
        msg : in logic_vec_8n)
        return base_w_array is
        variable result : base_w_array;
        variable sum : integer range 0 to wots_len1*16;
        variable sum_as_array : std_logic_vector(wots_len2*wots_log_w-1 downto 0);
        variable tmp : std_logic_vector(wots_log_w - 1 downto 0);
    begin
        sum := 0;
        for i in 0 to wots_len1-1 loop
            tmp := msg((8*n - 1) - i * wots_log_w downto (8*n) - (i + 1) * wots_log_w);
            sum := sum + (wots_w - 1) - to_integer(unsigned(tmp));
            result(wots_len - 1 - i) := tmp;
        end loop;
        sum_as_array := std_logic_vector(to_unsigned(sum, wots_len2*wots_log_w));
        for i in 0 to wots_len2-1 loop
            tmp := sum_as_array((wots_len2*wots_log_w - 1) - i * wots_log_w downto (wots_len2*wots_log_w) - (i + 1) * wots_log_w);
            result(wots_len2 - 1 - i) := tmp;
        end loop;
        return result;
    end;
    
--    function compute_checksum(
--        msg : in base_w_msg)
--        return base_w_csum is
--        variable result : base_w_csum;
--        variable tmp : integer;
--        variable tmp1 : std_logic_vector(wots_len2*wots_log_w-1 downto 0);
--        variable tmp2 : std_logic_vector(wots_log_w - 1 downto 0);
--    begin
--        tmp := 0;
--        for i in 0 to wots_len1-1 loop
--            tmp := tmp + (wots_w - 1) - to_integer(unsigned(msg(i)));
--        end loop;
--        tmp1 := std_logic_vector(to_unsigned(tmp, wots_len2*wots_log_w));
--        for i in 0 to wots_len2-1 loop
--            tmp2 := tmp1((wots_len2*wots_log_w - 1) - i * wots_log_w downto (wots_len2*wots_log_w) - (i + 1) * wots_log_w);
--            result(wots_len2 - 1 - i) := tmp2;
--        end loop;
--        return result;
--    end;
    
end package body wots_functions;
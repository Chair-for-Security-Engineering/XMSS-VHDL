----------------------------------------------------------------------------------
-- Contains combinatorical functions of WOTS
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.wots_comp.ALL;
use work.params.ALL;

package wots_functions is
    
        
    function base_w(
        msg : in logic_vec_8n)
        return base_w_array;
    

end package wots_functions;


package body wots_functions is
    

    
    function base_w(
        msg : in logic_vec_8n)
        return base_w_array is
        variable msg_copy : logic_vec_8n;
        variable result : base_w_array;
        variable sum : integer range 0 to wots_len1*(wots_w-1);
        variable sum_as_array : std_logic_vector(wots_len2*wots_log_w-1 downto 0);
        --variable tmp : std_logic_vector(wots_log_w - 1 downto 0);
    begin
        sum := (wots_w-1) * wots_len1;
        msg_copy := msg;
        for i in wots_len2 to wots_len-1 loop
            result(i) := msg_copy(wots_log_w-1 downto 0);
            msg_copy := std_logic_vector(SHIFT_RIGHT(unsigned(msg_copy), wots_log_w));
        end loop;
        for i in wots_len2 to wots_len-1 loop
            sum := sum -  to_integer(unsigned(result(i)));
        end loop;
        
        sum_as_array := std_logic_vector(to_unsigned(sum, wots_len2*wots_log_w));
        for i in 0 to wots_len2 - 1 loop
            result(i) := sum_as_array(wots_log_w-1 downto 0);
            sum_as_array := std_logic_vector(SHIFT_RIGHT(unsigned(sum_as_array), wots_log_w));
        end loop;
        return result;
    end;
    
    
end package body wots_functions;
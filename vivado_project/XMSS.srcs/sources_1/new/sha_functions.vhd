----------------------------------------------------------------------------------
-- Contains combinatorical functions of SHA
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;


package sha_functions is
    subtype logic_vec_32 is std_logic_vector(31 downto 0);
    subtype u32_t is unsigned(31 downto 0);
    subtype padding_block is unsigned(n*8-1 downto 0);
    
    -- Define the lookup function
    function sha_lookup (
        t : in integer)
        return u32_t;
        
    -- Define the gen_padding function
    function gen_padding_sha256 (
        len: in integer)
        return padding_block;
        
    function ch(
        e : unsigned(31 downto 0);
        f : unsigned(31 downto 0);
        g : unsigned(31 downto 0))
        return u32_t;
        
    function maj(
        a : unsigned(31 downto 0);
        b : unsigned(31 downto 0);
        c : unsigned(31 downto 0))
        return u32_t;
    
    function BSig0(
        x : unsigned(31 downto 0))
        return u32_t;
     
    function BSig1(
        x : unsigned(31 downto 0))
        return u32_t;
    
    function sig0(
        x : unsigned(31 downto 0))
        return u32_t;
        
    function sig1(
        x : unsigned(31 downto 0))
        return u32_t;

end package sha_functions;


package body sha_functions is

    function gen_padding_sha256 (
        len: in integer)
        return padding_block is
    variable result :unsigned(256 downto 0);
    begin      
          return to_unsigned(len, 256); -- the leading '1' hash been appended in the previous block

    end;

    function ch(
        e : unsigned(31 downto 0);
        f : unsigned(31 downto 0);
        g : unsigned(31 downto 0))
        return u32_t is
     begin
        return (e and f) xor ((not e) and g); 
     end function;
     
     function maj(
        a : unsigned(31 downto 0);
        b : unsigned(31 downto 0);
        c : unsigned(31 downto 0))
        return u32_t is
     begin
        return ((a and b) xor (a and c) xor (b and c)); 
     end function;
     
      function BSig0(
        x : unsigned(31 downto 0))
        return u32_t is
      begin
          return (x(1 downto 0) & x(31 downto 2)) xor (x(12 downto 0) & x(31 downto 13)) xor (x(21 downto 0) & x(31 downto 22));
      end function;
      
      function BSig1(
        x : unsigned(31 downto 0))
        return u32_t is
      begin
          return (x(5 downto 0) & x(31 downto 6)) xor (x(10 downto 0) & x(31 downto 11)) xor (x(24 downto 0) & x(31 downto 25));

      end function;
      
      function sig0(
        x : unsigned(31 downto 0))
        return u32_t is
      begin
          return (x(6 downto 0) & x(31 downto 7)) xor (x(17 downto 0) & x(31 downto 18)) xor ("000" & x(31 downto 3));
      end function;
      
      function sig1(
        x : unsigned(31 downto 0))
        return u32_t is
      begin
          return (x(16 downto 0) & x(31 downto 17)) xor (x(18 downto 0) & x(31 downto 19)) xor ("0000000000" & x(31 downto 10));
      end function;

    function sha_lookup(
        t : in integer) 
        return u32_t is
    begin
	     case t is
             when 0 => return x"428a2f98";
             when 1 => return x"71374491";
             when 2 => return x"b5c0fbcf";
             when 3 => return x"e9b5dba5";
             when 4 => return x"3956c25b";
             when 5 => return x"59f111f1";
             when 6 => return x"923f82a4";
             when 7 => return x"ab1c5ed5";
             when 8 => return x"d807aa98";
             when 9 => return x"12835b01";
             when 10 => return x"243185be";
             when 11 => return x"550c7dc3";
             when 12 => return x"72be5d74";
             when 13 => return x"80deb1fe";
             when 14 => return x"9bdc06a7";
             when 15 => return x"c19bf174";
             when 16 => return x"e49b69c1";
             when 17 => return x"efbe4786";
             when 18 => return x"0fc19dc6";
             when 19 => return x"240ca1cc";
             when 20 => return x"2de92c6f";
             when 21 => return x"4a7484aa";
             when 22 => return x"5cb0a9dc";
             when 23 => return x"76f988da";
             when 24 => return x"983e5152";
             when 25 => return x"a831c66d";
             when 26 => return x"b00327c8";
             when 27 => return x"bf597fc7";
             when 28 => return x"c6e00bf3";
             when 29 => return x"d5a79147";
             when 30 => return x"06ca6351";
             when 31 => return x"14292967";
             when 32 => return x"27b70a85";
             when 33 => return x"2e1b2138";
             when 34 => return x"4d2c6dfc";
             when 35 => return x"53380d13";
             when 36 => return x"650a7354";
             when 37 => return x"766a0abb";
             when 38 => return x"81c2c92e";
             when 39 => return x"92722c85";
             when 40 => return x"a2bfe8a1";
             when 41 => return x"a81a664b";
             when 42 => return x"c24b8b70";
             when 43 => return x"c76c51a3";
             when 44 => return x"d192e819";
             when 45 => return x"d6990624";
             when 46 => return x"f40e3585";
             when 47 => return x"106aa070";
             when 48 => return x"19a4c116";
             when 49 => return x"1e376c08";
             when 50 => return x"2748774c";
             when 51 => return x"34b0bcb5";
             when 52 => return x"391c0cb3";
             when 53 => return x"4ed8aa4a";
             when 54 => return x"5b9cca4f";
             when 55 => return x"682e6ff3";
             when 56 => return x"748f82ee";
             when 57 => return x"78a5636f";
             when 58 => return x"84c87814";
             when 59 => return x"8cc70208";
             when 60 => return x"90befffa";
             when 61 => return x"a4506ceb";
             when 62 => return x"bef9a3f7";
             when others => return x"c67178f2";
         end case;
    end;
end package body sha_functions;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_k is
port(
	t : in  unsigned(5 downto 0);
	k : out unsigned(31 downto 0));
end entity;

architecture default of sha256_k is
begin
	k <= x"428a2f98" when t =  0 else 
	     x"71374491" when t =  1 else
	     x"b5c0fbcf" when t =  2 else
	     x"e9b5dba5" when t =  3 else
	     x"3956c25b" when t =  4 else
	     x"59f111f1" when t =  5 else
	     x"923f82a4" when t =  6 else
	     x"ab1c5ed5" when t =  7 else
	     x"d807aa98" when t =  8 else
	     x"12835b01" when t =  9 else
	     x"243185be" when t = 10 else
	     x"550c7dc3" when t = 11 else
	     x"72be5d74" when t = 12 else
	     x"80deb1fe" when t = 13 else
	     x"9bdc06a7" when t = 14 else
	     x"c19bf174" when t = 15 else
	     x"e49b69c1" when t = 16 else
	     x"efbe4786" when t = 17 else
	     x"0fc19dc6" when t = 18 else
	     x"240ca1cc" when t = 19 else
	     x"2de92c6f" when t = 20 else
	     x"4a7484aa" when t = 21 else
	     x"5cb0a9dc" when t = 22 else
	     x"76f988da" when t = 23 else
	     x"983e5152" when t = 24 else
	     x"a831c66d" when t = 25 else
	     x"b00327c8" when t = 26 else
	     x"bf597fc7" when t = 27 else
	     x"c6e00bf3" when t = 28 else
	     x"d5a79147" when t = 29 else
	     x"06ca6351" when t = 30 else
	     x"14292967" when t = 31 else
	     x"27b70a85" when t = 32 else
	     x"2e1b2138" when t = 33 else
	     x"4d2c6dfc" when t = 34 else
	     x"53380d13" when t = 35 else
	     x"650a7354" when t = 36 else
	     x"766a0abb" when t = 37 else
	     x"81c2c92e" when t = 38 else
	     x"92722c85" when t = 39 else
	     x"a2bfe8a1" when t = 40 else
	     x"a81a664b" when t = 41 else
	     x"c24b8b70" when t = 42 else
	     x"c76c51a3" when t = 43 else
	     x"d192e819" when t = 44 else
	     x"d6990624" when t = 45 else
	     x"f40e3585" when t = 46 else
	     x"106aa070" when t = 47 else
	     x"19a4c116" when t = 48 else
	     x"1e376c08" when t = 49 else
	     x"2748774c" when t = 50 else
	     x"34b0bcb5" when t = 51 else
	     x"391c0cb3" when t = 52 else
	     x"4ed8aa4a" when t = 53 else
	     x"5b9cca4f" when t = 54 else
	     x"682e6ff3" when t = 55 else
	     x"748f82ee" when t = 56 else
	     x"78a5636f" when t = 57 else
	     x"84c87814" when t = 58 else
	     x"8cc70208" when t = 59 else
	     x"90befffa" when t = 60 else
	     x"a4506ceb" when t = 61 else
	     x"bef9a3f7" when t = 62 else
	     x"c67178f2"; -- when t = 63
end architecture;


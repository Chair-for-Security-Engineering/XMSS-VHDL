library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha_comp.all;
use work.sha_functions.all; 

entity sha256_h is
generic (
    SHA_LEN : integer);
port(
	clk  : in  std_logic;
	d : in  sha_h_input_type;
	q : out sha_h_output_type);
end entity;

architecture default of sha256_h is
    type reg_type is record 
        ch, maj, bsig0, bsig1, t1, t2, add1, add2, add3 : unsigned(31 downto 0);
        i0, i1, i2, i3, i4, i5, i6, i7 : std_logic_vector(31 downto 0);
        a, b, c, d, e, f, g, h : std_logic_vector(31 downto 0);
        h0, h1, h2, h3, h4, h5, h6, h7 : std_logic_vector(31 downto 0);
    end record;
    signal r, r_in : reg_type;

begin


    combinational : process (r, d)
	   variable v : reg_type; 
	begin
	    v := r;
        
        
        -- main hash computation
        v.ch := unsigned((r.e and r.f) xor ((not r.e) and r.g));
        v.maj := unsigned((r.a and r.b) xor (r.a and r.c) xor (r.b and r.c));
        v.bsig0 := unsigned((r.a(1 downto 0) & r.a(31 downto 2)) xor (r.a(12 downto 0) & r.a(31 downto 13)) xor (r.a(21 downto 0) & r.a(31 downto 22)));
        v.bsig1 := unsigned((r.e(5 downto 0) & r.e(31 downto 6)) xor (r.e(10 downto 0) & r.e(31 downto 11)) xor (r.e(24 downto 0) & r.e(31 downto 25)));
        v.add1 := sha_lookup(to_integer(unsigned(d.t))) + d.w;
        --
        
        v.add2 := v.bsig1 + v.ch;
        v.add3 := v.add2 + unsigned(v.h);
        v.t1 := v.add1 + v.add3;
        v.t2 := v.bsig0 + v.maj;
	    
        -- Assign values for next cicle	
        -- 
        -- if [Param1] = '1' then
        --      return get_constant([Param3]);
        -- elsif [Param2] = '1' then
        --      return [Param4];
        -- else
        --      return [Param5];
        -- end if;
        
         -- intermediate hash values
        v.i0 := std_logic_vector(unsigned(r.a) + unsigned(r.h0));
        v.i1 := std_logic_vector(unsigned(r.b) + unsigned(r.h1));
        v.i2 := std_logic_vector(unsigned(r.c) + unsigned(r.h2));
        v.i3 := std_logic_vector(unsigned(r.d) + unsigned(r.h3));
        v.i4 := std_logic_vector(unsigned(r.e) + unsigned(r.h4));
        v.i5 := std_logic_vector(unsigned(r.f) + unsigned(r.h5));
        v.i6 := std_logic_vector(unsigned(r.g) + unsigned(r.h6));
        v.i7 := std_logic_vector(unsigned(r.h) + unsigned(r.h7));
        
        v.a := assign_next(d.init, d.save, 0, v.i0, std_logic_vector(v.t1 + v.t2));
        v.b := assign_next(d.init, d.save, 1, v.i1, r.a);
        v.c := assign_next(d.init, d.save, 2, v.i2, r.b);
        v.d := assign_next(d.init, d.save, 3, v.i3, r.c);
        v.e := assign_next(d.init, d.save, 4, v.i4, std_logic_vector(unsigned(r.d) + v.t1));
        v.f := assign_next(d.init, d.save, 5, v.i5, r.e);
        v.g := assign_next(d.init, d.save, 6, v.i6, r.f);
        v.h := assign_next(d.init, d.save, 7, v.i7, r.g);
        
        v.h0 := assign_next(d.init, d.save, 0, v.i0, r.h0);
        v.h1 := assign_next(d.init, d.save, 1, v.i1, r.h1);
        v.h2 := assign_next(d.init, d.save, 2, v.i2, r.h2);
        v.h3 := assign_next(d.init, d.save, 3, v.i3, r.h3);
        v.h4 := assign_next(d.init, d.save, 4, v.i4, r.h4);
        v.h5 := assign_next(d.init, d.save, 5, v.i5, r.h5);
        v.h6 := assign_next(d.init, d.save, 6, v.i6, r.h6);
        v.h7 := assign_next(d.init, d.save, 7, v.i7, r.h7);
        
        

        
       
        
        -- Assign Hash output
        if SHA_LEN = 32 then
	       q.hash <= v.i0 & v.i1 & v.i2 & v.i3 & v.i4 & v.i5 & v.i6 & v.i7;
	    else
	       q.hash <= v.i2 & v.i3 & v.i4 & v.i5 & v.i6 & v.i7;
	    end if;
        
        -- Update the register state
        r_in <= v;
	end process;
		
    
    sequential : process(clk)
	begin
		if rising_edge(clk) then
			r <= r_in;
		end if;
	end process;
end architecture;

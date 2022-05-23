----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;
use work.sha_comp.all;
use work.sha_functions.ALL;

entity sha_256 is
port(
	clk     : in  std_logic;
	reset   : in  std_logic;
	d       : in  sha_input_type;
	q       : out sha_output_type);
end sha_256;

--  For a SHA256 developement guideline, see
--  http://www.iwar.org.uk/comsec/resources/cipher/sha256-384-512.pdf
--  The parameter naming of this module largely follows this document.

architecture Behavioral of sha_256 is
    type state_type is (S_IDLE, S_ROUND, S_LOOP);
    
    constant h1_init : unsigned(31 downto 0) := x"6a09e667";
    constant h2_init : unsigned(31 downto 0) := x"bb67ae85";
    constant h3_init : unsigned(31 downto 0) := x"3c6ef372";
    constant h4_init : unsigned(31 downto 0) := x"a54ff53a";
    constant h5_init : unsigned(31 downto 0) := x"510e527f";
    constant h6_init : unsigned(31 downto 0) := x"9b05688c";
    constant h7_init : unsigned(31 downto 0) := x"1f83d9ab";
    constant h8_init : unsigned(31 downto 0) := x"5be0cd19";
    
    type reg_type is record 
        state : state_type;

        h1, h2, h3, h4, h5, h6, h7, h8 : unsigned(31 downto 0);
        a, b, c, d, e, f, g, h : unsigned(31 downto 0);
        
        ctr : integer range 0 to 64;        
    end record;
    signal w : unsigned(31 downto 0);
    --signal prep : std_logic;
    signal t1, t2 : unsigned(31 downto 0);
    signal r, r_in : reg_type;
    signal a_next, b_next, c_next, d_next, e_next, f_next, g_next, h_next : unsigned(31 downto 0);
    
begin
    Message_Schedule : entity work.sha256_m 
        port map(
            clk     => clk,
            reset => reset,
            d.ctr => r.ctr,
            d.message => d.message,
            d.halt => d.halt,
            q.w => w);

    -- Compute t1 and t2 
    t1 <= r.h + BSig1(r.e) + Ch(r.e, r.f, r.g) + sha_lookup(r.ctr) + w;
    t2 <= BSig0(r.a) + Maj(r.a, r.b, r.c);
    
    --prep <= '1' when r.ctr < 16 else '0';
    
    -- Assign next values to signal used later below
    a_next <= r.a + r.h1;
    b_next <= r.b + r.h2;
    c_next <= r.c + r.h3;
    d_next <= r.d + r.h4;
    e_next <= r.e + r.h5;
    f_next <= r.f + r.h6;
    g_next <= r.g + r.h7;
    h_next <= r.h + r.h8;
    
    -- Hash output (This is not stable and only vaild when the done signal is 1)
    q.hash <= std_logic_vector(r_in.h1 & r_in.h2 & r_in.h3 & r_in.h4 & r_in.h5 & r_in.h6 & r_in.h7 & r_in.h8);
    --q.done <= r.done;
    
    
    
    

    combinational : process (r, d, t1, t2, a_next, b_next, c_next, d_next, e_next, f_next, g_next, h_next)
	variable v : reg_type;
	begin
	   v := r;
	   
	   --prep <= '0';
	   q.done <= '0';
	   q.mnext <= '0';
	   
	   case r.state is
	     when S_IDLE =>
			if d.enable = '1' then
			     -- Set Regs to initial values
			     v.h1 := h1_init; v.a := h1_init;
			     v.h2 := h2_init; v.b := h2_init;
			     v.h3 := h3_init; v.c := h3_init;
			     v.h4 := h4_init; v.d := h4_init;
			     v.h5 := h5_init; v.e := h5_init;
			     v.h6 := h6_init; v.f := h6_init;
			     v.h7 := h7_init; v.g := h7_init;
			     v.h8 := h8_init; v.h := h8_init;

                 -- initialize counter as 0
			     v.ctr := 0;
			     
			     v.state := S_ROUND;
			end if;
        when S_ROUND => 
            -- update registers
            v.h := r.g;
            v.g := r.f;
            v.f := r.e;
            v.e := r.d + t1;
            v.d := r.c;
            v.c := r.b;
            v.b := r.a;
            v.a := t1 + t2;
            
            v.ctr := v.ctr + 1;
            
            -- mnext is 1 excatly 1 cycle before the next message block is expected
            if r.ctr = 5 then 
                q.mnext <= '1';
            end if;
            
            if r.ctr = 62 and d.last = '0' then
                q.mnext <= '1';
            end if;

		    if r.ctr = 63 then
		      v.state := S_LOOP; 
		      
		      v.ctr := 0;
		    end if;
		 when S_LOOP =>
		    -- Update output regs
		    v.h1 := a_next;
		    v.h2 := b_next;
		    v.h3 := c_next;
		    v.h4 := d_next;
		    v.h5 := e_next;
		    v.h6 := f_next;
		    v.h7 := g_next;
		    v.h8 := h_next;
		    
		    v.a := a_next;
		    v.b := b_next;
		    v.c := c_next;
		    v.d := d_next;
		    v.e := e_next;
		    v.f := f_next;
		    v.g := g_next;
		    v.h := h_next;
		    
		    
		    
		    if d.last = '1' then
		      --v.done := '1';
		      q.done <= '1';
		      v.state := S_IDLE;
		    else
		      --q.mnext <= '1';
		      v.state := S_ROUND;
		    end if;
	   end case;

       r_in <= v;
	end process;
		
    sequential : process(clk)
    variable v : reg_type;
	begin
		if rising_edge(clk) then
		    if reset = '1' then
				r.state <= S_IDLE;
				
             elsif d.halt = '0' then
                r <= r_in;
             end if;
        end if;
	end process;

end Behavioral;

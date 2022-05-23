----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2020 09:53:08
-- Design Name: 
-- Module Name: thash_h - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.xmss_main_typedef.ALL;
--use work.wots_comp.ALL;
--use work.xmss_functions.ALL;
--use work.wots_functions.ALL;
use work.params.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity thash_h is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_thash_h_input_type;
           q     : out xmss_thash_h_output_type);
end thash_h;

architecture Behavioral of thash_h is
    type HASH_CONSTANT_ARRAY is array (2 downto 0) of std_logic_vector(31 downto 0);
    constant hash_constatns : HASH_CONSTANT_ARRAY := (x"00000000", x"00000001", x"00000002");
    alias m_in : xmss_thash_h_input_type_small is d.module_input;
    alias m_out : xmss_thash_h_output_type_small is q.module_output;
    type state_type is (S_IDLE, S_KEY, S_BITMASK_2, S_BITMASK_1, S_CORE_HASH);
    type reg_type is record
        state : state_type;
        block_ctr : integer range 0 to 6;
        ctr : integer range 0 to 2;
        mask_input_1, mask_input_2 : std_logic_vector(n*8-1 downto 0);
        hash_enable : std_logic;
    end record;
    signal r, r_in : reg_type;
    
    --signal sel : std_logic_vector(2 downto 0);
begin
    
    q.hash.enable <= '1' when r.hash_enable = '1' else '0';
    
	m_out.o <= d.hash.o;
		
    combinational : process (r, d)
	   variable v : reg_type;
    begin
        v := r;
        q.hash.len <= 768;
        m_out.done <= '0';
        v.hash_enable := '0';
        	    
     	case r.state is
     	      when S_IDLE =>
     	          v.block_ctr := 0;
                  if m_in.enable = '1' then
                       v.ctr := 1;
                       v.mask_input_1 := m_in.input_1;
                       v.mask_input_2 := m_in.input_2;
                       v.hash_enable := '1';
                       v.state := S_BITMASK_1;
                  end if;
              when S_BITMASK_1 =>
                  if d.hash.mnext = '1' then
                      v.block_ctr := r.block_ctr + 1;
                  end if;
                  if d.hash.done = '1' then
                      v.block_ctr := 0;
                      v.ctr := 0;
                      v.mask_input_1 := r.mask_input_1 xor d.hash.o;
                      v.hash_enable := '1';
                      v.state := S_BITMASK_2;
                  end if;
              when S_BITMASK_2 =>
                  if d.hash.mnext = '1' then
                      v.block_ctr := r.block_ctr + 1;
                  end if;
                  if d.hash.done = '1' then
                      v.block_ctr := 0;
                      v.ctr := 2;
                      v.mask_input_2 := r.mask_input_2 xor d.hash.o;
                      v.hash_enable := '1';
                      v.state := S_KEY;
                  end if;
              when S_KEY =>
                  if d.hash.mnext = '1' then
                      v.block_ctr := r.block_ctr + 1;
                  end if;
                  if d.hash.done = '1' then
                      v.block_ctr := 3;
                      v.hash_enable := '1';
                      v.state := S_CORE_HASH;
                  end if;
              when S_CORE_HASH =>
                  q.hash.len <= 1024;
                  if d.hash.mnext = '1' then
                      v.block_ctr := r.block_ctr + 1;
                  end if;
                  if d.hash.done = '1' then
                      m_out.done <= '1';
                      v.state := S_IDLE;
                  end if;
    end case;
    r_in <= v;
end process; 

--mux : entity work.mux8
--    port map(
--           a0 => std_logic_vector(to_unsigned(3, n*8)),
--           a1 => d.pub_seed,
--           a2 => d.pub_seed,-- x"00000000" & x"00000000" & x"00000000" & m_in.address_3 & m_in.address_4 
--                               -- & m_in.address_5 & m_in.address_6 & hash_constatns(r.ctr),
--           a3 => std_logic_vector(to_unsigned(1, n*8)),
--           a4 => d.hash.o, --key
--           a5 => r.mask_input_1,
--           a6 =>  r.mask_input_2,
--           b => q.hash.input,
--           sel => sel,
--           a7 => (others => '0'));
     
--sel <= std_logic_vector(to_unsigned(r.block_ctr, 3));
hash_mux : process(r.block_ctr, m_in, d.hash.o, r.mask_input_1, r.mask_input_2, d.pub_seed, r.ctr)
begin
    case r.block_ctr is
        when 0 =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));      
        when 1 =>
                q.hash.input <= d.pub_seed;
        when 2=>
                q.hash.input <= x"00000000" & x"00000000" & x"00000000" & m_in.address_3 & m_in.address_4 
                                & m_in.address_5 & m_in.address_6 & hash_constatns(r.ctr);
        when 3  => 
                q.hash.input <= std_logic_vector(to_unsigned(1, n*8));
        when 4 => 
                q.hash.input <= d.hash.o; --key
        when 5 =>
                q.hash.input <= r.mask_input_1;
        when 6 =>
                q.hash.input <= r.mask_input_2;
    end case;
end process;

sequential : process(clk)
--variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       ---v.block_ctr := 0;
	      -- v.hash_enable := '0';
	      -- r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;
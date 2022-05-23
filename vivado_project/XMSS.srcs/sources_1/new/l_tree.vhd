----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2020 15:59:13
-- Design Name: 
-- Module Name: l_tree - Behavioral
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
use work.xmss_functions.ALL;
use work.params.ALL;
USE ieee.numeric_std.ALL; 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity l_tree is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_l_tree_input_type;
           q     : out xmss_l_tree_output_type);
end l_tree;

architecture Behavioral of l_tree is
    alias m_in : xmss_l_tree_input_type_small is d.module_input;
    alias m_out : xmss_l_tree_output_type_small is q.module_output;   
    type state_type is (S_IDLE, S_LOOP, S_INNER_LOOP, S_THASH,  S_WAIT, S_WRITEBACK, S_SWITCH_READ, S_SWITCH_WRITE);
    type reg_type is record
        state : state_type;       
            --key : wots_key;     -- todo remove
        block_ctr : unsigned(3 downto 0);
        l : integer range 0 to wots_len;
        height : integer range 0 to wots_len;
        parent_node : integer;
        ctr : integer range 0 to wots_len; 
        write_enable_b : std_logic;
        thash_enable : std_logic;
    end record;

    signal r, r_in : reg_type;
begin
    q.bram.b.en <= '1';
    q.bram.a.en <= '1';
    q.bram.a.wen <= '0';
    q.bram.a.din <= (others => '0');
    
    q.bram.b.wen <= '1' when r.write_enable_b = '1' else '0';
    q.bram.b.din <= d.thash.o when r.block_ctr = "0010" else d.bram.a.dout;
    q.thash.input_1 <= d.bram.a.dout;
    q.thash.input_2 <= d.bram.b.dout;
    q.thash.enable <= '1' when r.thash_enable = '1' else '0';

    m_out.leaf_node <= d.thash.o;
    
    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r; 

	    
        -- thash
--        q.thash.address <= (x"00000000", std_logic_vector(to_unsigned(r.ctr, 32)),std_logic_vector(to_unsigned(r.height, 32)),
--                        m_in.address_4, x"00000001" ,x"00000000",x"00000000",x"00000000");
                        
        q.thash.address_3 <= x"00000001";
        q.thash.address_4 <= m_in.address_4;
        q.thash.address_5 <= std_logic_vector(to_unsigned(r.height, 32));
        q.thash.address_6 <= std_logic_vector(to_unsigned(r.ctr, 32));
        -- self
        m_out.done <= '0';
        
        v.write_enable_b := '0';
        v.thash_enable := '0';
        
     	case r.state is
     	      when S_IDLE =>
     	          if m_in.enable = '1' then
     	              v.block_ctr := (others => '0');
     	              v.l := wots_len;
     	              v.height := 0;
     	              v.ctr := 0;
     	              v.state := S_LOOP;
     	          end if;
     	      when S_LOOP => 
     	          if r.l > 1 then
     	              v.parent_node := sr(r.l, 1); -- shift right, defined in xmss_functions.vhd
     	              v.state := S_INNER_LOOP;
     	          else 
     	              v.state := S_IDLE;
     	              m_out.done <= '1';
     	              
     	          end if;
     	      when S_INNER_LOOP =>
     	          if r.ctr < r.parent_node then
     	              v.thash_enable := '1';
     	              v.state := S_THASH;
     	          else
     	              if r.l mod 2 = 1 then
     	                  v.block_ctr := "0001";
     	                  v.l := sr(r.l, 1) + 1;
     	                  v.state := S_SWITCH_READ; 
     	              else 
     	                  v.block_ctr := "0000";
     	                  v.l := sr(r.l, 1); -- shift right, defined in xmss_functions.vhd
     	                  v.state := S_LOOP;
     	                  v.height := r.height + 1;
     	                  v.ctr := 0;
     	              end if;
     	              
     	          end if;
     	      when S_SWITCH_READ =>
     	          v.state := S_SWITCH_WRITE;
     	          v.write_enable_b := '1';
     	      when S_SWITCH_WRITE => 
     	          v.block_ctr := "0000";
     	          v.height := r.height + 1;
     	          v.ctr := 0;
     	          v.state := S_LOOP;
     	      when S_THASH =>
     	          if d.thash.done = '1' then
     	              v.block_ctr := "0010";
     	              v.write_enable_b := '1';
                      v.state := S_WRITEBACK;
     	          end if;
     	      when S_WRITEBACK =>
     	          v.block_ctr := "0000";
     	          v.ctr := r.ctr +1;
     	          v.state := S_WAIT;
     	      when  S_WAIT =>
     	          v.state := S_INNER_LOOP;
     	end case;
     	r_in <= v;
    end process; 
    
    q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_PK + 2 * r.ctr, BRAM_ADDR_SIZE));
    
    bram_mux : process(r.block_ctr, r.ctr)
    begin
        case r.block_ctr is
            
     	    when "0001" =>
     	            q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_PK + r.ctr, BRAM_ADDR_SIZE));
     	    when "0010" =>
                    q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_PK + r.ctr, BRAM_ADDR_SIZE));
     	    when others => -- 0000
     	            q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_PK + 2 * r.ctr + 1, BRAM_ADDR_SIZE));
        end case;
    end process;
   
   
    
    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	      -- v.thash_enable := '0';
	      -- v.block_ctr := "0000";
	       --r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;


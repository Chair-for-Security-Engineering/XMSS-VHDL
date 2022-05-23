----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2020 14:18:34
-- Design Name: 
-- Module Name: xmss_treehash - Behavioral
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
USE ieee.numeric_std.ALL; 
use work.params.ALL;
use work.xmss_main_typedef.ALL;
--use work.wots_comp.ALL;
use work.xmss_functions.ALL;
use work.wots_functions.ALL;


entity xmss_treehash is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_treehash_input_type;
           q     : out xmss_treehash_output_type);
end xmss_treehash;

architecture Behavioral of xmss_treehash is
    alias m_in : xmss_treehash_input_type_small is d.module_input;
    alias m_out : xmss_treehash_output_type_small is q.module_output;
    
    type state_type is (S_IDLE, S_LOOP, S_INNER_LOOP, S_WOTS_PKGEN, S_LTREE, S_WAIT_FOR_THASH, S_SEED_GEN, S_WRITE_LEAF, S_READ_LEAF, S_READ_LEAF_1, S_WRITE_AUTH);
    constant bound : unsigned(tree_height-1 downto 0) := (others => '1');
    constant idx_padding : std_logic_vector(31-tree_height downto 0) := (others => '0');
    type reg_type is record
        state : state_type;
        block_ctr : integer range 0 to 2;
        bram_state : std_logic;

        tree_idx :  unsigned(tree_height-1 downto 0);--integer range 0 to 2**tree_height;
        idx : unsigned(tree_height-1 downto 0);-- integer range 0 to 2**tree_height;
        offset : integer range 0 to tree_height+1;
        auth_counter : integer range 0 to tree_height-1;
        stack : treehash_stack;
        heights_arr : heights;
        wots_seed : std_logic_vector(n*8-1 downto 0);
        done : std_logic;
        
        mode_select : unsigned(1 downto 0);
        
        hash_enable, wots_enable, bram_a_wen, bram_b_wen, thash_enable, l_tree_enable : std_logic;
        --DEBUG_AUTH_PATH, DEBUG_AUTH_PATH_1 : unsigned(tree_height-1 downto 0);
    end record;
    signal r, r_in : reg_type;
begin

    
    q.bram.a.en <= '1';
	q.bram.b.en <= '1';
    q.bram.a.wen <= r.bram_a_wen;
    q.bram.b.wen <= r.bram_b_wen;
    q.bram.b.din <= r.stack(r.offset) when r.offset /= tree_height+1 else (others => '0');-- mod (tree_height+1));
    q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_AUTH + r.auth_counter, BRAM_ADDR_SIZE));
    q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_INTER, BRAM_ADDR_SIZE) + r.idx) 
                     when r.bram_state = '0' else std_logic_vector(to_unsigned(BRAM_PK, BRAM_ADDR_SIZE));
    q.bram.a.din <= r.stack(r.offset) when r.offset /= tree_height+1 else (others => '0'); --mod (tree_height+1));

    q.hash.len <= 768;
    q.hash.enable <= r.hash_enable;

    q.l_tree.address_4 <= idx_padding & std_logic_vector(r.idx);
    q.l_tree.enable <= '1' when r.l_tree_enable = '1' else '0';
    
    q.thash.enable <= r.thash_enable;
    q.thash.input_1 <= (others => '0') when r.offset < 2 else r.stack(r.offset-2);
    q.thash.input_2 <= (others => '0') when r.offset < 2 else r.stack(r.offset-1);
    q.thash.address_3 <= x"00000002";
    q.thash.address_4 <= x"00000000";
    q.thash.address_5 <= std_logic_vector(to_unsigned(r.heights_arr((r.offset - 1)), 32)) when r.offset > 1 else (others => '0');
    q.thash.address_6 <= idx_padding & std_logic_vector(r.tree_idx);
    
    q.wots.address_4 <= idx_padding & std_logic_vector(r.idx);
    q.wots.mode <= "00";
    q.wots.message <= (others => '0');
    q.wots.seed <= r.wots_seed;
    q.wots.enable <= '0' when r.wots_enable = '0' else '1';
    
    
    m_out.mode_select <= r.mode_select;
    m_out.done <= '1' when r.done = '1' else '0';
    

    combinational : process (r, d)
	   variable v : reg_type;
	   variable tmp : integer;
	begin
	    v := r;
	    
	    v.done := '0';
	    v.bram_b_wen := '0';	
     	v.hash_enable := '0';
     	v.wots_enable := '0';
     	v.bram_a_wen := '0';
     	v.thash_enable := '0';
     	v.l_tree_enable := '0';
     	
     	
     	case r.state is
     	      when S_IDLE =>
     	          v.idx := (others => '0');    
     	          v.offset := 0;
     	          v.bram_state := '0';
     	          v.auth_counter := 0;
     	          if m_in.enable = '1' then
     	              v.heights_arr := (others => 0);
     	              v.mode_select := (others => '0'); -- Hash and bram as child
     	              v.state := S_LOOP;
     	          end if;
     	      when S_LOOP =>
     	          v.mode_select := (others => '0'); -- Hash and bram as child
                  if m_in.mode = '0' then
                      v.block_ctr := 0;
                      v.hash_enable := '1';
                      v.state := S_SEED_GEN;
                  else
                      v.state := S_READ_LEAF;
                  end if;
     	      when S_READ_LEAF =>
     	          v.state := S_READ_LEAF_1;
     	      when S_READ_LEAF_1 =>
     	          v.stack(r.offset) := d.bram_a.dout;
     	          v.heights_arr(r.offset) := 0;
     	          
                  
                 -- v.DEBUG_AUTH_PATH := (to_unsigned(m_in.leaf_idx, tree_height) xor r.idx);
     	          if (to_unsigned(m_in.leaf_idx, tree_height) xor r.idx) = to_unsigned(1, tree_height) then
     	                v.auth_counter := 0;--r.auth_counter + 1;
     	                v.bram_b_wen := '1';
                        v.state := S_WRITE_LEAF;
     	          else
     	                v.state := S_INNER_LOOP;
     	                v.offset := r.offset +1;
     	          end if;
     	      when S_SEED_GEN =>
     	          if d.hash.mnext = '1' then
     	              v.block_ctr := r.block_ctr + 1;
     	          end if;
     	          if d.hash.done = '1' then
     	              --v.block_ctr := r.block_ctr + 1;
     	              v.wots_seed := d.hash.o;
     	              v.mode_select := "10"; -- WOTS gets hash and bram
     	              v.wots_enable := '1';
     	              v.state := S_WOTS_PKGEN;
     	          end if;
     	     when S_WOTS_PKGEN=>
     	          if d.wots.done = '1' then
     	              --v.block_ctr := r.block_ctr + 1;
     	              v.mode_select := "01"; -- Ltree gets thash, hash and bram
     	              v.l_tree_enable := '1';
     	              v.state := S_LTREE;
     	          end if;
     	      when S_LTREE =>
     	          if d.l_tree.done = '1' then
     	              v.stack(r.offset) := d.l_tree.leaf_node;
     	              v.heights_arr(r.offset) := 0;
     	              
     	              v.mode_select := (others => '0'); -- Treehash gets bram and hash
                      v.bram_a_wen := '1';
                      v.state := S_WRITE_LEAF;
     	          end if;     	             
     	      when S_WRITE_LEAF =>
     	             v.offset := r.offset +1;
                     v.state := S_INNER_LOOP;
     	      when S_INNER_LOOP =>
     	          if r.offset >= 2 and (r.heights_arr(r.offset - 1) = r.heights_arr(r.offset -2)) then
     	              v.tree_idx := shift_right(r.idx, r.heights_arr(r.offset - 1) + 1); 
     	              v.mode_select := "11"; -- Thash gets hash, Bram stays with Treehash
     	              v.thash_enable := '1';

     	              v.state := S_WAIT_FOR_THASH;
     	          elsif r.idx = to_integer(bound) then
     	              -- Write Root to bram
     	              v.mode_select := (others => '0'); -- Treehash gets bram and hash
     	              v.bram_state := '1';
     	              v.offset := 0;
     	              v.bram_a_wen := '1';
     	              v.done := '1';
     	              
     	              v.state := S_IDLE;
     	          else
     	              v.idx := r.idx + 1;
     	              v.state := S_LOOP;
     	          end if;
     	      when S_WAIT_FOR_THASH =>
     	          if d.thash.done = '1' then
     	              v.stack(r.offset - 2) := d.thash.o;
                      v.heights_arr(r.offset - 2) := r.heights_arr(r.offset - 2) + 1;
                      
                     -- v.DEBUG_AUTH_PATH_1 := shift_right((to_unsigned(m_in.leaf_idx, tree_height) xor r.idx), v.heights_arr(r.offset - 2));
     	              if shift_right((to_unsigned(m_in.leaf_idx, tree_height) xor r.idx), v.heights_arr(r.offset - 2)) = to_unsigned(1, tree_height) then
     	                  v.auth_counter := v.heights_arr(r.offset - 2);
     	                  v.bram_b_wen := '1';
                          v.offset := r.offset - 2;
                          v.state := S_WRITE_AUTH;
     	              else 
     	                  v.offset := r.offset-1;
                          v.state := S_INNER_LOOP;  
                      end if;
     	              
     	          end if;
     	      when S_WRITE_AUTH =>
     	          v.offset := r.offset + 1;
     	          v.state := S_INNER_LOOP;
     	end case;
     	
        
     	r_in <= v;
    end process; 

    
    hash_mux : process(r.block_ctr, r.idx, r.hash_enable, d.seed)
    begin
        case r.block_ctr is
            when 0 =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8)); 
            when 1 => 
                q.hash.input <= d.seed;
            when others => --2 
                q.hash.input <=x"00000000" & x"00000000" & x"00000000" & x"00000000" & 
     	                      idx_padding & std_logic_vector(r.idx) & x"00000000" & x"00000000" & x"00000000";
        end case;
    end process;
    
    
    
    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.04.2020 08:51:49
-- Design Name: 
-- Module Name: xmss_verify - Behavioral
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
use work.params.ALL;
use work.xmss_main_typedef.ALL;
--use work.wots_comp.ALL;
use work.xmss_functions.ALL;
use work.wots_functions.ALL;
use IEEE.NUMERIC_STD.ALL;

entity xmss_verify is
    port(
        clk   : in std_logic;
        reset : in std_logic;
        d     : in xmss_verify_input_type;
        q     : out xmss_verify_output_type);
end xmss_verify;

architecture Behavioral of xmss_verify is
    constant index_padding : std_logic_vector(31-tree_height downto 0) := (others => '0');
    constant index_padding_2 : std_logic_vector(31 downto 0) := (others => '0');
    
    type state_type is (S_IDLE, S_HASH_MESSAGE, S_WOTS_VRFY, S_LTREE, S_COMP_ROOT, S_LOAD_DATA_1,S_LOAD_DATA_2, S_LOAD_DATA_3);
    type bram_type_a is (B_IDLE, B_HASH_MESSAGE, B_COMP_ROOT);
    type bram_type_b is (B_IDLE, B_INDEX, B_PUB_SEED, B_ROOT);
    type reg_type is record
        state : state_type;
        mhash : std_logic_vector(n*8-1 downto 0);
        idx_leaf : unsigned(tree_height-1 downto 0);
        index : std_logic_vector(31 downto 0);
       -- bram_state : integer range 0 to 4;
        --bram_state_a : bram_type_a;
        bram_state_b : bram_type_b;
        --thash_mux : std_logic;
       -- ctr : integer;
        --block_ctr : integer range 0 to 3;
        wots_enable, hash_message_enable, l_tree_enable, comp_root_enable : std_logic;
        
        mode_select : unsigned(1 downto 0);
    end record;
    -- signal addr_element : std_logic_vector(63 downto 0);
    type out_signals is record
        compute_root : xmss_compute_root_output_type;
    end record;
    signal compute_root : xmss_compute_root_input_type;
    signal modules : out_signals;
    signal r, r_in : reg_type;
begin
    comproot : entity work.compute_root
	port map(
		clk     => clk,
		reset => reset,
		d => compute_root,
		q => modules.compute_root);
		
	
	--compute_root.pub_seed <= r.pub_seed;
    compute_root.leaf <= d.l_tree.leaf_node;
    compute_root.leaf_idx <= to_integer(r.idx_leaf);
    
    compute_root.enable <= '1' when r.comp_root_enable = '1' else '0';
    --compute_root.hash <= d.hash;
    compute_root.thash <= d.thash;
    compute_root.bram <= d.bram.a;
	--compute_root.address <= (x"00000000", addr_element(63 downto 32), addr_element(31 downto 0) , x"00000000", x"00000000",x"00000000",x"00000000",x"00000000");
    
    --q.hash <= modules.compute_root.hash;
    q.thash <= modules.compute_root.thash;
    
   -- q.hash_message.hash <= d.hash;
    q.hash_message.mlen <=  d.mlen;
    --q.hash_message.bram <= d.bram.a;
    q.hash_message.enable <= '1' when r.hash_message_enable = '1' else '0';
    q.hash_message.index <= r.index;
    
    
   -- q.l_tree.pub_seed <= r.pub_seed;
    q.l_tree.enable <= '1' when r.l_tree_enable = '1' else '0';
    --q.l_tree.hash <= d.hash;
   -- q.l_tree.thash <= d.thash;
    --q.l_tree.bram <= d.bram;
    q.l_tree.address_4 <= index_padding & std_logic_vector(r.idx_leaf);
    --q.thash <= d.l_tree.thash when r.thash_mux = '0' else modules.compute_root.thash;

    
    --q.wots.pub_seed <= r.pub_seed;
    q.wots.mode <= "10";
    q.wots.message <= r.mhash;
    q.wots.enable <= '1' when r.wots_enable = '1' else '0';
    q.wots.seed <= (others => '0');
    --q.wots.hash <= d.hash;
    --q.wots.bram <= d.bram;
	q.wots.address_4 <= index_padding & std_logic_vector(r.idx_leaf);

    q.mode_select_l1 <= r.mode_select;
    --q.mode_select_l2 <= "00";

    combinational : process (r, d, modules)
	   variable v : reg_type;   
	    
	begin
	    v := r;
	   	
	   	v.wots_enable := '0';
	    v.hash_message_enable := '0';
	    v.l_tree_enable := '0';
	    v.comp_root_enable := '0';
	    q.valid <= '0';
	    q.done <= '0';
	    
	    case r.state is
	       when S_IDLE =>
	           q.done <= '0';
	           q.valid <= '0';
	           if d.enable = '1' then
	               --v.block_ctr := 0;
	               v.mode_select := "10";
	               --v.bram_state_a := B_HASH_MESSAGE;
	               v.bram_state_b := B_INDEX;
	               --v.thash_mux := '0';
	              -- v.idx := (others => '0');
	                  
	               v.hash_message_enable := '1';
	               v.state := S_LOAD_DATA_1;
	           end if;
	          when S_LOAD_DATA_1 => 
	               v.state := S_LOAD_DATA_2;
	          when S_LOAD_DATA_2 =>
	               v.state := S_LOAD_DATA_3;
	          when S_LOAD_DATA_3 =>
	               v.index := d.bram.b.dout(31 downto 0); -- Signature index
	               v.bram_state_b := B_PUB_SEED;
	               v.state := S_HASH_MESSAGE;
	          when S_HASH_MESSAGE => 
	               if d.hash_message.done = '1' then
	                   --v.pub_seed := d.bram.b.dout; -- Pub Seed
	                   --v.block_ctr := 1;
	                   v.mhash := d.hash_message.o;
	                   v.idx_leaf := unsigned(r.index(tree_height -1 downto 0));
	                  -- v.idx := std_logic_vector(shift_right(unsigned(r.index), tree_height));
	                   v.wots_enable := '1';
	                   v.state := S_WOTS_VRFY;
	                   v.mode_select := "01";
	               end if;
     	      when S_WOTS_VRFY =>
     	          if d.wots.done = '1' then
     	             -- v.block_ctr := r.block_ctr + 1;
     	              v.l_tree_enable := '1';
     	              v.mode_select := "11";
     	              v.state := S_LTREE;
     	          end if;
     	      when S_LTREE =>
     	          if d.l_tree.done = '1' then
     	              --v.thash_mux := '1';
     	              --v.block_ctr := r.block_ctr + 1;
     	              v.comp_root_enable := '1';
     	              v.mode_select := "00";
     	              v.state := S_COMP_ROOT;
     	              --v.bram_state_a := B_COMP_ROOT;
     	              v.bram_state_b := B_ROOT;
     	          end if;
     	      when S_COMP_ROOT =>
     	          if modules.compute_root.done = '1' then
     	              q.done <= '1';
     	              if modules.compute_root.root = d.bram.b.dout then
     	                  q.valid <= '1';
     	              end if;
     	              v.state := S_IDLE;
     	          end if;
	    end case;
     	r_in <= v;
    end process; 
    
    q.bram.a <= modules.compute_root.bram;
    
    bram_mux_b : process(r.bram_state_b, modules.compute_root.bram)
    begin
        case r.bram_state_b is
            when B_IDLE =>
                q.bram.b <= bram_zero;
            when B_INDEX =>
                q.bram.b.en <= '1';
                q.bram.b.wen <= '0';
                q.bram.b.din <= (others => '0');
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG, BRAM_ADDR_SIZE)); -- Signature Index
            when B_PUB_SEED =>
                q.bram.b.en <= '1';
                q.bram.b.wen <= '0';
                q.bram.b.din <= (others => '0');
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG+2, BRAM_ADDR_SIZE)); -- PUB Seed
            when B_ROOT =>
                q.bram.b.en <= '1';
                q.bram.b.wen <= '0';
                q.bram.b.din <= (others => '0');
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG+3, BRAM_ADDR_SIZE)); -- Root node
        end case;
    end process;
    
    
    
    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       --r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;
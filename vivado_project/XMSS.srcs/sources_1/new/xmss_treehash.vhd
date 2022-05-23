----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.params.ALL;
use work.xmss_main_typedef.ALL;


entity xmss_treehash is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_treehash_input_type;
           q     : out xmss_treehash_output_type);
end xmss_treehash;

architecture Behavioral of xmss_treehash is
    constant bound : unsigned(tree_height-1 downto 0) := (others => '1');
    
    alias m_in : xmss_treehash_input_type_small is d.module_input;
    alias m_out : xmss_treehash_output_type_small is q.module_output;
    
    type state_type is (S_IDLE, S_LOOP, S_INNER_LOOP, S_WOTS_PKGEN, S_LTREE, S_WAIT_FOR_THASH, S_SEED_GEN, S_WRITE_LEAF_AUTH, S_WRITE_INTER, S_READ_LEAF, S_WRITE_STACK_FROM_BRAM, S_WRITE_AUTH, S_READ_STACK_1, S_READ_STACK_2);
    type bram_state_a_type is (B_TOPSTACK, B_WRITE_INTER, B_WRITE_ROOT, B_WRITE_AUTH, B_STACK_OFFSET_2, B_WRITE_TOPSTACK);
    type bram_state_b_type is (B_SECOND_TOPSTACK, B_WRITE_AUTH, B_READ_INTER);
    
    type reg_type is record
        state : state_type;
        auth_counter : integer range 0 to tree_height-1;       
        done : std_logic; 

        tree_idx :  unsigned(tree_height-1 downto 0);
        idx : unsigned(tree_height-1 downto 0);
                
        --stack : treehash_stack;
        offset : integer range 0 to tree_height+1;
        heights_arr : heights;
                
        wots_enable : std_logic;
        wots_seed : std_logic_vector(n*8-1 downto 0);

    end record;
    --signal bram_a_addr_mux : std_logic;
    signal bram_state_a : bram_state_a_type;
    signal bram_state_b : bram_state_b_type;
    signal leaf_xor_idx : unsigned(tree_height - 1 downto 0);
    signal offset_minus_1, offset_minus_2 : integer range 0 to tree_height+1;
    
    signal r, r_in : reg_type;
begin

    -- Static output wiring
    q.bram.a.en <= '1';
	q.bram.b.en <= '1';
    
    q.hash.len <= 768;
    q.hash.id.block_ctr <= "000";
    q.hash.id.ctr <= to_unsigned(0, ID_CTR_LEN);

    q.l_tree.address_4 <= std_logic_vector(resize(r.idx, 32));
    
    q.thash.input_1 <= d.bram.b.dout;--r.stack(offset_minus_2);
    q.thash.input_2 <= d.bram.a.dout;--r.stack(offset_minus_1);
    q.thash.address_3 <= x"00000002";
    q.thash.address_4 <= x"00000000";
    q.thash.address_5 <= std_logic_vector(to_unsigned(r.heights_arr(offset_minus_1), 32));
    q.thash.address_6 <= std_logic_vector(resize(r_in.tree_idx, 32));
    
    q.wots.address_4 <= std_logic_vector(resize(r.idx, 32));
    q.wots.mode <= "00";
    q.wots.message <= (others => '0');
    q.wots.seed <= r.wots_seed;
    q.wots.enable <= r.wots_enable;
    
    m_out.done <= r.done;
    
    -- Internal signals
    leaf_xor_idx <= to_unsigned(m_in.leaf_idx, tree_height) xor r.idx;
    offset_minus_1 <= r.offset - 1 when r.offset /= 0 else 0;
    offset_minus_2 <= r.offset - 2 when r.offset > 1 else 0;
    

    combinational : process (r, d, offset_minus_1, offset_minus_2, leaf_xor_idx)
	   variable v : reg_type;
	begin
	    v := r;
	    
	    -- Default assignments
	    v.done := '0';
     	m_out.mode_select <= "00"; -- default: bram and hash are connected to treehash directly
     	
     	bram_state_a <= B_TOPSTACK;
     	bram_state_b <= B_SECOND_TOPSTACK;
     	q.bram.b.wen <= '0';
     	q.bram.a.wen <= '0';
     	q.bram.a.din <= (others => '-');
     	q.bram.b.din <= (others => '-');
     	
     	q.l_tree.enable <= '0';
     	q.thash.enable <= '0';
     	q.hash.enable <= '0';
     	v.wots_enable := '0';
     	
     	case r.state is
     	      when S_IDLE =>
     	          -- Zero init counters
     	          v.idx := (others => '0');    
     	          v.offset := 0;
     	          v.heights_arr := (others => 0);
     	          --v.auth_counter := 0;
     	          
     	          if m_in.enable = '1' then
     	              v.state := S_LOOP;
     	          end if;
     	      when S_LOOP =>
     	      -- S_LOOP:
     	      -- Starting point for treehash algorithm
     	      -- Depending on the mode, leaf nodes are generated or read from BRAM
     	      
     	          --------------------------------
     	          -- Mode Mapping               --
     	          -- 0 : Keygen                 --
     	          -- 1 : Sign                   --
     	          --------------------------------
     	          
     	          -- For sign, the implementation uses the intermediate values
     	          -- stored in BRAM during keygen.
                  if m_in.mode = '0' then
                      q.hash.enable <= '1';
                      v.state := S_SEED_GEN;
                  else
                      bram_state_b <= B_READ_INTER; -- Read the next intermediate value from BRAM
                      v.state := S_READ_LEAF;
                  end if;
                  
     	      when S_READ_LEAF =>
     	          -- Wait for BRAM output
     	          bram_state_b <= B_READ_INTER; -- Read the next intermediate value from BRAM
     	          v.state := S_WRITE_STACK_FROM_BRAM;
     	      when S_WRITE_STACK_FROM_BRAM =>
     	          -- Fill the stack just like in normal Treehash
     	          q.bram.a.din <= d.bram.b.dout;
     	          q.bram.a.wen <= '1';
     	          bram_state_a <= B_WRITE_TOPSTACK;
     	          v.heights_arr(r.offset) := 0;
     	          v.offset := r.offset + 1;
     	          
     	          -- There is only one leaf node that is part of the auth path
     	          if leaf_xor_idx = to_unsigned(1, tree_height) then
     	                v.auth_counter := 0;
                        v.state := S_WRITE_LEAF_AUTH;
     	          else
     	                v.state := S_READ_STACK_1;
     	          end if;
     	      when S_WRITE_LEAF_AUTH =>
     	          q.bram.a.din <= d.bram.b.dout;
     	          q.bram.a.wen <= '1';
     	          bram_state_a <= B_WRITE_AUTH;
     	          v.state := S_READ_STACK_1;
     	      
     	      
     	      when S_SEED_GEN =>
     	      -- Generate the sk seed for WOTS keygen
     	          if d.hash.done = '1' then
     	              v.wots_seed := d.hash.o;
     	              v.wots_enable := '1';
     	              v.state := S_WOTS_PKGEN;
     	          end if;
     	     when S_WOTS_PKGEN=>
     	     -- Generate a WOTS PK 
     	          
     	          -- WOTS Module gets bram and hash
     	          m_out.mode_select <= "10"; 
     	          
     	          if d.wots.done = '1' then
     	              m_out.mode_select <= "01";
     	              q.l_tree.enable <= '1';
     	              v.state := S_LTREE;
     	          end if;
     	      when S_LTREE =>
     	      -- compress WOTS key to n-bit value
     	      
     	          -- LTree module gets bram and hash
     	          m_out.mode_select <= "01";
     	          
     	          if d.l_tree.done = '1' then
     	              m_out.mode_select <= "00";
     	              --v.stack(r.offset) := d.l_tree.leaf_node;
     	              bram_state_a <= B_WRITE_TOPSTACK;
     	              q.bram.a.din <= d.l_tree.leaf_node;
     	              q.bram.a.wen <= '1';
     	              v.heights_arr(r.offset) := 0;
     	              
                      --v.bram_a_wen := '1';
                      v.state := S_WRITE_INTER;
     	          end if;     	             
     	      when S_WRITE_INTER =>
     	      -- Store the intermediate value to BRAM
     	             bram_state_a <= B_WRITE_INTER;
     	             q.bram.a.din <= d.l_tree.leaf_node;
     	             q.bram.a.wen <= '1';
     	             v.offset := r.offset +1;
                     v.state := S_READ_STACK_1;
                     
                    
              when S_READ_STACK_1 =>
              -- READ STACK:
              -- S_INNER_LOOP requires bram outputs to be the two top nodes
              -- of the stack. Read stack waits two cycles to make sure the 
              -- outputs are present. 
                  v.state := S_READ_STACK_2;
              when S_READ_STACK_2 =>
                  v.state := S_INNER_LOOP;
                  
     	      when S_INNER_LOOP =>
     	      --  S_INNER_LOOP
     	      -- Check whether there are enough nodes on the stack to call thash algorithm
     	          if r.offset >= 2 and (r.heights_arr(offset_minus_1) = r.heights_arr(offset_minus_2)) then
     	              v.tree_idx := shift_right(r.idx, r.heights_arr(offset_minus_1) + 1); 
     	              q.thash.enable <= '1';
                      m_out.mode_select <= "11";
     	              v.state := S_WAIT_FOR_THASH;
     	          elsif r.idx = to_integer(bound) then
     	              -- Write Root to bram
     	              bram_state_a <= B_WRITE_ROOT;
     	              q.bram.a.wen <= '1';
     	              q.bram.a.din <= d.l_tree.leaf_node;
     	              v.done := '1';
     	              
     	              v.state := S_IDLE;
     	          else
     	              v.idx := r.idx + 1;
     	              v.state := S_LOOP;
     	          end if;
     	          
     	      when S_WAIT_FOR_THASH =>
     	      -- Wait until thash algorithm is done, then write the result to the stack
     	          m_out.mode_select <= "11";
     	          if d.thash.done = '1' then
     	              m_out.mode_select <= "00";
     	              bram_state_a <= B_STACK_OFFSET_2;
     	              q.bram.a.wen <= '1';
     	              q.bram.a.din <= d.thash.o;
                      v.heights_arr(offset_minus_2) := r.heights_arr(offset_minus_2) + 1;
                      
                      -- Check whether the result is part of the auth path
     	              if shift_right(leaf_xor_idx, v.heights_arr(offset_minus_2)) = to_unsigned(1, tree_height) then
     	                  v.auth_counter := v.heights_arr(offset_minus_2);
                          v.offset := offset_minus_2;
                          v.state := S_WRITE_AUTH;
     	              else 
     	                  v.offset := offset_minus_1;
                          v.state := S_READ_STACK_1;  
                      end if;
     	              
     	          end if;
     	      when S_WRITE_AUTH =>
     	      -- Write the auth path node
     	          q.bram.b.wen <= '1';
     	          q.bram.b.din <= d.thash.o;
     	          bram_state_b <= B_WRITE_AUTH;
     	          v.offset := r.offset + 1;
     	          v.state := S_READ_STACK_1;
     	end case;

     	r_in <= v;
    end process; 

    
    bram_a_mux : process(bram_state_a, r.offset, r.idx)
    begin
        case bram_state_a is 
            when B_WRITE_TOPSTACK =>
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_STACK + r.offset, BRAM_ADDR_SIZE));
            when B_TOPSTACK =>
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_STACK - 1 + r.offset, BRAM_ADDR_SIZE));
            when B_STACK_OFFSET_2 =>
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_STACK - 2 + r.offset, BRAM_ADDR_SIZE));
            when B_WRITE_INTER => 
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_INTER, BRAM_ADDR_SIZE) + r.idx);
            when B_WRITE_ROOT => -- 10
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_PK, BRAM_ADDR_SIZE));
     	    when B_WRITE_AUTH => 
     	        q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_AUTH + r.auth_counter, BRAM_ADDR_SIZE));
        end case;
    end process;
    
    bram_b_mux : process(bram_state_b, r.offset, r.idx)
    begin
        case bram_state_b is 
            when B_SECOND_TOPSTACK =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_STACK - 2 + r.offset, BRAM_ADDR_SIZE));
            when B_READ_INTER => 
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_TREEHASH_INTER, BRAM_ADDR_SIZE) + r.idx);
     	    when B_WRITE_AUTH => 
     	        q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_AUTH + r.auth_counter, BRAM_ADDR_SIZE));
        end case;
    end process;
    
    hash_mux : process(d.hash.id.block_ctr, r.idx, d.seed)
    begin
        case d.hash.id.block_ctr(1 downto 0) is
            when "00" =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8)); 
            when "01" => 
                q.hash.input <= d.seed;
            when "10" => -- 10
                q.hash.input <=x"00000000" & x"00000000" & x"00000000" & x"00000000" & 
     	                      std_logic_vector(resize(r.idx, 32)) & x"00000000" & x"00000000" & x"00000000";
     	    when others => 
     	        q.hash.input <= (others => '-');
        end case;
    end process;
    
    
    
    sequential : process(clk)
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       r.tree_idx <= (others => '0');
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;

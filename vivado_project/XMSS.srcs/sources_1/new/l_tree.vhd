----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.xmss_main_typedef.ALL;
use work.params.ALL;
USE ieee.numeric_std.ALL; 


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
    type state_type is (S_IDLE, S_LOOP, S_INNER_LOOP, S_THASH, S_BRAM_WAIT_1, S_BRAM_WAIT_2 , S_SWITCH_READ, S_SWITCH_WRITE, S_BRAM_WAIT);
    type reg_type is record
        state : state_type;       
        l : unsigned(wots_len_log - 1 downto 0);--integer range 0 to wots_len;
        height : integer range 0 to wots_len_log;
        parent_node : unsigned(wots_len_log - 1 downto 0);-- integer;
        ctr : integer range 0 to wots_len; 
    end record;
    signal bram_select : unsigned(1 downto 0);
    signal DEBUG_LTREE_DONE : std_logic;
    signal DEBUG_LTREE_EN : std_logic;
    signal r, r_in : reg_type;
begin
    DEBUG_LTREE_EN <= m_in.enable;
    --------------------------
    -- Static output wiring --
    --------------------------
    q.bram.a.en <= '1';
    q.bram.a.wen <= '0';
    q.bram.a.din <= (others => '-');
    q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_KEY + 2 * r.ctr, BRAM_ADDR_SIZE));
    
    q.bram.b.en <= '1';
    q.bram.b.din <= d.thash.o when bram_select = "10" else d.bram.a.dout;
    
    q.thash.input_1 <= d.bram.a.dout;
    q.thash.input_2 <= d.bram.b.dout;
    q.thash.address_3 <= x"00000001";
    q.thash.address_4 <= m_in.address_4;
    q.thash.address_5 <= std_logic_vector(to_unsigned(r.height, 32));
    q.thash.address_6 <= std_logic_vector(to_unsigned(r.ctr, 32));

    m_out.leaf_node <= d.thash.o;
    
    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r; 
        DEBUG_LTREE_DONE <= '0';
        -- Default assignments
        q.thash.enable <= '0';
        q.bram.b.wen <= '0';
        m_out.done <= '0';
        bram_select <= (others => '0');
        
     	case r.state is
     	      when S_IDLE =>
     	          if m_in.enable = '1' then
     	              -- Initialize variables
     	              v.l := to_unsigned(WOTS_LEN, wots_len_log);
     	              v.height := 0;
     	              v.ctr := 0;
     	              v.state := S_BRAM_WAIT;
     	          end if;
     	      when S_LOOP => 
     	          -- l couts the remaning n-bit hashes to be compressed
     	          if r.l > 1 then
     	              v.parent_node := shift_right(r.l, 1);
     	              v.state := S_INNER_LOOP;
     	          else 
     	              v.state := S_IDLE;
     	              m_out.done <= '1';
     	              DEBUG_LTREE_DONE <= '1';
     	          end if;
     	      when S_INNER_LOOP =>
     	          if r.ctr < r.parent_node then
     	              -- Use thash to compress the next two n-bit values
     	              -- Inputs from BRAM
     	              q.thash.enable <= '1';
     	              v.state := S_THASH;
     	          else
     	              -- If the remaining number of nodes is even, start next loop iteration
     	              -- otherwise copy the remaining "odd" value on top of the reduced stack
     	              v.height := r.height + 1;
     	              if r.l mod 2 = 1 then
     	                  bram_select <= "01"; -- read the reminaing 2n+1-th value
     	                  v.l := shift_right(r.l, 1) + 1;
     	                  v.state := S_SWITCH_READ; 
     	              else 
     	                  v.l := shift_right(r.l, 1); 
     	                  v.state := S_BRAM_WAIT;
     	                  v.ctr := 0;
     	              end if;
     	          end if;
     	      when S_SWITCH_READ =>
     	          -- Read takes two cycles --> wait
     	          bram_select <= "01";
     	          v.state := S_SWITCH_WRITE;
     	      when S_SWITCH_WRITE => 
     	          -- write the read value to the new position and reset the counter
     	          bram_select <= "01";
     	          q.bram.b.wen <= '1';
     	          v.ctr := 0;
     	          v.state := S_BRAM_WAIT;
     	      when S_BRAM_WAIT => 
     	          -- make sure, BRAM reads are finished in time
     	          v.state := S_LOOP;
     	      when S_THASH =>
     	          -- wait until thahs algorithm is done and increase counter
     	          if d.thash.done = '1' then
     	              bram_select <= "10";
     	              q.bram.b.wen <= '1'; -- write new value...
     	              v.ctr := r.ctr +1;
                      v.state := S_BRAM_WAIT_1;
     	          end if;
     	      when S_BRAM_WAIT_1 =>
     	          -- Make sure BRAM reads are ready when entering inner Loop...
     	          v.state := S_BRAM_WAIT_2;
     	      when  S_BRAM_WAIT_2 =>
     	          v.state := S_INNER_LOOP;
     	end case;
     	r_in <= v;
    end process;     
    
    bram_mux : process(bram_select, r.ctr)
    begin
        case bram_select is
            
     	    when "01" =>
     	            q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_KEY + r.ctr, BRAM_ADDR_SIZE));
     	    when "10" =>
                    q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_KEY + r.ctr, BRAM_ADDR_SIZE));
     	    when "00" =>
     	            q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_KEY + 2 * r.ctr + 1, BRAM_ADDR_SIZE));
     	    when others =>
     	            q.bram.b.addr <= (others => '-');
        end case;
    end process;
   
   
    
    sequential : process(clk)
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


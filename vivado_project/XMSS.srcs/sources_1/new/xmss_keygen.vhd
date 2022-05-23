----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2020 14:19:19
-- Design Name: 
-- Module Name: xmss_keygen - Behavioral
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
-- work.xmss_comp.ALL;
--use work.wots_comp.ALL;
use work.xmss_main_typedef.ALL;
USE ieee.numeric_std.ALL; 


entity xmss_keygen is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_keygen_input_type;
           q     : out xmss_keygen_output_type);
end xmss_keygen;

architecture Behavioral of xmss_keygen is
    type state_type is (S_IDLE, S_BRAM_INIT, S_TREEHASH, S_TREEHASH_INIT);
    type reg_type is record
        state : state_type;
        block_ctr : integer range 0 to 1;
        bram_wen_a, bram_wen_b : std_logic;
        treehash_en : std_logic;
        mode_select : unsigned(1 downto 0);
     end record;

    signal r, r_in : reg_type;
begin
    q.treehash.mode <= '0';
   
    q.done <= d.treehash.done;
	q.treehash.leaf_idx <= 0; -- The auth path is not needed for keygen...
	--q.treehash.subtree_address <= (x"00000000", x"00000000", x"00000000", x"00000000", 
    --                                   x"00000000", x"00000000", x"00000000", dim_vec);
    q.treehash.enable <= '1' when r.treehash_en = '1' else '0';
    q.mode_select_l1 <= r.mode_select;

    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;

	    v.bram_wen_a := '0';
     	v.bram_wen_b := '0';
     	v.treehash_en := '0';
     	
     	q.mode_select_l2 <= "00";
	    
	    -- self 
     	case r.state is
     	      when S_IDLE =>
     	          if d.enable ='1' then 
     	              v.block_ctr := 0;
     	              v.bram_wen_a := '1';
     	              v.bram_wen_b := '1';
     	              v.mode_select := "01"; -- BRAM to keygen
     	              v.state := S_BRAM_INIT;
     	          end if;
     	      when S_BRAM_INIT =>
     	          v.block_ctr := 1;
     	          v.bram_wen_a := '1';
     	          v.bram_wen_b := '1';
                  v.state := S_TREEHASH_INIT;
              when S_TREEHASH_INIT =>
                  v.treehash_en := '1';
                  v.mode_select := "00"; -- Treehash is active
                  --v.block_ctr := 2;
                  v.state := S_TREEHASH;
     	      when S_TREEHASH =>
     	          q.mode_select_l2 <= d.treehash.mode_select;
     	          if d.treehash.done = '1' then
     	              v.state := S_IDLE;
     	          end if;
     	end case;
     	r_in <= v;
    end process;
    
    bram_mux : process(r.block_ctr, r.bram_wen_a, r.bram_wen_b, d.pub_seed, d.sk_prf)
    begin 
        case r.block_ctr is
            when 0 => 
                -- idx
                q.bram.a.en <= '1';
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_SK, BRAM_ADDR_SIZE));
     	        q.bram.a.din <= std_logic_vector(to_unsigned(0, n*8));
     	        q.bram.a.wen <= r.bram_wen_a;
     	              
     	        -- Write SK SEED to bram
     	        q.bram.b.en <= '1';
     	        q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_SK + 1, BRAM_ADDR_SIZE));
     	        q.bram.b.din <= d.sk_seed;
     	        q.bram.b.wen <= r.bram_wen_b;
     	    when 1 => 
     	        -- Write SK PRF to bram
     	        q.bram.a.en <= '1';
                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_SK + 2, BRAM_ADDR_SIZE));
                q.bram.a.din <= d.sk_prf;
                q.bram.a.wen <= r.bram_wen_a;
                  
                -- Write PUB SEED to bram
                q.bram.b.en <= '1';
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_PK + 1, BRAM_ADDR_SIZE));
                q.bram.b.din <= d.pub_seed;
                q.bram.b.wen <= r.bram_wen_b;
            when others => 
                --q.bram <= d.treehash.bram;
        end case;
    end process;
    
    sequential : process(clk)
    --variable v : reg_type;
    begin
       if rising_edge(clk) then
          if reset = '1' then
             r.state <= S_IDLE;
             --v.block_ctr := 0;
             --v.mode_select := "01"; -- BRAM to keygen
             --r <= v;
          else
             r <= r_in;
          end if;
       end if;
    end process;
end Behavioral;
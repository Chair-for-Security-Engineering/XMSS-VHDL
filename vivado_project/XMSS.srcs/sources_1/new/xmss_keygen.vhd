----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.params.ALL;
use work.xmss_main_typedef.ALL;
use ieee.numeric_std.ALL; 


entity xmss_keygen is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_keygen_input_type;
           q     : out xmss_keygen_output_type);
end xmss_keygen;

architecture Behavioral of xmss_keygen is
    type state_type is (S_IDLE, S_TREEHASH);
    type reg_type is record
        state : state_type;
     end record;

    --signal bram_select : std_logic;

    signal r, r_in : reg_type;
    
    signal DEBUG_gen_done, DEBUG_gen_enable : std_logic;
begin
    -- Static output wiring
    q.treehash.mode <= '0'; -- Treehash mode 0: Rebuild entire tree
    q.treehash.leaf_idx <= 0; -- Auth Path is not needed during keygen
    
    q.done <= d.treehash.done;
	q.bram.a.en <= '1';
    q.bram.b.en <= '1';
    q.bram.a.wen <= '0';
    q.bram.b.wen <= '0';

    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;

        -- Default assignments
     	q.mode_select_l1 <= "01"; -- BRAM to keygen
     	q.mode_select_l2 <= "00";
     	
     	q.treehash.enable <= '0';
     	--bram_select <= '0';
     	
     	DEBUG_gen_done <= '0';
     	DEBUG_gen_enable <= '0';
	    
     	case r.state is
     	      when S_IDLE =>
     	          if d.enable ='1' then 
     	              DEBUG_gen_enable <= '1';
     	              --v.state := S_BRAM_WRITE_1;
     	              q.treehash.enable <= '1';
     	              v.state := S_TREEHASH;
     	          end if;
--     	      when S_BRAM_WRITE_1 => 
--     	          -- Write index and SK Seed to BRAM
--     	          q.bram.a.wen <= '1';
--     	          q.bram.b.wen <= '1';
--     	          v.state := S_BRAM_WRITE_2;
--     	      when S_BRAM_WRITE_2 =>
--     	          -- Write SK PRF and PUB SEED to BRAM
--     	          q.bram.a.wen <= '1';
--     	          q.bram.b.wen <= '1';
--     	          bram_select <= '1';
     	          
--     	          -- Start Treehash algorithm
--     	          q.treehash.enable <= '1';
--                  v.state := S_TREEHASH;
     	      when S_TREEHASH =>
     	          q.mode_select_l1 <= "00"; -- Treehash gets bram and hash
     	          q.mode_select_l2 <= d.treehash.mode_select; -- Submodule muxing by treehash
     	          
     	          if d.treehash.done = '1' then
     	              v.state := S_IDLE;
     	              DEBUG_gen_done <= '1';
     	          end if;
     	end case;
     	r_in <= v;
    end process;
    
   
    -- Multiplex BRAM addresses and DIN
--    bram_mux : process(bram_select, d.pub_seed, d.sk_prf)
--    begin 
--        case bram_select is
--            when '0' => 
--                -- Index
--                --q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_SK, BRAM_ADDR_SIZE));
--     	        q.bram.a.din <= std_logic_vector(to_unsigned(0, n*8));
     	              
--     	        -- SK SEED
--     	        --q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_SK + 1, BRAM_ADDR_SIZE));
--     	        q.bram.b.din <= d.sk_seed;
--     	    when others =>  -- '1'
--     	        -- SK PRF
--                --q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_SK + 2, BRAM_ADDR_SIZE));
--                q.bram.a.din <= d.sk_prf;
                  
--                -- PUB SEED
--                --q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_PK + 1, BRAM_ADDR_SIZE));
--                q.bram.b.din <= d.pub_seed;
--        end case;
--    end process;
    
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
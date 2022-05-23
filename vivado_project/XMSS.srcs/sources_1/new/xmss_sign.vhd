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
use work.xmss_main_typedef.ALL;

entity xmss_sign is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_sign_input_type;
           q     : out xmss_sign_output_type);
end xmss_sign;

architecture Behavioral of xmss_sign is
    type state_type is (S_IDLE, S_WAIT_FOR_HASH, S_COMPUTE_SEED, S_COMPUTE_R, S_HASH_MESSAGE, S_WOTS_SIGN, S_TREEHASH,S_WRITE_ROOT);
    --type bram_type_a is (B_SK_PRF, B_PUB_SEED, B_PUB_SEED_SIG);
    type bram_type_b is (B_R, B_INDEX, B_XMSS_SIG_ROOT);
    type reg_type is record
        state : state_type;
        
        wots_seed : std_logic_vector(n*8-1 downto 0);
    end record;
    
    signal block_ctr : unsigned(2 downto 0);
    --signal bram_state_a : bram_type_a; 
    signal bram_state_b : bram_type_b; 

    signal r, r_in : reg_type;
    signal DEBUG_sign_done, DEBUG_sign_enable : std_logic;
begin
    
    --------------------------
    -- Static output wiring --
    --------------------------
    
    -- BRAM
    q.bram.a.en <= '1';
    q.bram.b.en <= '1';
    q.bram.a.din <= d.pub_seed;
    
    -- Hash
    q.hash.len <= 768; 
    q.hash.id.block_ctr <= block_ctr;
    
    -- Hash Message
    q.hash_message.mlen <= d.mlen;
    q.hash_message.index <= d.index;
    
    -- Treehash
    q.treehash.leaf_idx <= to_integer(unsigned(d.index));
    q.treehash.mode <= '1';
   
    -- WOTS 
    q.wots.address_4 <= std_logic_vector(resize(d.index, 32));
    q.wots.mode <= "01";
    q.wots.message <= d.hash_message.mhash;
    q.wots.seed <= r.wots_seed;

    q.mode_select_l2 <= d.treehash.mode_select;
    
    

    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;

        -- Default assignments
        q.bram.b.wen <= '0';
     	q.bram.a.wen <= '0';
     	--bram_state_a <= B_SK_PRF;
     	bram_state_b <= B_R;
     	
     	q.hash.enable <= '0';
     	q.hash.id.ctr <= to_unsigned(0, ID_CTR_LEN);
     	block_ctr <= d.hash.id.block_ctr;
     	
     	q.hash_message.enable <= '0';
     	
     	q.wots.enable <= '0';
     	
     	q.treehash.enable <= '0';
     	
     	q.mode_select_l1 <= "00";
     	q.done <= '0';
     	
     	DEBUG_sign_done <= '0';
        DEBUG_sign_enable <= '0';

     	case r.state is
     	      when S_IDLE =>
     	          if d.enable ='1' then
     	              v.state := S_COMPUTE_R;
     	              DEBUG_sign_enable <= '1';
     	          end if;
     	      when S_COMPUTE_R =>
     	          -- Start computing the digest randomization value
     	          block_ctr <= "000";
     	          q.hash.enable <= '1';
     	          v.state := S_COMPUTE_SEED;
     	      when S_COMPUTE_SEED =>
     	          if d.hash.busy = '0' then
     	              -- Start computing the seed
     	              q.hash.id.ctr <= to_unsigned(1, ID_CTR_LEN);
     	              block_ctr <= "100";
     	              q.hash.enable <= '1';
     	              v.state := S_WAIT_FOR_HASH;
     	          end if;
     	          
     	          -- [Constant Condition] 
     	          -- If only one hash core is configured, wait until previous hash is done
     	          if HASH_CORES = 1 then
                      if d.hash.done = '1' then
                          --bram_state_b <= B_R;
                          q.bram.b.wen <= '1';
                      end if;
     	          end if;
     	      when S_WAIT_FOR_HASH =>
     	          -- Wait until Seed and R are ready
     	          if d.hash.done = '1' then
     	              if d.hash.done_id.ctr(0) = '0' then
     	                  -- Write R to BRAM
     	                  --bram_state_b <= B_R;
     	                  q.bram.b.wen <= '1';
     	              else
     	                  -- Save the WOTS seed in register
     	                  v.wots_seed := d.hash.o;
     	                  
     	                  -- Write the current index to BRAM
     	                  bram_state_b <= B_INDEX;
     	                  q.bram.b.wen <= '1';
     	                  
     	                  -- Enable hash message module
     	                  q.hash_message.enable <= '1';
     	                  v.state := S_HASH_MESSAGE;
     	              end if;
     	          end if;
     	     when S_HASH_MESSAGE =>
     	           q.mode_select_l1 <= "10";  -- Hash and BRAM are driven by Hash Message Module
     	           
	               if d.hash_message.done = '1' then	                   
	                   -- Start WOTS Signature generation
	                   q.wots.enable <= '1';
	                   q.mode_select_l1 <= "01";
	                   
	                   v.state := S_WOTS_SIGN;
	               end if;
            when S_WOTS_SIGN =>
                q.mode_select_l1 <= "01"; -- Hash and BRAM are driven by WOTS Module
                
                if d.wots.done = '1' then
                    -- Enable Treehash module
                    q.treehash.enable <= '1';
                    v.state := S_TREEHASH;
                end if;
            when S_TREEHASH =>
                q.mode_select_l1 <= "11"; -- Hash, BRAM & WOTS driven by Treehash
                
                if d.treehash.done = '1' then
                    v.state := S_WRITE_ROOT;
                end if;
            when S_WRITE_ROOT =>
                -- write the root to BRAM and set done = 1
                bram_state_b <= B_XMSS_SIG_ROOT;
                q.bram.b.wen <= '1';
                --bram_state_a <= B_PUB_SEED_SIG;
                q.bram.a.wen <= '1';
                q.done <= '1';
                DEBUG_sign_done <= '1';
                v.state := S_IDLE;
     	end case;
     	r_in <= v;
    end process; 
    
    q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 2, BRAM_ADDR_SIZE)); -- Pub Seed Sig
    -- Multiplex BRAM A addr based on bram_state_a
--    bram_a_mux : process(bram_state_a)
--    begin
--        case bram_state_a is
--            --when B_SK_PRF => 
--                --q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_SK + 2, BRAM_ADDR_SIZE));
--            --when B_PUB_SEED =>
--            --    q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_PK + 1, BRAM_ADDR_SIZE)); -- Pub Seed
--            when B_PUB_SEED_SIG =>
--                q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 2, BRAM_ADDR_SIZE)); -- Pub Seed Sig
--        end case;
--    end process;
    
    -- Multiplex BRAM B addr based on bram_state_b
    bram_b_mux : process(bram_state_b)
    begin
        case bram_state_b is
            --when B_SK_SEED => 
                --q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_SK + 1, BRAM_ADDR_SIZE)); -- SK Seed
            when B_R =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 1, BRAM_ADDR_SIZE)); -- R
            when B_INDEX =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG, BRAM_ADDR_SIZE)); -- Index
            when B_XMSS_SIG_ROOT =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 3, BRAM_ADDR_SIZE)); -- Signature Root
        end case;
    end process;
    
    -- Multiplexer for BRAM B din
    with bram_state_b select q.bram.b.din 
                 <= d.hash.o                                        when B_R,
                    std_logic_vector(resize(d.index, n*8))          when B_INDEX,
                    d.thash.o                                       when B_XMSS_SIG_ROOT,
                    (others => '-')                                 when others;
              
    
    -- Multiplexer for hash input
    hash_mux : process(d.hash.id.block_ctr, d.bram.a.dout, d.index)
    begin
        case d.hash.id.block_ctr is
            when "000"|"100" =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));
            when "001" =>
                q.hash.input <= d.sk_prf; --d.bram.a.dout;
            when "010" =>
                q.hash.input <= std_logic_vector(resize(d.index, n*8));
            when "101" => 
                q.hash.input <= d.sk_seed;--d.bram.b.dout;
            when "110" =>
                q.hash.input <= x"00000000" & x"00000000" & x"00000000" & x"00000000" & 
                            std_logic_vector(resize(d.index, 32)) & x"00000000" & x"00000000" & x"00000000";
            when others =>
                q.hash.input <= (others => '-');
        end case;
    end process;
    
    -- Update the register state
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
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2020 11:35:38
-- Design Name: 
-- Module Name: xmss_sign - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.params.ALL;
use work.xmss_main_typedef.ALL;
--use work.wots_comp.ALL;
use work.xmss_functions.ALL;
use work.wots_functions.ALL;

entity xmss_sign is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_sign_input_type;
           q     : out xmss_sign_output_type);
end xmss_sign;

architecture Behavioral of xmss_sign is
    type state_type is (S_IDLE, S_COMPUTE_R_2, S_COMPUTE_R, S_HASH_MESSAGE, S_GET_SEED, S_WOTS_SIGN, S_TREEHASH);
    type bram_type_a is (B_SK_PRF, B_PUB_SEED);
    type bram_type_b is (B_SK_SEED, B_R, B_PUB_SEED_SIG, B_INDEX, B_XMSS_SIG_ROOT);
    type reg_type is record
        state : state_type;
        block_ctr : integer range 0 to 5;
        bram_state_a : bram_type_a; 
        bram_state_b : bram_type_b; 
        done : std_logic;
        mhash, sk_seed, wots_seed : std_logic_vector(n*8-1 downto 0);

        hash_enable, hash_message_enable, wots_enable, treehash_enable : std_logic;
        bram_b_wen : std_logic;
        mode_select : unsigned(1 downto 0);
    end record;

    signal r, r_in : reg_type;
begin
    
    q.done <= '1' when r.done = '1' else '0';
    
    q.treehash.mode <= '1';
    
    q.hash_message.mlen <= d.mlen;
    q.hash_message.enable <= '1' when r.hash_message_enable = '1' else '0';
    q.hash_message.index <= d.index;
        
    --q.treehash.subtree_address <= address;
    q.treehash.leaf_idx <= to_integer(unsigned(d.index));
    q.treehash.enable <= '1' when r.treehash_enable = '1' else '0';
    
    q.mode_select_l1 <= r.mode_select;
   
    
    q.wots.address_4 <= d.index;
    q.wots.mode <= "01";
    q.wots.message <= r.mhash;
    q.wots.seed <= r.wots_seed;
    q.wots.enable <=  r.wots_enable;

    combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;

	    v.done := '0';
     	v.bram_b_wen := '0';
     	v.hash_enable := '0';
     	v.hash_message_enable := '0';
	    v.wots_enable := '0';
	    v.treehash_enable := '0';
	    q.mode_select_l2 <= "00";
	    	    
     	case r.state is
     	      when S_IDLE =>
     	          if d.enable ='1' then
     	              -- Compute digest randomization value
     	              v.block_ctr := 0;
     	              v.bram_state_a := B_SK_PRF;
     	              v.bram_state_b := B_SK_SEED;
     	              v.mode_select := "00";
     	              v.hash_enable := '1';
     	              v.state := S_COMPUTE_R;
     	          end if;
     	      when S_COMPUTE_R =>
     	          if d.hash.mnext = '1' then
     	              v.sk_seed := d.bram.b.dout;
     	              v.bram_state_b := B_INDEX;
     	              v.bram_b_wen := '1';
     	              v.block_ctr := 1;
     	              v.state := S_COMPUTE_R_2;
     	          end if;
     	     when S_COMPUTE_R_2 =>
     	          if d.hash.mnext = '1' then
     	              --v.index := d.bram.b.dout(31 downto 0);
     	              v.bram_state_a := B_PUB_SEED;
     	              v.bram_state_b := B_PUB_SEED_SIG;
     	              v.bram_b_wen := '1';
     	              v.block_ctr := 2;
     	          end if;
     	          if d.hash.done = '1' then
                      v.hash_message_enable := '1';
                      v.mode_select := "10";
                      v.bram_state_b := B_R;
     	              v.bram_b_wen := '1'; -- R
     	              v.state := S_HASH_MESSAGE;
     	          end if;
     	     when S_HASH_MESSAGE =>
	               if d.hash_message.done = '1' then
	                   v.block_ctr := 3;
	                   v.mode_select := "00";
	                   v.state := S_GET_SEED;
	                   v.mhash := d.hash_message.o;
	                   v.hash_enable := '1';
	               end if;
     	     when S_GET_SEED =>
     	          if d.hash.mnext = '1' then
     	              v.block_ctr := r.block_ctr + 1;
                  end if;
                  if d.hash.done = '1' then
                      v.state := S_WOTS_SIGN;
                      v.mode_select := "01";
                      v.wots_seed := d.hash.o;
                      v.wots_enable := '1';
                  end if;
            when S_WOTS_SIGN =>
                if d.wots.done = '1' then
                    v.mode_select := "11";
                    v.treehash_enable := '1';
                    v.state := S_TREEHASH;
                end if;
            when S_TREEHASH =>
                q.mode_select_l2 <= d.treehash.mode_select;
                if d.treehash.done = '1' then
                    v.mode_select := "00";
                    v.bram_state_b := B_XMSS_SIG_ROOT;
                    v.bram_b_wen := '1';
                    v.done := '1';
                    v.state := S_IDLE;
                end if;
     	end case;
     	r_in <= v;
    end process; 
    
    q.bram.a.wen <= '0';
    q.bram.a.din <= (others => '0');
    q.bram.a.en <= '1';
    q.bram.a.addr <= std_logic_vector(to_unsigned(BRAM_SK + 2, BRAM_ADDR_SIZE)) when r.bram_state_a = B_SK_PRF else std_logic_vector(to_unsigned(BRAM_PK + 1, BRAM_ADDR_SIZE)); -- Pub Seed
    
    
    q.bram.b.en <= '1';
    q.bram.b.wen <= r.bram_b_wen;
    
    bram_b_mux : process(r.bram_state_b)
    begin
        case r.bram_state_b is
            when B_SK_SEED => 
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_SK + 1, BRAM_ADDR_SIZE)); -- SK Seed
            when B_R =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 1, BRAM_ADDR_SIZE)); -- R
            when B_INDEX =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG, BRAM_ADDR_SIZE)); -- Index
            when B_PUB_SEED_SIG =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 2, BRAM_ADDR_SIZE)); -- Pub Seed Sig
            when B_XMSS_SIG_ROOT =>--"111" =>
                q.bram.b.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 3, BRAM_ADDR_SIZE)); -- Signature Root
        end case;
    end process;
    
    with r.bram_state_b select
        q.bram.b.din <= d.hash.o when B_R,
                    std_logic_vector(to_unsigned(0, n*7)) & d.index when B_INDEX,
                    d.thash.o when others;
              
    q.hash.enable <= r.hash_enable;
    q.hash.len <= 768; 
    
    hash_mux : process(r.block_ctr, r.hash_enable, d.bram.a.dout, d.index)
    begin
        case r.block_ctr is
            when 0|3 =>
                q.hash.input <= std_logic_vector(to_unsigned(3, n*8));
            when 1 =>
                q.hash.input <=  d.bram.a.dout;
            when 2 =>
                q.hash.input <= std_logic_vector(to_unsigned(0, n*7)) & d.index;
            when 4 => 
                q.hash.input <= r.sk_seed;
            when 5 => 
                q.hash.input <= x"00000000" & x"00000000" & x"00000000" & x"00000000" & 
                            d.index & x"00000000" & x"00000000" & x"00000000";
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
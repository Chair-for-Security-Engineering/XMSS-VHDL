----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.wots_comp.ALL;
use work.wots_functions.ALL;
use work.xmss_main_typedef.ALL;
use work.params.ALL;
use ieee.numeric_std.all;


entity wots_core is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in wots_core_input_type;
           q     : out wots_core_output_type);
end wots_core;

architecture Behavioral of wots_core is
    constant all_zeros : std_logic_vector(HASH_CHAINS-1 downto 0) := (others => '0');
    
    type chain_output_array is array (HASH_CHAINS-1 downto 0) of std_logic_vector(n*8 -1 downto 0);
    type chain_hash_array is array (HASH_CHAINS-1 downto 0) of hash_subsystem_input_type;
    type chain_counter_array is array (HASH_CHAINS-1 downto 0) of unsigned(WOTS_LEN_LOG -1 downto 0);
    type state_type is (S_IDLE, S_READ_SK_1, S_READ_SK_2, S_CHAIN_EN, S_SIG_CHECK, S_DONE_CHECK);
    type bram_state_type is (B_READ_SK_I, B_WRITE_PK_I, B_WRITE_SIG_I);
    type reg_type is record 
        state : state_type;
        
        ctr : integer range 0 to wots_len;
        
        done_indicator, sig_indicator : std_logic_vector(HASH_CHAINS-1 downto 0);
        
        hash_sel : unsigned(HASH_CHAINS-1 downto 0);
    end record;
    
    signal bram_offset : unsigned(WOTS_LEN_LOG-1 downto 0);
    signal bram_state : bram_state_type;
    
    signal chain_busy, chain_enable, chain_continue, chain_done, chain_sig_done : std_logic_vector(HASH_CHAINS-1 downto 0);
    signal chain_counter : chain_counter_array;
    signal chain_hash_output : chain_hash_array;
    signal chain_idle : std_logic;
    signal chain_output : chain_output_array;
    signal chain_sig_step : unsigned(wots_log_w downto 0);
    signal chain_start : unsigned(wots_log_w - 1 downto 0);
    
    signal hash_indicator : unsigned(HASH_CHAINS-1 downto 0);
    
    signal index : integer range 0 to HASH_CHAINS-1;
    signal msg_and_checksum : base_w_array;
    signal msg_as_int : unsigned(wots_log_w - 1 downto 0);
    
    signal r, r_in : reg_type;
begin

    -- Generate Hash Chains           
    HashChain: for I in 0 to HASH_CHAINS-1 generate
      Chain : entity work.wots_chain 
        generic map(
            id => I+1)
        port map(
            clk => clk,
            reset => reset,
            d.enable  => chain_enable(I),
            d.seed => d.pub_seed,
            d.X => d.bram.dout,
            d.address_4 => d.address_4,
            d.chain_index => r.ctr,
            d.continue => chain_continue(I),
            d.start => chain_start,
            d.signature_step => chain_sig_step,
            d.hash_available => hash_indicator(I),
            d.hash => d.hash,
            q.hash => chain_hash_output(I),
            q.done => chain_done(I),
            q.done_inter => chain_sig_done(I),
            q.result => chain_output(I),
            q.busy => chain_busy(I),
            q.ctr => chain_counter(I));
   end generate;

    
    -- Internal Signals
    hash_indicator <= r_in.hash_sel when d.hash.busy = '0' else (others => '0');
    chain_idle <= '1' when chain_busy = ALL_ZEROS else '0';
    msg_and_checksum <= base_w(d.message); 
    msg_as_int <= unsigned(msg_and_checksum(wots_len-1-r.ctr)) when r.ctr /= wots_len else (others => '0');
    bram_offset <= chain_counter(index);
    
    -- Submodule wiring
    q.bram.din <= chain_output(index);
    q.bram.en <= '1';
    
    chain_start    <=       msg_as_int when d.mode = "10" else (others => '0');
    chain_sig_step <= '0' & msg_as_int when d.mode = "01" else to_unsigned(wots_w, wots_log_w + 1);
    

    combinational : process (r, d, chain_hash_output, chain_sig_done, chain_done, chain_busy, chain_idle)
	   variable v : reg_type;
	begin
	    v := r;
	    
	    -- Default Assignments
	    q.hash <= ZERO_HASH_INPUT;
	    q.bram.wen <= '0';
	    q.done <= '0';
	    
	    chain_enable <= (others => '0');
	    chain_continue <= (others => '0');
	    
	    bram_state <= B_READ_SK_I;
	    index <= 0;
        
	    
	    -- Transfer done and sig_done signals to register state
	    v.done_indicator := r.done_indicator or chain_done;
	    v.sig_indicator := r.sig_indicator or chain_sig_done;
	    
	    -- Set hash available signale round based if mnext is not present
	    if d.hash.mnext = '1' and r.state /= S_IDLE then
	       v.hash_sel := (others => '0');
	       v.hash_sel(to_integer(d.hash.id.ctr-1)) := '1';
        else
            v.hash_sel := ROTATE_LEFT(r.hash_sel, 1);
        end if;
        
        -- Assign the hash output of the active chain to the output
        for k in 0 to HASH_CHAINS-1 loop
             if v.hash_sel(k) = '1' then
                 q.hash <= chain_hash_output(k);
             end if;
        end loop;
        
	    	    
     	case r.state is
     	     when S_IDLE =>
     	          if d.enable = '1' then
     	              -- init chain
     	              v.ctr := 0;
     	              v.state := S_READ_SK_1;
     	          end if;
     	     when S_READ_SK_1 =>
     	          v.state := S_READ_SK_2;
     	     when S_READ_SK_2 =>
     	          v.state := S_CHAIN_EN;
     	     when S_CHAIN_EN =>
     	          for k in 0 to HASH_CHAINS-1 loop
                     if chain_busy(k) = '0' then
                         chain_enable(k) <= '1';
                         v.ctr := r.ctr + 1;
                         exit;
                     end if;
                  end loop;
                  v.state := S_SIG_CHECK;
     	     when S_SIG_CHECK =>
     	          bram_state <= B_WRITE_SIG_I;
     	          for k in 0 to HASH_CHAINS-1 loop
                     if r.sig_indicator(k) = '1' then
                         index <= k;
                         v.sig_indicator(k) := '0';
                         if r.done_indicator(k) = '0' then
                            chain_continue(k) <= '1';
                         end if;
                         q.bram.wen <= '1';
                         exit;
                     end if;
                  end loop;
     	          v.state := S_DONE_CHECK;
     	     when S_DONE_CHECK =>
     	          bram_state <= B_WRITE_PK_I;
     	          for k in 0 to HASH_CHAINS-1 loop
                     if r.done_indicator(k) = '1' then
                         index <= k;
                         v.done_indicator(k) := '0';
                         if r.sig_indicator(k) = '0' then
                            chain_continue(k) <= '1';
                         end if;
                         q.bram.wen <= '1';
                         exit;
                     end if;
                  end loop;
                  if chain_idle = '1' then
                        v.state := S_IDLE;
                        q.done <= '1';
                  elsif r.ctr = wots_len then
                        v.state := S_SIG_CHECK;
                  else
     	                v.state := S_READ_SK_1;
     	          end if;
        end case;
        r_in <= v;
    end process;

    din_mux : process(index)
    begin
         
    end process;
    bram_mux : process(bram_state, d.mode, bram_offset, r.ctr)
    begin
        case bram_state is
            when B_READ_SK_I => 
                if d.mode = "10" then
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_WOTS + r.ctr, BRAM_ADDR_SIZE));
                else
                     q.bram.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_KEY + r.ctr, BRAM_ADDR_SIZE));
                end if;
            when B_WRITE_PK_I =>
                q.bram.addr <= std_logic_vector(BRAM_WOTS_KEY + resize(bram_offset, BRAM_ADDR_SIZE));
            when B_WRITE_SIG_I =>
                q.bram.addr <= std_logic_vector(BRAM_XMSS_SIG_WOTS + resize(bram_offset, BRAM_ADDR_SIZE));
        end case;
    end process;

    sequential : process(clk)
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       r.hash_sel <= (0 => '1', others => '0');
	       r.done_indicator <= (others => '0');
	       r.sig_indicator <= (others => '0');
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;

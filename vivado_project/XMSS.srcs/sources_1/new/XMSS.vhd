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
use ieee.numeric_std.all;
use work.xmss_main_typedef.all;

entity XMSS is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_input_type;
           q     : out xmss_output_type);
end XMSS;



architecture Behavioral of XMSS is
    type state_type is (S_IDLE, S_KEYGEN, S_SIGN, S_VRFY, S_GET_MESSAGE);
    type reg_type is record 
        state : state_type;
        index : unsigned(tree_height-1 downto 0);
        done, valid : std_logic;
        
        sk_seed, pub_seed, sk_prf : std_logic_vector(8*n-1 downto 0);
        mlen : integer range 0 to 4096;

        bram_a_wen, keygen_enable, sign_enable, verify_enable : std_logic;
        message_counter : unsigned(3 downto 0);
    end record;
    signal mode_select_l0 : unsigned(1 downto 0);
    signal mode_select_l1 : unsigned(1 downto 0);
    signal mode_select_l2 : unsigned(1 downto 0);
    
    signal hash_message_bram : dual_port_bram_in;
    
    signal wots : wots_input_type;
    signal hash : hash_subsystem_input_type;
    signal treehash : xmss_treehash_input_type;
    signal thash : xmss_thash_h_input_type;
    signal keygen : xmss_keygen_input_type;
    signal sign : xmss_sign_input_type;  
    signal verify : xmss_verify_input_type;  
    signal hash_message : hash_message_input_type; 
    signal bram : dual_port_bram_in;
    signal l_tree : xmss_l_tree_input_type;
    signal bram_local : dual_port_bram_in;
    
    type output_signal is record    
        l_tree : xmss_l_tree_output_type;
        wots : wots_output_type;
        treehash : xmss_treehash_output_type;
        thash : xmss_thash_h_output_type;
        keygen : xmss_keygen_output_type;
        hash : hash_subsystem_output_type;
        sign : xmss_sign_output_type;
        verify : xmss_verify_output_type;   
        hash_message : hash_message_output_type; 
        bram : dual_port_bram_out;
    end record;
    signal modules : output_signal;
    signal r, r_in : reg_type;

begin
    -------------------------------------------
    -----       MODULE CONNECTION         -----
    -------------------------------------------
    hash_bus : entity work.hash_core_collection
	port map(
		clk     => clk,
		reset => reset,
		d  => hash,
		q  => modules.hash
		);

    wots_module : entity work.wots
    port map(
       clk        => clk,
       reset      => reset,
       d  => wots,
       q => modules.wots );
     
    treehash_module : entity work.xmss_treehash
    port map(
        clk => clk,
        reset => reset,
        d => treehash,
        q => modules.treehash
    );
    
    thash_module : entity work.thash_h

    port map(
        clk => clk,
        reset => reset,
        d => thash,
        q => modules.thash
    );
    
    keygen_module : entity work.xmss_keygen
    port map(
        clk => clk,
        reset => reset,
        d => keygen,
        q => modules.keygen        
    );
    
    sign_module : entity work.xmss_sign
    port map(
        clk => clk,
        reset => reset,
        d => sign,
        q => modules.sign        
    );
    
    verify_module : entity work.xmss_verify
    port map(
        clk => clk,
        reset => reset,
        d => verify,
        q => modules.verify        
    );
    
    hash_message_module : entity work.hash_message
    port map(
        clk => clk,
        reset => reset,
        d => hash_message,
        q => modules.hash_message        
    );
    
    bram_module : entity work.blk_mem_gen_0
	port map(
	    clka    => clk,
        ena     => bram.a.en,
        wea(0)  => bram.a.wen,
        addra   => bram.a.addr,
        dina    => bram.a.din,
        douta   => modules.bram.a.dout,
        clkb    => clk,
        enb     => bram.b.en,
        web(0)  => bram.b.wen,
        addrb   => bram.b.addr,
        dinb    => bram.b.din,
        doutb   => modules.bram.b.dout
	);
	
    ltree : entity work.l_tree
	port map(
		clk     => clk,
		reset => reset,
		d  => l_tree,
		q  => modules.l_tree);
	
	
	-------------------------------------
	----          STATIC WIRING      ----
	-------------------------------------
	
	hash_message.bram <= modules.bram.a;
    hash_message.hash <= modules.hash;
    
    keygen.enable <= '1' when r.keygen_enable = '1' else '0';
    keygen.pub_seed <= r.pub_seed;
    keygen.sk_prf <= r.sk_prf;
    keygen.sk_seed <= r.sk_seed;
    keygen.treehash <= modules.treehash.module_output;
    
    l_tree.bram <= modules.bram;
    l_tree.thash <= modules.thash.module_output;
    
    sign.bram <= modules.bram;
    sign.enable <= '1' when r.sign_enable = '1' else '0';
    sign.hash <= modules.hash;
    sign.hash_message <= modules.hash_message.module_output;
    sign.index <= r.index;
    sign.mlen <= r.mlen;
    sign.thash <= modules.thash.module_output;
    sign.treehash <= modules.treehash.module_output;
    sign.wots <= modules.wots.module_output;
    sign.sk_seed <= r.sk_seed;
    sign.sk_prf <= r.sk_prf;
    sign.pub_seed <= r.pub_seed;
    
    thash.hash <= modules.hash;
    thash.pub_seed <= r.pub_seed;
    
    treehash.bram <= modules.bram;
    treehash.hash <= modules.hash;
    treehash.l_tree <= modules.l_tree.module_output;
    treehash.seed <= r.sk_seed;
    treehash.thash <= modules.thash.module_output;
    treehash.wots <= modules.wots.module_output;
    
    verify.bram <= modules.bram;
    verify.enable <= '1' when r.verify_enable = '1' else '0';
    verify.hash_message <= modules.hash_message.module_output;
    verify.l_tree <= modules.l_tree.module_output;
    verify.mlen <= r.mlen;
    verify.thash <= modules.thash.module_output;
    verify.wots <= modules.wots.module_output;
    
    wots.bram_b <= modules.bram.b;
    wots.hash <= modules.hash;
    wots.pub_seed <= r.pub_seed;
    
    q.done <= '1' when r.done = '1' else '0';
    q.valid <= '1' when r.valid = '1' else '0';
    
    combinational : process (r, d, modules)
	   variable v : reg_type;
	begin
	    v := r;
	    
	    -- Default assignments
	    v.keygen_enable := '0';
	    v.sign_enable := '0';
	    v.verify_enable := '0';
	    v.bram_a_wen := '0';
	    
	    mode_select_l0 <= (others => '1');
        mode_select_l1 <= (others => '0');
        mode_select_l2 <= (others => '0');
	    
	    v.done := '0';
	    v.valid := '0';
	    
	    -----------------------------------
	    ---- MODE MAPPING:             ----
	    ----                           ----
	    ---- 00: Keygen                ----
	    ---- 01: Sign                  ----
	    ---- 10: Verify                ----
	    -----------------------------------
	    
        case r.state is
            when S_IDLE =>
                mode_select_l1 <= (others => '0');
                if d.enable = '1' then
                    v.mlen := 0;
                    -- If mode is keygen -> the message is not required
                    if d.mode = "00" then
                        -- Save the input seeds in registers
                        v.sk_seed := d.true_random(8*3*n-1 downto 8*2*n);
                        v.sk_prf := d.true_random(8*2*n-1 downto 8*n);
                        v.pub_seed := d.true_random(8*n-1 downto 0);
                        
                        v.keygen_enable := '1';
                        v.state := S_KEYGEN;
                    else 
                        v.state := S_GET_MESSAGE;
                        v.bram_a_wen := '1';
                        --v.bram_b_wen := '1';
                        v.message_counter := (others => '0');
                    end if;
                end if;
            when S_GET_MESSAGE =>
                -- store the message in BRAM
                v.mlen := r.mlen + n*8;
                if v.mlen < d.mlen then
                    v.state := S_GET_MESSAGE;
                    v.message_counter := r.message_counter +1;
                    v.bram_a_wen := '1';
                else
                    if d.mode = "01" then
                        v.sign_enable := '1';
                        v.state := S_SIGN;
                    else
                        v.verify_enable := '1';
                        v.state := S_VRFY;
                    end if;
                end if;
            when S_KEYGEN =>
                mode_select_l0 <= "00";
                mode_select_l1 <= modules.keygen.mode_select_l1;
                mode_select_l2 <= modules.keygen.mode_select_l2;
                if modules.keygen.done = '1' then
                    v.index := (others => '0'); -- After Keygen, reset the State
                    v.done := '1';
                    v.state := S_IDLE;
                end if;
            when S_SIGN =>
                mode_select_l0 <= "01";
                mode_select_l1 <= modules.sign.mode_select_l1;
                mode_select_l2 <= modules.sign.mode_select_l2;
                if modules.sign.done = '1' then
                    v.index := r.index + 1; -- Update the Key
                    v.done := '1';
                    v.state := S_IDLE;
                end if;
            when S_VRFY =>
                mode_select_l0 <= "10";
                mode_select_l1 <= modules.verify.mode_select_l1;
                mode_select_l2 <= "00";
                if modules.verify.done = '1' then
                    v.valid := modules.verify.valid;
                    v.done := '1';
                    v.state := S_IDLE;
                end if;
                
        end case;
     	r_in <= v;
    end process; 
    
    -- BRAM setup to write the pubseed and the message to BRAM in this module
    bram_local.a.wen <= r.bram_a_wen;
    bram_local.a.addr <= std_logic_vector(to_unsigned(BRAM_MESSAGE, BRAM_ADDR_SIZE) + r.message_counter);
    bram_local.a.din <= d.message;
    bram_local.a.en <= '1';
    
    bram_local.b.wen <= '0';
    bram_local.b.addr <= (others => '-');-- std_logic_vector(to_unsigned(BRAM_XMSS_SIG + 2, BRAM_ADDR_SIZE));
    bram_local.b.din <= (others => '-');--r.pub_seed;
    bram_local.b.en <= '0';
    
    -- Multiplex the signals to the submodules based on the three select signals
    with mode_select_l0 select treehash.module_input 
                            <= modules.keygen.treehash        when "00",
                               modules.sign.treehash          when "01",
                               zero_treehash_xmss_child_input when others;
    
    with mode_select_l0 select hash_message.module_input 
                            <= modules.sign.hash_message        when "01",
                               modules.verify.hash_message          when "10",
                               zero_hash_message_xmss_child_input when others;
    
    with mode_select_l0 & mode_select_l1 select wots.module_input 
                            <= modules.treehash.wots         when "0000",
                               modules.treehash.wots         when "0111",
                               modules.sign.wots        when "0101",
                               modules.verify.wots      when "1001",
                               zero_wots_xmss_child_input when others;
                               
    with mode_select_l0 & mode_select_l1 & mode_select_l2 select hash 
                            <= modules.treehash.hash         when "000000",
                               modules.treehash.hash         when "011100",
                               modules.thash.hash         when "000011",
                               modules.thash.hash        when "000001",
                               modules.thash.hash         when "011111",
                               modules.thash.hash         when "011101",
                               modules.thash.hash         when "100000",
                               modules.thash.hash         when "101100",
                               modules.wots.hash      when "000010",
                               modules.wots.hash         when "010100",
                               modules.wots.hash         when "011110",
                               modules.wots.hash         when "100100",
                               modules.sign.hash      when "010000",
                               modules.hash_message.hash      when "011000",
                               modules.hash_message.hash         when "101000",
                               dont_care_hash_input when others;
                               
    with mode_select_l0 & mode_select_l1 & mode_select_l2 select bram
                            <= modules.treehash.bram         when "000000",
                               modules.treehash.bram         when "000011",
                               modules.treehash.bram         when "011100",
                               modules.treehash.bram         when "011111",
                               modules.wots.bram         when "000010",
                               modules.wots.bram         when "010100",
                               modules.wots.bram         when "011110",
                               modules.wots.bram         when "100100",
                               modules.l_tree.bram         when "000001",
                               modules.l_tree.bram         when "011101",
                               modules.l_tree.bram         when "101100",
                               hash_message_bram         when "011000",
                               hash_message_bram         when "101000",
                               modules.keygen.bram      when "000100",
                               modules.sign.bram      when "010000",
                               modules.verify.bram         when "100000",
                               bram_local when "110000",
                               dual_bram_zero when others;
    
    hash_message_bram.a <= modules.hash_message.bram;
    hash_message_bram.b <= modules.sign.bram.b when mode_select_l0 = "01" else modules.verify.bram.b;
    
    with mode_select_l0 & mode_select_l1 & mode_select_l2 select thash.module_input 
                            <= modules.treehash.thash         when "000011",
                               modules.treehash.thash         when "011111",
                               modules.l_tree.thash         when "000001",
                               modules.l_tree.thash         when "011101",
                               modules.l_tree.thash         when "101100",
                               modules.verify.thash         when "100000",
                               zero_thash_xmss_child_input when others;
                               
    with mode_select_l0  select l_tree.module_input 
                            <= modules.treehash.l_tree         when "00",
                               modules.treehash.l_tree         when "01",
                               modules.verify.l_tree         when "10",
                               zero_l_tree_xmss_child_input when others;
                      

    
    
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

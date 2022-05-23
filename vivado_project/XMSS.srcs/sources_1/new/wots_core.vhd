----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.02.2020 14:01:56
-- Design Name: 
-- Module Name: wots_sign - Behavioral
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
use work.wots_comp.ALL;
use work.wots_functions.ALL;
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
    type state_type is (S_IDLE, S_CHAIN,S_WAIT,S_WAIT_2, S_WRITEBACK_PK, S_WRITEBACK_SIG,S_FIN, S_DOUBLE_WRITEBACK);
    type bram_state_type is (B_READ_I, B_WRITE_PK_I, B_WRITE_SIG_I);
    type reg_type is record 
        state : state_type;
        bram_state : bram_state_type;
        ctr : integer range 0 to wots_len;
        ctr2 : integer range 0 to wots_len;
        chain_enable : std_logic;
    end record;
    signal chain : wots_chain_input_type;
    type output_signal is record
        chain : wots_chain_output_type;
    end record;
    signal modules : output_signal;
    signal msg_and_checksum : base_w_array;
    signal r, r_in : reg_type;
begin

    hash_chain : entity work.wots_chain
    port map(
           clk   => clk,
           reset => reset,
           d => chain,
           q => modules.chain);
    
    msg_and_checksum <= base_w(d.message); 
    
    q.bram.en <= '1';
    q.bram.din <= modules.chain.result;
    
    chain.enable <= '1' when r.chain_enable = '1' else '0';
    chain.start <= to_integer(unsigned(msg_and_checksum(wots_len-1-r.ctr2))) when d.mode = "10" and r.ctr /= wots_len else 0;
    chain.steps <= wots_w - 1 - chain.start when d.mode = "10" else  wots_w - 1;
    chain.signature_step <= to_integer(unsigned(msg_and_checksum(wots_len-1-r.ctr2))) when d.mode = "01" else wots_w;
--    chain.address <= (d.address(7), d.address(6), std_logic_vector(to_unsigned(r.ctr2,32)), d.address(4), d.address(3), 
--                    d.address(2), d.address(1), d.address(0)); 
    chain.address_4 <= d.address_4;
    chain.address_5 <= std_logic_vector(to_unsigned(r.ctr2,32));
    chain.seed <= d.pub_seed;
    chain.X <= d.bram.dout; -- next value
    chain.hash <= d.hash;
    
    q.hash <= modules.chain.hash;

    
    
    
    combinational : process (r, d, modules, chain)
	   variable v : reg_type;
	begin
	    v := r;
	    v.chain_enable := '0';

         -- self
	    q.done <= '0';
	    v.bram_state := B_READ_I;
	    
     	case r.state is
     	     when S_IDLE =>
     	          if d.enable = '1' then
     	              -- init chain
     	              v.ctr := 0;
     	              v.state := S_WAIT_2;
     	          end if;
     	     when S_WAIT =>
     	          v.ctr := r.ctr +1;
     	          v.state := S_CHAIN;     -- BRAM Wait
     	     when S_WAIT_2 =>
     	          v.chain_enable := '1';
     	          v.state := S_WAIT;     -- BRAM Wait
     	     when S_CHAIN =>
     	          if modules.chain.done = '1' then
     	              if modules.chain.done_inter = '1' then
     	                  v.state := S_DOUBLE_WRITEBACK;
     	                  v.bram_state := B_WRITE_SIG_I;
     	              else
     	                  if r.ctr < wots_len then
                              v.chain_enable := '1';
                              v.ctr2 := r.ctr; -- update steps and start
     	                  end if;
     	                  v.bram_state := B_WRITE_PK_I;
     	                  v.state := S_WRITEBACK_PK;
     	              end if;
     	          elsif modules.chain.done_inter = '1' then
     	              v.state := S_WRITEBACK_SIG;
     	              v.bram_state := B_WRITE_SIG_I;
                  end if;
             when S_WRITEBACK_SIG =>
     	           v.state := S_CHAIN;
     	     when S_DOUBLE_WRITEBACK =>
     	           if r.ctr < wots_len then
     	               --chain.X <= d.bram.dout; -- next value
                       v.chain_enable := '1';
                       v.ctr2 := r.ctr; -- update steps and start
     	           end if;
     	           v.bram_state := B_WRITE_PK_I;
     	           v.state := S_WRITEBACK_PK;
     	           
     	     when S_WRITEBACK_PK =>
                    if r.ctr = wots_len then
                        v.state := S_FIN;
                    else
                        
                        v.ctr := r.ctr +1;
                        v.state := S_CHAIN;
                    end if;
     	     when S_FIN =>
     	            q.done <= '1';
     	            v.ctr := 0;
     	            v.ctr2 := 0;
     	            v.state := S_IDLE;
        end case;
        r_in <= v;
    end process;

        -- hash
    bram_mux : process(r.bram_state, d.mode, r.ctr)
    begin
        case r.bram_state is
            when B_READ_I => 
                if d.mode = "10" then
                    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_WOTS + r.ctr, BRAM_ADDR_SIZE));
                else
                     q.bram.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_SK + r.ctr, BRAM_ADDR_SIZE));
                end if;
                q.bram.wen <= '0';
            when B_WRITE_PK_I =>
                q.bram.addr <= std_logic_vector(to_unsigned(BRAM_WOTS_PK -1 + r.ctr, BRAM_ADDR_SIZE));
                q.bram.wen <= '1';
            when B_WRITE_SIG_I =>
                q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_WOTS -1 + r.ctr, BRAM_ADDR_SIZE));
                q.bram.wen <= '1';
        end case;
    end process;

    sequential : process(clk)
    --variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	      -- v.ctr2 := 0;
	      -- v.chain_enable := '0';
	      -- v.ctr := 0;
	      -- r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;
end Behavioral;

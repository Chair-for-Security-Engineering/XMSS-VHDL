----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.02.2020 12:14:23
-- Design Name: 
-- Module Name: wots
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
use ieee.numeric_std.all;
use work.xmss_main_typedef.ALL;
use work.xmss_components.ALL;
use work.wots_comp.ALL;
use work.params.ALL;

entity WOTS is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in wots_input_type;
           q     : out wots_output_type);
end WOTS;

architecture Behavioral of WOTS is
    alias m_in : wots_input_type_small is d.module_input;
    alias m_out : wots_output_type_small is q.module_output;

    type state_type is (S_IDLE, S_PRIVKEY_INIT, S_WAIT, S_PRIVKEY);
    type reg_type is record 
        state : state_type;
        block_ctr : unsigned(0 downto 0);
    end record;
    type output_signal is record
        seed_expander : seed_expander_output_type;
        core : wots_core_output_type;
    end record;
    signal core : wots_core_input_type;
    signal seed_expander : seed_expander_input_type;
    signal modules : output_signal;
    signal r, r_in : reg_type;
begin
    
    
    privkey_gen : entity work.seed_expander
	port map(
		clk     => clk,
		reset => reset,
		d  => seed_expander,
		q => modules.seed_expander);

    wots_core : entity work.wots_core
    port map(
       clk          => clk,
       reset        => reset,
       d            => core,
	   q            => modules.core
    );
   
    
    --seed_expander.bram <= d.bram.a;
    q.bram.a <= modules.seed_expander.bram;
    
    core.bram <= d.bram_b;
    q.bram.b <= modules.core.bram;
    
    core.message <= m_in.message;
    core.address_4 <= m_in.address_4;
    
    core.hash <= d.hash;
    core.mode <= m_in.mode;
    seed_expander.input <= m_in.seed;
    seed_expander.hash <= d.hash;
    
    combinational : process (r, d, modules)
	   variable v : reg_type;
	begin
	    v := r;
	    -- core module
	    core.enable <= '0';
	    core.pub_seed <= d.pub_seed;

        -- seed expander 
        seed_expander.enable <= '0';
        
        -- self
        q.module_output.done <= '0';
        
     	case r.state is
     	      when S_IDLE =>
                    if m_in.enable = '1' then
                        if m_in.mode = "10" then -- verify -> we don't need the privkey
                            --core.signature <= d.signature;
                            core.enable <= '1';
                            v.block_ctr := "1";
                            v.state := S_WAIT;
                        else
                            --v.bram_mux := '0';
                            v.block_ctr := "0";
                            v.state := S_PRIVKEY_INIT;
                        end if;
                    end if;
     	      when S_PRIVKEY_INIT =>
                    --seed_expander.input <= d.seed;
                    seed_expander.enable <= '1';
                    v.state := S_PRIVKEY;
              when S_PRIVKEY =>
                    if modules.seed_expander.done = '1' then
                        core.enable <= '1';
                        v.state := S_WAIT;
                        v.block_ctr := "1";
                    end if;
     	      when S_WAIT =>
     	          
     	          -- if done in core submodule, set done and return idling
     	          if modules.core.done = '1' then
     	              m_out.done <= '1';
     	              v.state := S_IDLE;
     	          end if;
     	end case;
     	
        case r.block_ctr is
            when "0" =>
                    q.hash <= modules.seed_expander.hash;
            when "1" =>
                    q.hash <= modules.core.hash;
            when others =>
        end case;
        r_in <= v;
	end process;
	
    
    sequential : process(clk)
   -- variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       --v.block_ctr := "0";
	      -- r <= v;
	    else
		   r <= r_in;
        end if;
       end if;
    end process;

end Behavioral;

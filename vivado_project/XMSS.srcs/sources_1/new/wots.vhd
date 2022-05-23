----------------------------------------------------------------------------------
-- Company: Ruhr-University Bochum / Chair for Security Engineering
-- Engineer: Jan Philipp Thoma
-- 
-- Create Date: 13.08.2020
-- Project Name: Full XMSS Hardware Accelerator
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.xmss_main_typedef.ALL;
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

    type state_type is (S_IDLE, S_WOTS_CORE, S_PRIVKEY);
    type reg_type is record 
        state : state_type;
    end record;
    type output_signal is record
        seed_expander : seed_expander_output_type;
        core : wots_core_output_type;
    end record;
    
    signal hash_select : std_logic;
    signal core : wots_core_input_type;
    signal seed_expander : seed_expander_input_type;
    signal modules : output_signal;
    signal r, r_in : reg_type;
    
    signal DEBUG_WOTS_EN : std_logic;
    signal DEBUG_WOTS_DONE : std_logic;
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
    DEBUG_WOTS_EN <= m_in.enable;
    
    -- Split the dual port bram : Privkey Gen gets one and WOTS Core gets one
    q.bram.a <= modules.seed_expander.bram;
    q.bram.b <= modules.core.bram;
    
    q.hash <= modules.core.hash when hash_select = '0' else modules.seed_expander.hash;
    
    -- Set input signals for WOTS Core
    core.bram <= d.bram_b;
    core.message <= m_in.message;
    core.address_4 <= m_in.address_4;
    core.hash <= d.hash;
    core.mode <= m_in.mode;
    
    -- Set input signals for Privkey Gen
    seed_expander.input <= m_in.seed;
    seed_expander.hash <= d.hash;
    
    combinational : process (r, d, modules)
	   variable v : reg_type;
	begin
	    v := r;
        DEBUG_WOTS_DONE <= '0';
        -- Default Assignments
	    core.enable <= '0';
	    core.pub_seed <= d.pub_seed;

        seed_expander.enable <= '0';
        
        q.module_output.done <= '0';
        
        hash_select <= '0';
        
        ---------------------------------------------
        -- d.mode mapping:                         --
        -- mode = 00 : Keygen only                 --
        -- mode = 01 : Sign + implicit keygen      --
        -- mode = 10 : Verify                      --
        ---------------------------------------------
        
     	case r.state is
     	      when S_IDLE =>
                    if m_in.enable = '1' then
                        if m_in.mode = "10" then -- verify -> we don't need the SK
                            core.enable <= '1';
                            v.state := S_WOTS_CORE;
                        else    -- Sign or Keygen -> Start with generating the SK
                            seed_expander.enable <= '1';
                            v.state := S_PRIVKEY;
                        end if;
                    end if;
              when S_PRIVKEY =>
                    hash_select <= '1';
                    if modules.seed_expander.done = '1' then
                        core.enable <= '1';
                        v.state := S_WOTS_CORE;
                    end if;
     	      when S_WOTS_CORE =>
     	          -- if done in core submodule, set done and return idling
     	          if modules.core.done = '1' then
     	              m_out.done <= '1';
     	              DEBUG_WOTS_DONE <= '1';
     	              v.state := S_IDLE;
     	          end if;
     	end case;
     
        r_in <= v;
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

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.04.2020 08:54:11
-- Design Name: 
-- Module Name: compute_root - Behavioral
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
use work.xmss_functions.ALL;
use work.xmss_main_typedef.ALL;
--use work.wots_comp.ALL;
use IEEE.NUMERIC_STD.ALL;

entity compute_root is
    port (
           clk   : in std_logic;
           reset : in std_logic;
           d     : in xmss_compute_root_input_type;
           q     : out xmss_compute_root_output_type);
end compute_root;

architecture Behavioral of compute_root is
    type state_type is (S_IDLE, S_THASH, S_LOOP, S_WAIT);
    type reg_type is record
        state : state_type;
        ctr : integer range 0 to wots_len;
        leaf_idx : integer range 0 to 2**tree_height;
        thash_enable : std_logic;
        init : std_logic;
    end record;
    signal r, r_in : reg_type;
begin

    -- BRAM
	q.bram.wen <= '0';
    q.bram.en <= '1';
    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_AUTH + r.ctr, BRAM_ADDR_SIZE)); -- Auth Path
    q.bram.din <= (others => '0');
    --q.hash <= d.thash.hash;
    
    q.thash.enable <= '1' when r.thash_enable = '1' else '0';
    --q.thash.hash <= d.hash;
    --q.thash.address <= (x"00000000", std_logic_vector(to_unsigned(r.leaf_idx, 32)), std_logic_vector(to_unsigned(r.ctr, 32)), x"00000000", x"00000002", x"00000000", x"00000000", x"00000000");
	
	q.thash.address_3 <= x"00000002";
    q.thash.address_4 <= x"00000000";
    q.thash.address_5 <= std_logic_vector(to_unsigned(r.ctr, 32));
    q.thash.address_6 <= std_logic_vector(to_unsigned(sr(r.leaf_idx, 1), 32));
	
	q.root <= d.thash.o;

combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;
	    q.done <= '0';
	    v.thash_enable := '0';
        case r.state is
           when S_IDLE =>    
                if d.enable = '1' then
                    v.ctr := 0;
                    v.init := '1';
                    v.leaf_idx := d.leaf_idx;--sr(d.leaf_idx, 1);
                    v.state := S_WAIT;
                end if;     
            when S_THASH =>
                if d.thash.done = '1' then
                    v.leaf_idx := sr(r.leaf_idx, 1); -- shift right
                    v.init := '0';
                    if r.ctr = tree_height - 1 then
                        v.state := S_IDLE;
                        q.done <= '1';
                    else
                        v.ctr := r.ctr + 1;
                        v.state := S_WAIT;   
                    end if;
                end if;
            when S_WAIT => -- BRAM
                v.state := S_LOOP;
            when S_LOOP =>
                v.thash_enable := '1';
                v.state := S_THASH;
        end case;
        -- Assign submodules
        
        r_in <= v;
end process; 

init_mux : process(r.init, d.leaf, d.thash.o, d.bram.dout, r.leaf_idx)
begin
    if r.leaf_idx mod 2 = 0 then
        if r.init = '1' then
            q.thash.input_1 <= d.leaf;
        else
            q.thash.input_1 <= d.thash.o;
        end if;
        q.thash.input_2 <= d.bram.dout;
    else
        q.thash.input_1 <=  d.bram.dout;
        if r.init = '1' then
            q.thash.input_2 <= d.leaf;
        else
            q.thash.input_2 <= d.thash.o;
        end if;
    end if;
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

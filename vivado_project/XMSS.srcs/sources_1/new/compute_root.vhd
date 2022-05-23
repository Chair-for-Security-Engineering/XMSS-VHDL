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
        leaf_idx : unsigned(tree_height-1 downto 0);--integer range 0 to 2**tree_height;
        init : std_logic;
    end record;
    signal r, r_in : reg_type;
begin

    -- Static assignments
	q.bram.wen <= '0';
    q.bram.en <= '1';
    q.bram.addr <= std_logic_vector(to_unsigned(BRAM_XMSS_SIG_AUTH + r_in.ctr, BRAM_ADDR_SIZE)); -- Auth Path
    q.bram.din <= (others => '0');
        
	q.thash.address_3 <= x"00000002";
    q.thash.address_4 <= x"00000000";
    q.thash.address_5 <= std_logic_vector(to_unsigned(r.ctr, 32));
    q.thash.address_6 <= std_logic_vector(shift_right(resize(r.leaf_idx, 32), 1));
	
	q.root <= d.thash.o;

combinational : process (r, d)
	   variable v : reg_type;
	begin
	    v := r;
	    
	    -- Default assignments
	    q.done <= '0';
	    q.thash.enable <= '0';

        case r.state is
           when S_IDLE =>    
                if d.enable = '1' then
                    v.ctr := 0;
                    v.init := '1';
                    v.leaf_idx := to_unsigned(d.leaf_idx, tree_height);
                    v.state := S_WAIT; -- Make sure BRAM data is presnet 
                end if;     
            when S_THASH =>
                if d.thash.done = '1' then
                    -- Shift leaf index for the address
                    v.leaf_idx := shift_right(r.leaf_idx, 1); 
                    
                    -- Set init to 0
                    v.init := '0';
                    
                    -- Check whether the algorithm is done
                    if r.ctr = tree_height - 1 then
                        v.state := S_IDLE;
                        q.done <= '1';
                    else
                        v.ctr := r.ctr + 1;
                        v.state := S_WAIT;   
                    end if;
                end if;
            when S_WAIT => -- BRAM wait state
                v.state := S_LOOP;
            when S_LOOP =>
                q.thash.enable <= '1';
                v.state := S_THASH;
        end case;
        
        r_in <= v;
end process; 


-- Assign the inputs to the thash module
-- If this is the fist round, a leaf node will serve as one input.
-- Otherwise one input is the previous value and the other is part
-- of the auth path stored in BRAM.
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

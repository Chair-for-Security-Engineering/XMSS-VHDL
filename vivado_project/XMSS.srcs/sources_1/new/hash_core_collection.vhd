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


entity hash_core_collection is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in hash_subsystem_input_type;
           q     : out hash_subsystem_output_type);
end hash_core_collection;

architecture Behavioral of hash_core_collection is
    constant ALL_ONES : std_logic_vector(HASH_CORES-1 downto 0) := (others => '1');
    constant ALL_ZEROS : std_logic_vector(HASH_CORES-1 downto 0) := (others => '0');
    
    type hash_output_array is array (HASH_CORES-1 downto 0) of std_logic_vector(n*8-1 downto 0);
    type id_array is array (HASH_CORES-1 downto 0) of hash_id; -- ID = block_ctr || id
    type reg_type is record 
        done_queue, mnext : std_logic_vector(HASH_CORES-1 downto 0);
        ids : id_array;
        busy_indicator, halt_indicator : std_logic_vector(HASH_CORES-1 downto 0);
        busy : std_logic;
    end record;
    
    signal hash_outputs : hash_output_array;
    signal done, mnext, enable : std_logic_vector(HASH_CORES-1 downto 0);
    signal r, r_in : reg_type;
begin

   
   HashCore: for I in 0 to HASH_CORES-1 generate
      SWITCH_SHA : if (HASH_FUNCTION = "SHA") generate
        SHA : entity work.absorb_message 
        port map(
            clk     => clk,
            reset => reset,
            d.enable  => enable(I),
            d.len  => d.len,
            d.input => d.input,
            d.halt => r_in.halt_indicator(I),
            q.done  => done(I),
            q.mnext => mnext(I),
            q.o => hash_outputs(I));
      end generate SWITCH_SHA;
      
      SWITCH_SHA_FAST : if (HASH_FUNCTION = "SHA_FAST") generate
        SHA_FAST : entity work.absorb_message_fast 
        port map(
            clk     => clk,
            reset => reset,
            d.enable  => enable(I),
            d.len  => d.len,
            d.input => d.input,
            d.halt => r_in.halt_indicator(I),
            q.done  => done(I),
            q.mnext => mnext(I),
            q.o => hash_outputs(I));
      end generate SWITCH_SHA_FAST;
      
      SWITCH_SHAKE : if (HASH_FUNCTION = "SHAKE") generate
        SHAKE : entity work.absorb_message_shake 
        port map(
            clk     => clk,
            reset => reset,
            d.enable  => enable(I),
            d.len  => d.len,
            d.input => d.input,
            d.halt => r_in.halt_indicator(I),
            q.done  => done(I),
            q.mnext => mnext(I),
            q.o => hash_outputs(I));
      end generate SWITCH_SHAKE;
   end generate HashCore;
   
   q.idle <= '1' when r.busy_indicator = ALL_ZEROS else '0';
   q.busy <= r.busy;
   combinational : process (r, d, done, mnext, hash_outputs)
	   variable v : reg_type;
	begin
	   v := r;
	   
	   q.done <= '0';
	   q.o <= (others => '-');
	   q.id <= (others => (others => '0'));
	   q.done_id <= (others => (others => '-'));
	   q.mnext <= '0';
	   v.busy := '0';
	   enable <= (others => '0');

	   
	   -- If two done signals appear simultaniously, we need to schedule them --> First prepare a queue of
	   -- finished cores
	   v.done_queue := r.done_queue or done;
	   
	   
       
       
       -- Output the mnext signal for the Core identified in the previous cycle (Loop above)
       -- Data is expected in THE SAME cycle. Release halt which may be set in the event
       -- that multiple hash cores had mnext simultaniously.
       for k in 0 to HASH_CORES-1 loop
            if r.mnext(k) = '1' then
                q.mnext <= '1';
                v.mnext(k) := '0';
                v.halt_indicator(k) := '0';
                v.ids(k).block_ctr := r.ids(k).block_ctr + 1;
                q.id <= v.ids(k);
            end if;
       end loop;
       
       
       -- Iterate through all cores until the first mnext signal is found. The hash module
	   -- expects the next message block in the next cycle.
       for k in 0 to HASH_CORES-1 loop
            if mnext(k) = '1' or r.halt_indicator(k) = '1' then
                v.busy := '1'; -- next cycle will be mnext data -> Prevent other modules to send anything else (e.g. enable)
                v.mnext(k) := '1';
                exit;
            end if;
       end loop;
       
       -- To cover the case where multiple mnext signals occur in the same cycle,
       -- Halt all other Cores that send an mnext signal.
       v.halt_indicator := (r.halt_indicator or mnext) xor v.mnext;
       
       -- Look for done signals and output the first.
       -- Release busy from the respective hash core.
        for k in 0 to HASH_CORES-1 loop
            if r.done_queue(k) = '1' then
                q.done <= '1';
                v.done_queue(k) := '0';
                v.busy_indicator(k) := '0';
                q.done_id <= r.ids(k);
                q.o <= hash_outputs(k);
                exit;
            end if;
        end loop;
       
       -- When the enable signal is set, look for the first hash core that is not
       -- busy and forward the signal. Also save the ID for future use.       
       if d.enable = '1' then
           for k in 0 to HASH_CORES-1 loop
                if r.busy_indicator(k) = '0' then
                    enable(k) <= '1';
                    v.busy_indicator(k) := '1';
                    v.ids(k) := d.id;
                    exit;
                end if;
           end loop;
       end if;
       
       -- Indicate whether all cores are busy (if so, no enable must be send)
       if v.busy_indicator = ALL_ONES then
	       v.busy := '1';
	   end if;
       
       r_in <= v;
	end process;
   
   sequential : process(clk)
   -- variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       -- Zero init queues.
	       r.busy_indicator <= (others => '0');
	       r.done_queue <= (others => '0');
	       r.mnext <= (others => '0');
	       r.halt_indicator <= (others => '0');
	    else
		   r <= r_in;
        end if;
        
       end if;
	end process;
end Behavioral;

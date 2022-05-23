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
use work.shake_comp.ALL;
use work.params.ALL;

entity absorb_message_shake is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in absorb_message_input_type;
           q     : out absorb_message_output_type);
end absorb_message_shake;

-- This Module is responsible for feeding the message into the SHAKE128 algorithm
-- We only allow message sizes < 1344 
-- Further all messages have to be a multiple of 256 bit
-- These constraints do not apply to the given SHA-256 Core
    
architecture Behavioral of absorb_message_shake is
    constant padding_block: unsigned(255 downto 0) := x"1f00000000000000000000000000000000000000000000000000000000000000";
    constant padding : unsigned(63 downto 0) := x"1f00000000000080";

    type state_type is (S_IDLE, S_MSG_ABSORB_1, S_HASH, S_PADDING, S_HASH_START);
    type reg_type is record 
        state : state_type;
        
        message : unsigned(1343 downto 0); -- 1344 bit message block to be absorbed
        remaining_len : integer range 0 to MAX_MLEN;
        
        is_padded, padding_next, done : std_logic;
        
        ctr : integer range 0 to 5;
    end record;
    type out_signals is record
        shake : shake_output_type;
    end record;
    signal shake_reset :std_logic;
    
    signal modules : out_signals;
    signal shake_in : shake_input_type;

    signal r, r_in : reg_type;
begin

    --------- Wire up the hash module:
	shake128 : entity work.KECCAK
	port map(
		clk     => clk,
		reset   => shake_reset,
		start => shake_in.start,
		absorb => shake_in.start,
		data_in => shake_in.din,
		ready => modules.shake.ready,
		data_out => modules.shake.dout

);
    shake_in.din <= std_logic_vector(r_in.message);
    
    -- Output the first 256 Bit of the Keccak permutation
    q.o <= modules.shake.dout(1343 downto 1088);
    q.done <= r.done;
    
    combinational : process (r, d, modules, reset)
	   variable v : reg_type;
	begin
	   v := r;
	   
	   -- default assignments
       q.mnext <= '0';
       v.done := '0';
       v.padding_next := '0';
       shake_in.start <= '0';
       shake_reset <= reset;
       
	   case r.state is
	       when S_IDLE =>
	           if d.enable = '1' then
	               shake_reset <= '1'; -- Reset the Keccak state to 0
	               v.message(319 downto 64)  := unsigned(d.input);
	               
	               v.is_padded := '0';
                   v.ctr := 0;
	               if d.len < 255 then
	                   v.remaining_len := 0;
	                   v.padding_next := '1'; -- Indicate that the next block will start with padding
	               else 
	                   q.mnext <= '1';
	                   v.remaining_len := d.len - 256;
	               end if;
	               v.state := S_MSG_ABSORB_1;
               end if;
           when S_MSG_ABSORB_1 =>
              -- In each cycle, shift the state 256 bit to the left and fill in the next 
              -- 256 bit of the message / padding
              -- Do this 4 times to fill maximum capcity in one block
              
              v.message := SHIFT_LEFT(r.message, 256);
              v.ctr := r.ctr + 1;
              
              if r.remaining_len = 0 then
                    if r.padding_next = '1' then -- padding_next defaults to 0 so we don't need to do this here
                        v.message(319 downto 64) := padding_block;
                        v.is_padded := '1';
                    else
                        v.message(319 downto 64) := (others => '0');
                    end if;
                    
              elsif r.remaining_len = 256 then -- get the next message block and check whether we need do padding in the next block
                    v.message(319 downto 64) := unsigned(d.input);
                    v.padding_next := '1';
                    v.remaining_len := 0;
              else
                    v.message(319 downto 64) := unsigned(d.input);
                    v.remaining_len := r.remaining_len - 256;
                    q.mnext <= '1';
              end if;
              if r.ctr = 3 then
                    v.state := S_PADDING;
              end if;
              
           when S_PADDING => -- Append the last 64 Bit padding block
              if r.is_padded = '1' then
                v.message(63 downto 0) := (7 => '1', others => '0');
              else
                v.message(63 downto 0) := padding;
              end if;
              -- Enable the hash function (start signal needs 2 cycles)
              shake_in.start <= '1';
              v.state := S_HASH_START; 
           when S_HASH_START =>
              shake_in.start <= '1';
              v.state := S_HASH;
           when S_HASH =>
              -- Wait until hash is done
              if modules.shake.ready = '1' then
                    v.done := '1';
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
	    elsif d.halt = '0' then
		   r <= r_in;
        end if;
        
       end if;
	end process;
	
	
end Behavioral;

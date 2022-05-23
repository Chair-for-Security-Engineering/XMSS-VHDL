----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.02.2020 09:46:29
-- Design Name: 
-- Module Name: wots_chain - Behavioral
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
-- work.wots_functions.ALL;
use work.sha_comp.ALL;
use work.params.ALL;
use work.sha_functions.ALL;

entity absorb_message is
    Generic (BLOCK_SIZE : integer := 512;
             PADDING_LENGTH : integer := 64); -- must be multiple of n
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in absorb_message_input_type;
           q     : out absorb_message_output_type);
end absorb_message;


    
architecture Behavioral of absorb_message is
    constant INPUTS_PER_BLOCK : Integer := BLOCK_SIZE / (8*n);
    
    type state_type is (S_IDLE, S_MSG_ABSORB, S_WAIT);
    type reg_type is record 
        state : state_type;
	    is_padded, last : std_logic;

        message : std_logic_vector(n*8-1 downto 0); -- 256 bit message block to be absorbed
        input_length : integer;
        --ctr : integer;
        out_reg : std_logic_vector(n*8-1 downto 0);
        -- counter
        absorb_ctr : Integer;
        done : std_logic;
    end record;
    type out_signals is record
        sha : sha_output_type;
    end record;
    signal hash_block : std_logic_vector(31 downto 0);   -- 32 bit hash input block
    signal modules : out_signals;
    signal r, r_in : reg_type;
    signal hash_enable : std_logic;
begin

    --------- Wire up the hash module:
	sha_256 : entity work.sha256
	port map(
		clk     => clk,
		reset   => reset,
		d.enable  => hash_enable,
		d.last    => r_in.last,      
		d.message => hash_block, 
		q         => modules.sha
		);

    q.o <= r.out_reg;
    q.done <= r.done;

    combinational : process (r, d, modules)
	   variable v : reg_type;
	begin
	   v := r;
	   hash_enable <= '0';
       q.mnext <= '0';
       hash_block <= (others => '0');
       
	   v.done := '0';
	  -- end if;
       
	   case r.state is
	       when S_IDLE =>
	           -- Wait until enable is set...
	           if d.enable = '1' then
	               v.is_padded := '0';
                   v.absorb_ctr := 0;          
                   
                   -- get the first message block
	               v.message := d.input;
	               v.input_length := d.len - 8*n;
	               
	               -- Padding indicator for very short messages
	               if v.input_length < 0 then
	                   v.message(n*8-1-d.len) := '1';
	                   v.is_padded := '1';
	               end if;
	               v.state := S_MSG_ABSORB;
               end if;
               v.last := '0';
               
           when S_MSG_ABSORB =>
              -- Absorbs 16 x 32 Bit message blocks and padding if the current block is the last one.
              case r.absorb_ctr is
                    when 0 => 
                        hash_enable <= '1';
                        if r.is_padded = '0' and r.input_length < 0 then
                           v.message(n*8-1-(d.len mod (n*8))) := '1';
                           v.is_padded := '1';
	                    end if;
                    when 6 =>
                        if r.input_length > 0 then
                            q.mnext <= '1';
                        end if;
                    when 8 =>
                        if r.input_length > 0 then
                            v.message := d.input;
                        else
                            v.message := std_logic_vector(to_unsigned(0, n*8));
                        end if;
                        v.input_length := r.input_length - 8*n;
                        if r.is_padded = '0' and v.input_length < 0 then
                           v.message(n*8-1-(d.len mod (n*8))) := '1';
                           v.is_padded := '1';
	                    end if;
	                    if v.input_length + PADDING_LENGTH < 0 then
                              v.message := v.message or gen_padding_SHA256(d.len);
                              v.last := '1';
                        end if;
                    when 15 =>
                        if v.input_length > 0 then
                            q.mnext <= '1';
                        end if;
                        v.state := S_WAIT;
                    when others =>
              end case;
              hash_block <= v.message((8*n)-(r.absorb_ctr mod 8)*32-1 downto (8*n)-(r.absorb_ctr mod 8)*32- 32);
              v.absorb_ctr := r.absorb_ctr + 1;
           when S_WAIT =>
              
              
              if modules.sha.done = '1' then
                  v.state := S_IDLE;
                  v.done := '1';
                  v.out_reg := modules.sha.hash;
              end if;
              
              -- If mnext is set, feed the next message block
              if modules.sha.mnext = '1' then
                  if v.input_length > 0 then
                        v.message := d.input;
                  else
                        v.message := std_logic_vector(to_unsigned(0, n*8));
                  end if;
                  v.input_length := v.input_length - 8*n;    
                  v.absorb_ctr := 0;           
                  v.state := S_MSG_ABSORB;
              end if;

	   end case;
	   
       r_in <= v;
	end process;
	
	
    sequential : process(clk)
   -- variable v : reg_type;
	begin
	   if rising_edge(clk) then
	    if reset = '1' then
	       r.state <= S_IDLE;
	       --v.done := '0';
	       --r <= v;
	    else
		   r <= r_in;
        end if;
        
       end if;
	end process;
	
	
end Behavioral;

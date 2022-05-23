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
use work.sha_fast_comp.ALL;
use work.params.ALL;
use work.sha_functions.ALL;

entity absorb_message_fast is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           d     : in absorb_message_input_type;
           q     : out absorb_message_output_type);
end absorb_message_fast;

-- This Module is responsible for feeding the message in 32 Bit Chunks to 
-- the underlying SHA Module and creating the padding
    
architecture Behavioral of absorb_message_fast is
    type state_type is (S_IDLE, S_MSG_ABSORB_1, S_MSG_ABSORB_2, S_MNEXT_1, S_MNEXT_2);
    type reg_type is record 
        state : state_type;
	    is_padded, last : std_logic;
        message : unsigned(255 downto 0); -- 256 bit message block to be absorbed
        input_len, remaining_len : integer range 0 to MAX_MLEN;

        hash_enable : std_logic;
    end record;
    type out_signals is record
        sha : sha_output_type;
    end record;
    
    signal msg : unsigned(31 downto 0);
    signal mode : std_logic_vector(1 downto 0);
    signal modules : out_signals;
    signal r, r_in : reg_type;
begin

    --------- Wire up the hash module:
	sha_256 : entity work.sha_256_fast
	port map(
		clk     => clk,
		reset   => reset,
		d.enable  => r_in.hash_enable,
		d.halt => d.halt,
		d.mode => mode,
		d.last    => r.last,      
		d.message => msg, 
		q         => modules.sha
		);

    -- The output is equal to the underlying SHA Module
    q.o <= modules.sha.hash;
    q.done <= modules.sha.done;

    combinational : process (r, d, modules)
	   variable v : reg_type;
	begin
	   v := r;
	   v.hash_enable := '0';
       q.mnext <= '0';
       msg <= r.message(255 downto 224);
       
	   case r.state is
	       when S_IDLE =>
	           if d.enable = '1' then
                   -- get the first message block and start hashing
	               v.message := unsigned(d.input(63 downto 0)) & to_unsigned(0, 192);
	               v.hash_enable := '1';
	               v.input_len := d.len;
	               
	               -- Padding indicator for very short messages
	               -- This doesn't really happen in XMSS except if very short
	               -- messages should be signed.
	               if d.len < 255 then
	                   v.remaining_len := 0;
	                   v.message(n*8-1-d.len) := '1';
	                   v.is_padded := '1';
	                   v.last := '1';
	               else 
	                   v.is_padded := '0';
	                   v.remaining_len := d.len - 256;
	                   v.last := '0';
	               end if;
	               
	               v.state := S_MSG_ABSORB_1;
               end if;
               
               
           --when S_INIT =>
           --   msg <= unsigned(r.message(31 downto 0));
           --   v.state := S_MNEXT_1;
           --   if r.remaining_len /= 0 then
           --       q.mnext <= '1';
           --   end if;
           when S_MSG_ABSORB_1 =>
              
              v.message := SHIFT_LEFT(r.message, 32);
              
              if modules.sha.mnext = '1' then
                    v.state := S_MNEXT_1;
                    if r.remaining_len /= 0 then
                        q.mnext <= '1';
                    end if;
              end if;
           when S_MNEXT_1 => 
              if r.remaining_len > 255 then
                   v.message := unsigned(d.input); 
	               v.remaining_len := r.remaining_len - 256;
	          else
	               v.message := (others => '0');
	               if r.remaining_len = 0 then -- there is no more message left
	                   if  r.is_padded = '0' then  -- padding 1 not in place
	                       v.message(255) := '1';
	                   end if;
	               else
	                   v.message := unsigned(d.input); 
	                   v.message(255-r.remaining_len) := '1';
	                   v.remaining_len := 0;
	               end if;
	               v.is_padded := '1';
              end if;
              
	          if r.remaining_len < 191 then
	               v.message := v.message or gen_padding_SHA256(r.input_len);
	               v.last := '1';
	          end if;
	          v.state := S_MSG_ABSORB_2;
	      when S_MSG_ABSORB_2 =>
	          v.message := SHIFT_LEFT(r.message, 32);

              if modules.sha.mnext = '1' then
                    v.state := S_MNEXT_2;
                    if r.last = '0' then
                        q.mnext <= '1';
                    end if;
              end if;
              
              if modules.sha.done = '1' then
                    v.state := S_IDLE;
              end if;
	      when S_MNEXT_2 =>
              if r.remaining_len > 255 then
                   v.message := unsigned(d.input); 
	               v.remaining_len := r.remaining_len - 256;
	          else
	               if r.remaining_len = 0 then -- there is no more message left
	                   -- message is implicitly 0 due to SHIFT
	                   if  r.is_padded = '0' then  -- padding 1 not in place
	                       v.message(255) := '1';
	                   end if;
	               else
	                   v.message := unsigned(d.input); 
	                   v.message(255-r.remaining_len) := '1';
	                   v.remaining_len := 0;
	               end if;
	               v.is_padded := '1';
              end if;
	          v.state := S_MSG_ABSORB_1;

	   end case;
	   
       r_in <= v;
	end process;
	
	
    sequential : process(clk)
   -- variable v : reg_type;
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

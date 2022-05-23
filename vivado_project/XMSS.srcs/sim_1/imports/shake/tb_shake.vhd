----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/19/2019 12:26:42 PM
-- Design Name: 
-- Module Name: tb_shake - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_shake is
end tb_shake;

architecture Behavioral of tb_shake is

    signal clk             : std_logic := '0';
    signal finished        : std_logic := '0';
    constant clk_period    : time := 10 ns;
    
    signal DATA_IN         : std_logic_vector (1344-1 downto 0)  := (others => '0');
    signal DATA_IN_LENGTH  : std_logic_vector (7 downto 0)  := (others => '0'); -- length of data
    signal SHAKE256        : std_logic := '0'; -- '0' = SHAKE128, '1' = SHAKE256
    signal RESET           : std_logic := '0';
    signal START           : std_logic := '0';
    signal READY           : std_logic := '0';
    signal ABSORB          : std_logic := '0';
    signal DATA_OUT        : std_logic_vector (1344-1 downto 0);
    
begin

    clk <= not clk after clk_period/2;
    
    uut : entity work.SHAKE
    port map ( 
        CLK => clk,
        DATA_IN => DATA_IN,
        DATA_IN_L => DATA_IN_LENGTH,
        SHAKE256 => SHAKE256,
        RESET => RESET,
        START => START,
        READY => READY,
        ABSORB => ABSORB,
        DATA_OUT => DATA_OUT
        );
    
    tb : process
    
    file invecfile, inveclenfile, resvecfile, squeezefile : text;
    variable invecline, inveclenline, resvecline, squeezeline : line;
    variable flag128 : boolean := true;
    variable invec128 : string(1 to 1344/4);
    variable invec256 : string(1 to 1088/4);
    variable inveclen : integer range 0 to 255;
    variable squeeze : std_logic;
    variable resvec : std_logic_vector(255 downto 0);
    
    function str_to_slv(str : string) return std_logic_vector is
  alias str_norm : string(1 to str'length) is str;
  variable char_v : character;
  variable val_of_char_v : natural;
  variable res_v : std_logic_vector(4 * str'length - 1 downto 0);
begin
  for str_norm_idx in str_norm'range loop
    char_v := str_norm(str_norm_idx);
    case char_v is
      when '0' to '9' => val_of_char_v := character'pos(char_v) - character'pos('0');
      when 'A' to 'F' => val_of_char_v := character'pos(char_v) - character'pos('A') + 10;
      when 'a' to 'f' => val_of_char_v := character'pos(char_v) - character'pos('a') + 10;
      when others => report "str_to_slv: Invalid characters for convert" severity ERROR;
    end case;
    res_v(res_v'left - 4 * str_norm_idx + 4 downto res_v'left - 4 * str_norm_idx + 1) :=
      std_logic_vector(to_unsigned(val_of_char_v, 4));
  end loop;
  return res_v;
end function;
    
    begin
        
        -- first reset
        RESET <= '1';
        
        wait for 2*clk_period;
        wait for 1 ns;
        
        RESET <= '0';
        
        file_open(invecfile,    "C:\Users\Jan\Downloads\shake\vecs_128_invec.txt",    read_mode);
        file_open(inveclenfile, "C:\Users\Jan\Downloads\shake\vecs_128_inveclen.txt", read_mode);
        file_open(squeezefile,  "C:\Users\Jan\Downloads\shake\vecs_128_squeeze.txt",  read_mode);
        file_open(resvecfile,   "C:\Users\Jan\Downloads\shake\vecs_128_RESULTS.txt",  write_mode);
        SHAKE256 <= '0';
        
        wait for clk_period;
        
        while true
        loop
            while not endfile(invecfile) and not endfile(inveclenfile)
            loop
            
                readline(invecfile,    invecline);
                readline(inveclenfile, inveclenline);
                readline(squeezefile,  squeezeline);
                
                read(squeezeline, squeeze);
                
                if squeeze = '0'
                then
                    read(inveclenline, inveclen);
                    if flag128
                    then
                        read(invecline, invec128);
                        DATA_IN <= str_to_slv(invec128);
                    else
                        read(invecline, invec256);
                        DATA_IN(1343 downto 256) <= str_to_slv(invec256);
                        DATA_IN(255 downto 0) <= (others => '0');
                    end if;
                    
                    DATA_IN_LENGTH <= std_logic_vector(to_unsigned(inveclen, DATA_IN_LENGTH'length));
                    START <= '1';
                    ABSORB <= '1';
                    
                    wait until READY = '0'; -- absorb done, permutation running
                    START <= '0';
                    ABSORB <= '0';
                    
                    wait until READY = '1'; -- all permutation rounds done
                 else
                 
                    resvec := DATA_OUT(1343 downto 1344-256);
                    hwrite(resvecline, resvec);
                    writeline(resvecfile, resvecline);
                    
                    RESET <= '1';
                    wait for 10 ns;
                    RESET <= '0';
                 
                 end if;
                
            end loop;
            
            file_close(invecfile);
            file_close(inveclenfile);
            file_close(squeezefile);
            file_close(resvecfile);
            file_close(squeezefile);
            
            if flag128
            then
                flag128 := false;
                file_open(invecfile,    "vecs_256_invec.txt",    read_mode);
                file_open(inveclenfile, "vecs_256_inveclen.txt", read_mode);
                file_open(squeezefile,  "vecs_256_squeeze.txt",  read_mode);
                file_open(resvecfile,   "vecs_256_RESULTS.txt",  write_mode);
                SHAKE256 <= '1';
            else
                exit;
            end if;
            
        end loop;
        
        assert false severity failure; 
    
    end process;

end Behavioral;

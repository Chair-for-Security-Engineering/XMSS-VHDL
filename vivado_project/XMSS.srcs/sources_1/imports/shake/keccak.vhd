----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2018 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann, Georg Land
--
-- CREATE DATE:			    13/12/2018
-- LAST CHANGES:            10/01/2020
-- MODULE NAME:			    KECCAK
--
-- REVISION:				1.00 - KECCAK top level
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or if you have questions regarding the code
--							please contact Tim G�neysu (tim.gueneysu@rub.de) and
--                          Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
-- KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
----------------------------------------------------------------------------------

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
    USE work.keccak_settings.ALL;
    

ENTITY KECCAK IS
    PORT ( CLK          : IN  STD_LOGIC;
           RESET        : IN  STD_LOGIC;
           START        : IN  STD_LOGIC;
           READY        : OUT STD_LOGIC;
           -- ABSORB ------------------------
           ABSORB       : IN  STD_LOGIC;
           DATA_IN      : IN  STD_LOGIC_VECTOR (RATE-1 DOWNTO 0);
           -- SQUEEZE -----------------------
           DATA_OUT     : OUT STD_LOGIC_VECTOR (RATE-1 DOWNTO 0));
END KECCAK;

ARCHITECTURE Structural OF KECCAK IS



-- SIGNALS -----------------------------------------------------------------------
SIGNAL STATE_OUT                            : keccak_m := (OTHERS => (OTHERS => (OTHERS => '0')));
SIGNAL STATE_REG, STATE_REG_IN              : keccak_m;
SIGNAL ROUND_NUMBER                         : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
SIGNAL ROUND_NUMBER_IN                      : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
SIGNAL DATA_OUT_TMP                         : STD_LOGIC_VECTOR (RATE-1 DOWNTO 0);

-- ABSORB
SIGNAL ENABLE_DATA_IN                       : STD_LOGIC;

-- COUNTER
SIGNAL CNT_EN_ROUND, CNT_RST_ROUND          : STD_LOGIC;
SIGNAL CNT_ROUND                            : STD_LOGIC_VECTOR((CNT_LENGTH_ROUND-1) DOWNTO 0);

SIGNAL RESET_IO                             : STD_LOGIC;
SIGNAL ENABLE_ROUND                         : STD_LOGIC;



-- STRUCTURAL ---------------------------------------------------------------------
BEGIN

    -- I/O Register  
    keccak_reg : PROCESS (clk, RESET_IO)
    BEGIN
        IF(RESET_IO ='1') THEN
            STATE_REG <= (OTHERS => (OTHERS => (OTHERS => '0')));
        ELSIF(RISING_EDGE(clk)) THEN 
            IF ENABLE_ROUND = '1' THEN
                STATE_REG <= STATE_OUT;
            END IF;
            IF ENABLE_DATA_IN = '1' THEN
                STATE_REG <= STATE_REG_IN;
            END IF;
        END IF;
    END PROCESS;
    
    a001 : FOR i IN 0 to RATE_LANES - 1
    GENERATE
        a011: FOR j in 0 to LANE_WIDTH/8-1
        GENERATE
            STATE_REG_IN(i mod 5)(i / 5)(j*8+7 downto j*8) <= STATE_REG(i mod 5)(i / 5)(j*8+7 downto j*8)
                        XOR DATA_IN(RATE - i * LANE_WIDTH - j*8 - 1 DOWNTO RATE - i * LANE_WIDTH - j*8 - 8);
        END GENERATE a011;
    END GENERATE a001;
    
    a002 : FOR i IN RATE_LANES TO 24
    GENERATE
        STATE_REG_IN(i mod 5)(i / 5) <= STATE_REG(i mod 5)(i / 5);
    END GENERATE a002;
    
    -- DATA OUTPUT
    o001 : FOR i in 0 to RATE_LANES - 1
    GENERATE
        o002 : FOR z in 0 to LANE_WIDTH - 1
        GENERATE
            DATA_OUT_TMP(LANE_WIDTH * i + z) <= STATE_REG(i mod 5)(i / 5)(z);
        END GENERATE o002; 
    END GENERATE o001; 
    
    -- DATA OUTPUT, invert byte-wise
    i001 : FOR i in 0 to RATE/8-1
    GENERATE
        DATA_OUT(i*8+7 DOWNTO i*8) <= DATA_OUT_TMP(RATE-i*8-1 DOWNTO RATE-i*8-8);
    END GENERATE i001;
                    
    -- KECCAK round function
    KECCAK_ROUND : ENTITY work.keccak_round
        PORT MAP (
            STATE_IN     => STATE_REG,
            STATE_OUT    => STATE_OUT,
            ROUND_NUMBER => CNT_ROUND
        );
    
    -- Round Counter
    COUNTER_ROUND : ENTITY work.KECCAK_COUNTER
    GENERIC MAP (
        SIZE            => CNT_LENGTH_ROUND,
        MAX_VALUE       => N_R-1)
    PORT MAP (
        CLK             => CLK,
        EN              => CNT_EN_ROUND,
        RST             => CNT_RST_ROUND,
        CNT_OUT         => CNT_ROUND
    );
    
    -- KECCAK Finite State Machine
    FSM : ENTITY work.KECCAK_CONTROLLER
    PORT MAP (
        CLK             => CLK,
        RESET           => RESET,
        START           => START,
        ABSORB          => ABSORB,
        ENABLE_DATA_IN  => ENABLE_DATA_IN,
        READY           => READY,
        ENABLE_ROUND    => ENABLE_ROUND,
        RESET_IO        => RESET_IO,
        CNT_EN_ROUND    => CNT_EN_ROUND,
        CNT_RST_ROUND   => CNT_RST_ROUND,
        CNT_ROUND       => CNT_ROUND
    );

END Structural;

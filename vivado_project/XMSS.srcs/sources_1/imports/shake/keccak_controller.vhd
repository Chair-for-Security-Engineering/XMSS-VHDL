----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2018 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann, Georg Land
--
-- CREATE DATE:			    13/12/2018
-- LAST CHANGES:            10/01/2020
-- MODULE NAME:			    KECCAK_CONTROLLER
--
-- REVISION:				1.00 - File created: finite state machine
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
    USE IEEE.NUMERIC_STD.ALL;
    
LIBRARY work;
    USE work.keccak_settings.ALL;


ENTITY KECCAK_CONTROLLER IS
    Port (  CLK             : IN  STD_LOGIC;
            RESET           : IN  STD_LOGIC;
            START           : IN  STD_LOGIC;
            -- CONTROL DATA INPUT ----------------
            ABSORB          : IN  STD_LOGIC;
            ENABLE_DATA_IN  : OUT STD_LOGIC;
            -- CONTROL PERMUTATION ---------------
            ENABLE_ROUND    : OUT STD_LOGIC;
            -- IO --------------------------------
            RESET_IO        : OUT STD_LOGIC;
            READY           : OUT STD_LOGIC;
            -- COUNTER ---------------------------
            CNT_EN_ROUND    : OUT STD_LOGIC;
            CNT_RST_ROUND   : OUT STD_LOGIC;
            CNT_ROUND       : IN  STD_LOGIC_VECTOR((CNT_LENGTH_ROUND-1)  DOWNTO 0)
            );
END KECCAK_CONTROLLER;



-- ARCHITECTURE ------------------------------------------------------------------
ARCHITECTURE FSM OF KECCAK_CONTROLLER IS



-- SIGNALS -----------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_DATA_IO, S_PERMUTE);
SIGNAL STATE, NEXT_STATE : STATES := S_RESET;



-- FSM ---------------------------------------------------------------------------
BEGIN

    SYNC : PROCESS(CLK)
    BEGIN
        IF rising_edge(CLK)
        THEN
            IF RESET = '1'
            THEN
                STATE <= S_RESET;
            ELSE
                STATE <= NEXT_STATE;
            END IF;
        END IF;
    END PROCESS;

    -- FINITE STATE MACHINE - PROCESS --------------------------------------------
    MEALY : PROCESS(STATE, START, CNT_ROUND, ABSORB)
    BEGIN
        -- STATE TRANSITIONS -----------------------------------------------------
        CASE STATE IS
            
            ------------------------------------------------------------------
            WHEN S_RESET        =>
                -- INTERALS ----------
                RESET_IO        <= '1';
                ENABLE_DATA_IN  <= '0';
                ENABLE_ROUND    <= '0';
                
                -- OUTPUT -------------
                READY           <= '1';
                
                -- COUNTER ------------
                CNT_EN_ROUND    <= '0';
                CNT_RST_ROUND   <= '1';
                
                -- TRANSITION ---------
                IF(START = '1') THEN
                    NEXT_STATE  <= S_DATA_IO;
                ELSE
                    NEXT_STATE  <= S_RESET;
                END IF;
            ------------------------------------------------------------------
            
            ------------------------------------------------------------------
            WHEN S_DATA_IO      =>
                -- INTERALS ----------
                RESET_IO        <= '0';
                ENABLE_DATA_IN  <= ABSORB;
                ENABLE_ROUND    <= '0';
                
                -- OUTPUT -------------
                READY           <= '1';
                
                -- COUNTER ------------
                CNT_EN_ROUND    <= '0';
                CNT_RST_ROUND   <= '1';
                
                -- TRANSITION ---------
                IF START = '1'
                THEN
                    NEXT_STATE  <= S_PERMUTE;
                ELSE
                    NEXT_STATE  <= S_DATA_IO;
                END IF;
            ------------------------------------------------------------------
            
            ------------------------------------------------------------------
            WHEN S_PERMUTE      =>
                -- INTERALS ----------
                RESET_IO        <= '0';
                ENABLE_DATA_IN  <= '0';
                ENABLE_ROUND    <= '1';
                
                -- OUTPUT -------------
                READY           <= '0';
                
                -- COUNTER ------------
                CNT_EN_ROUND    <= '1';
                CNT_RST_ROUND   <= '0';
                
                -- TRANSITION ---------
                IF to_integer(unsigned(CNT_ROUND)) = N_R-1
                THEN
                    NEXT_STATE  <= S_DATA_IO;
                ELSE
                    NEXT_STATE  <= S_PERMUTE;
                END IF; 
            ------------------------------------------------------------------
                          
            ------------------------------------------------------------------
            WHEN OTHERS         =>
                -- INTERALS ----------
                RESET_IO        <= '1';
                ENABLE_DATA_IN  <= '0';
                ENABLE_ROUND    <= '0';
                
                -- OUTPUT -------------
                READY           <= '1';
                
                -- COUNTER ------------
                CNT_EN_ROUND    <= '0';
                CNT_RST_ROUND   <= '1';
                
                -- TRANSITION ---------
                NEXT_STATE      <= S_RESET;
            ------------------------------------------------------------------
        END CASE;
    END PROCESS;

END FSM;

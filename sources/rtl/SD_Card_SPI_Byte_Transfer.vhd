----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/17/2017 05:33:17 PM
-- Design Name: 
-- Module Name: SD_Card_SPI_Byte_Transfer - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY SD_Card_SPI_Byte_Transfer IS
    PORT (
    clk210_p                : IN    STD_LOGIC;
    reset_p                 : IN    STD_LOGIC;
    sd_spi_mosi_p           : OUT   STD_LOGIC;
    sd_spi_miso_p           : IN    STD_LOGIC;        
    sd_spi_sck_p            : OUT   STD_LOGIC;
    sd_spi_ltransfer_in_p   : OUT   STD_LOGIC_VECTOR( 7 DOWNTO 0);
    sd_spi_ltransfer_out_p  : IN    STD_LOGIC_VECTOR( 7 DOWNTO 0);    
    sd_spi_init_trans_p     : IN    STD_LOGIC;
    sd_spi_byte_done_p      : OUT   STD_LOGIC;
    sd_spi_select_speed_p   : IN    STD_LOGIC;
    sd_spi_normal_baud_p    : IN    STD_LOGIC;    
    sd_spi_init_baud_p      : IN    STD_LOGIC
    );
END SD_Card_SPI_Byte_Transfer;

ARCHITECTURE Behavioral OF SD_Card_SPI_Byte_Transfer IS
    
    TYPE sd_spi_state_type IS (
        IDLE_st,             
        WAIT_FOR_SCK_HIGH_st,
        WAIT_FOR_SCK_LOW_st,
        CHECK_BIT_COUNTS_st,
        DONE_st);             
    
    
    SIGNAL      sd_spi_byte_state_s     : sd_spi_state_type;
    SIGNAL      sd_spi_sck_s            : STD_LOGIC := '0';
    SIGNAL      sd_spi_mosi_s           : STD_LOGIC := '0';
    SIGNAL      sd_spi_baud_rate_s      : STD_LOGIC;
    SIGNAL      sd_spi_ltransfer_out_s  : STD_LOGIC_VECTOR( 7 DOWNTO 0);  
    SIGNAL      sd_spi_num_bit_tfers_s  : INTEGER RANGE 0 to 20;
    SIGNAL      sd_spi_ltransfer_in_s   : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL      sd_spi_byte_done_s      : STD_LOGIC := '0';
    
    
    attribute mark_debug    : string;
    attribute keep          : string;

BEGIN


    -- output assignments
    sd_spi_sck_p            <= sd_spi_sck_s;
    sd_spi_mosi_p           <= sd_spi_mosi_s;
    sd_spi_byte_done_p      <= sd_spi_byte_done_s;
    sd_spi_ltransfer_in_p   <= sd_spi_ltransfer_in_s;
    
    -- selections
    sd_spi_baud_rate_s      <= sd_spi_normal_baud_p WHEN  sd_spi_select_speed_p = '1' ELSE      -- selecting the speed.
                               sd_spi_init_baud_p   WHEN  sd_spi_select_speed_p = '0';


    BYTE_TRANSFER_SM: 
    PROCESS (clk210_p, reset_p) BEGIN       
    
        IF reset_p = '1' THEN
            sd_spi_byte_state_s     <= IDLE_st;  
            sd_spi_num_bit_tfers_s  <= 0;
            sd_spi_byte_done_s      <= '0';
            sd_spi_sck_s            <= '0';
            sd_spi_mosi_s           <= '0';
            
        ELSIF RISING_EDGE (clk210_p) THEN       
            CASE (sd_spi_byte_state_s) IS
            
            -- wait for the master to raise the init transfer signal
            WHEN IDLE_st =>
                IF (sd_spi_init_trans_p = '1') THEN
                    sd_spi_ltransfer_out_s      <= sd_spi_ltransfer_out_p(6 DOWNTO 0) & '1';    -- get the data that needs to be transfered out
                                                                                                -- Note that the ltransfer_s register is being shifted
                                                                                                -- by a bit already. This is because ltransfer_out_p[7] is
                                                                                                -- used on the mosi_p line on the start (immediately after
                                                                                                -- SS is pulled low by the higher module - or during the middle
                                                                                                -- of a bunch of transactions but at the start of a new byte)
                    sd_spi_mosi_s               <= sd_spi_ltransfer_out_p(7);
                    sd_spi_byte_state_s         <= WAIT_FOR_SCK_HIGH_st;
                    sd_spi_sck_s                <= '0';
                    sd_spi_num_bit_tfers_s      <= 0;
                    sd_spi_byte_done_s          <= '0';
                ELSE 
                    sd_spi_sck_s                <= '0';
                    sd_spi_byte_state_s         <= IDLE_st;
                    sd_spi_num_bit_tfers_s      <= 0;
                    sd_spi_byte_done_s          <= '0';
                END IF;
            
            -- wait for the a baud tick. Raise the sck signal and shift in a new bit
            WHEN WAIT_FOR_SCK_HIGH_st =>
                IF (sd_spi_baud_rate_s = '1') THEN
                    sd_spi_sck_s                <= '1';
                    sd_spi_ltransfer_in_s       <= sd_spi_ltransfer_in_s(6 DOWNTO 0) & sd_spi_miso_p;
                    sd_spi_num_bit_tfers_s      <= sd_spi_num_bit_tfers_s + 1;
                    sd_spi_byte_state_s         <= WAIT_FOR_SCK_LOW_st;                
                ELSE 
                    sd_spi_byte_state_s         <= WAIT_FOR_SCK_HIGH_st;
                END IF;
            
            -- wait for a baud tick. lower the sck signal and shift out a new bit
            WHEN WAIT_FOR_SCK_LOW_st =>
                IF (sd_spi_baud_rate_s = '1') THEN
                    sd_spi_sck_s                <= '0';
                    -- sd_spi_ltransfer_out_s      <= sd_spi_ltransfer_out_s(6 DOWNTO 0) & '1';
                    -- sd_spi_mosi_s               <= sd_spi_ltransfer_out_s(7);
                    sd_spi_byte_state_s         <= CHECK_BIT_COUNTS_st;
                ELSE 
                    sd_spi_byte_state_s         <= WAIT_FOR_SCK_LOW_st;
                END IF;
             
            -- check if the number of transfers is 8. If it is, raise the done flag and 
            -- move to the done state. 
            WHEN CHECK_BIT_COUNTS_st =>
                IF (sd_spi_num_bit_tfers_s = 8) THEN
                    sd_spi_num_bit_tfers_s      <= 0;
                    sd_spi_byte_state_s         <= DONE_st;
                    sd_spi_byte_done_s          <= '1';
                ELSE 
                    sd_spi_byte_state_s         <= WAIT_FOR_SCK_HIGH_st;
                    sd_spi_ltransfer_out_s      <= sd_spi_ltransfer_out_s(6 DOWNTO 0) & '1';
                    sd_spi_mosi_s               <= sd_spi_ltransfer_out_s(7);
                END IF;
            
            -- wait for the higher module to lower the init trans signal. Then, this module
            -- clears the done flag and moves to the idle state where it waits for an init
            -- transfer signal.
            WHEN DONE_st =>
                IF (sd_spi_init_trans_p = '0') THEN
                    sd_spi_byte_state_s         <= IDLE_st;
                    sd_spi_byte_done_s          <= '0';
                ELSE
                    sd_spi_byte_state_s         <= DONE_st;
                END IF;                
            
            WHEN OTHERS =>
                sd_spi_byte_state_s             <= IDLE_st;
            
            END CASE;        
        END IF;
    END PROCESS;
    

END Behavioral;

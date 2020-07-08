----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/27/2017 09:28:53 AM
-- Design Name: 
-- Module Name: SD_Card_interface_top - Behavioral
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


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
LIBRARY work;
USE work.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY SD_Card_interface_top IS
 PORT (
    clk210_p                : IN    STD_LOGIC;
    reset_p                 : IN    STD_LOGIC;
    
    sd_spi_ss_p             : OUT   STD_LOGIC;
    sd_spi_mosi_p           : OUT   STD_LOGIC;
    sd_spi_sck_p            : OUT   STD_LOGIC;
    sd_spi_miso_p           : IN    STD_LOGIC;
    
    sd_ccs_bit_p            : OUT   STD_LOGIC;
    sd_spi_init_done_p      : OUT   STD_LOGIC;
    sd_spi_transfer_done_p  : OUT   STD_LOGIC;
    sd_spi_cntrl_status_p   : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0);
    
    sd_write_fifo_din_p     : IN    STD_LOGIC_VECTOR( 7 DOWNTO 0);
    sd_write_fifo_wr_en_p   : IN    STD_LOGIC;
    sd_write_fifo_full_p    : OUT   STD_LOGIC;
    
    sd_write_address_p      : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);
    sd_read_address_p       : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);
    fc_fifo_tx_din_p        : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0);
    fc_fifo_tx_wr_en_p      : OUT   STD_LOGIC;
    fc_sd_read_cmd_p        : IN    STD_LOGIC;
    sd_sectors_written_p    : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);
    FC_SD_card_shutdown_p   : IN    STD_LOGIC;
    sd_format_button_p      : IN    STD_LOGIC;                      -- INPUT  -  1 bit  - This button needs to be pressed as the FPGA is booting up to enter formatting state   
    sd_card_format_led_1_p  : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - indicates that the SD Card is starting the formatting
    sd_card_format_led_2_p  : OUT   STD_LOGIC;
    SD_card_shutdown_ready_p: OUT   STD_LOGIC_VECTOR(1 DOWNTO 0);
    sd_read_fault_p         : OUT   STD_LOGIC;
    fc_mmap_sd_shutdown_cmd_p : IN  STD_LOGIC
    );
end SD_Card_interface_top;

ARCHITECTURE Behavioral OF SD_Card_interface_top IS


    COMPONENT fifo_sd_card_write
    PORT(
        clk         : IN    STD_LOGIC;    
        rst         : IN    STD_LOGIC;   
        din         : IN    STD_LOGIC_VECTOR( 7 DOWNTO 0);
        wr_en       : IN    STD_LOGIC;    
        rd_en       : IN    STD_LOGIC;
        dout        : OUT   STD_LOGIC_VECTOR( 7 DOWNTO 0);
        full        : OUT   STD_LOGIC;
--        almost_full : OUT   STD_LOGIC;
--        almost_empty: OUT   STD_LOGIC;
        empty       : OUT   STD_LOGIC
--        data_count  : OUT   STD_LOGIC_VECTOR(12 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT fifo_sd_card_read
    PORT(
        clk         : IN    STD_LOGIC;    
        rst         : IN    STD_LOGIC;    
        din         : IN    STD_LOGIC_VECTOR( 7 DOWNTO 0);
        wr_en       : IN    STD_LOGIC;    
        rd_en       : IN    STD_LOGIC;
        dout        : OUT   STD_LOGIC_VECTOR( 7 DOWNTO 0);
        full        : OUT   STD_LOGIC;
        almost_full : OUT   STD_LOGIC;
        almost_empty: OUT   STD_LOGIC;
        empty       : OUT   STD_LOGIC;
        data_count  : OUT   STD_LOGIC_VECTOR(12 DOWNTO 0)
        );
    END COMPONENT;
    
    --------------------------------------------------------------------------------------------------
    -- Signal declarations
    --------------------------------------------------------------------------------------------------
    
    -- Write FIFO signals
    SIGNAL  fifo_write_rd_en_s      : STD_LOGIC;
    SIGNAL  fifo_write_dout_s       : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL  fifo_write_almost_full_s: STD_LOGIC;
    SIGNAL  fifo_write_almost_empty_s: STD_LOGIC;
    SIGNAL  fifo_write_empty_s      : STD_LOGIC;
    SIGNAL  fifo_write_data_count_s : STD_LOGIC_VECTOR(12 DOWNTO 0);
    
    -- Read FIFO signals
    SIGNAL  fifo_read_din_s         : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL  fifo_read_wr_en_s      : STD_LOGIC;
    SIGNAL  fifo_read_rd_en_s      : STD_LOGIC;
    SIGNAL  fifo_read_dout_s       : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL  fifo_read_full_s       : STD_LOGIC;
    SIGNAL  fifo_read_almost_full_s: STD_LOGIC;
    SIGNAL  fifo_read_almost_empty_s: STD_LOGIC;
    SIGNAL  fifo_read_empty_s      : STD_LOGIC;
    SIGNAL  fifo_read_data_count_s : STD_LOGIC_VECTOR(12 DOWNTO 0)  := (OTHERS => '0');

    -- SPI Controller signals
    SIGNAL  FC_sd_read_complete_s   : STD_LOGIC;
    
BEGIN
    
    
    -- Output assignments
    
    
    -- This FIFO is used to buffer data from the detector before it can be be sent to the SD Card
    fifo_sd_card_write_inst : fifo_sd_card_write
    PORT MAP(
        clk                 => clk210_p,                        -- INPUT  -  1 bit  - 105 MHz clock
        rst                 => reset_p,                         -- INPUT  -  1 bit  - reset
        din                 => sd_write_fifo_din_p,             -- INPUT  -  8 bits - data input bus to the fifo
        wr_en               => sd_write_fifo_wr_en_p,           -- INPUT  -  1 bit  - Write enable to the fifo
        rd_en               => fifo_write_rd_en_s,              -- INPUT  -  1 bit  - read enable to the fifo
        dout                => fifo_write_dout_s,               -- OUTPUT -  8 bits - data output bus from the fifo
        full                => sd_write_fifo_full_p,            -- OUTPUT -  1 bit  - Full flag from the FIFO
        -- almost_full         => fifo_write_almost_full_s,        -- OUTPUT -  1 bit  - Almost full flag (triggers 1 byte before full)
        -- almost_empty        => fifo_write_almost_empty_s,       -- OUTPUT -  1 bit  - Almost empty flag (triggers with only 1 byte in the fifo)
        empty               => fifo_write_empty_s               -- OUTPUT -  1 bit  - Empty flag 
        -- data_count          => fifo_write_data_count_s          -- OUTPUT - 13 bits - Number of bytes in the fifo
        );
            
    -- This FIFO is used to buffer data from the SD Card before it can be sent to the Flight computer
    -- fifo_sd_card_read_inst : fifo_sd_card_read
    -- PORT MAP(
        -- clk                 => clk210_p,                        -- INPUT  -  1 bit  - 105 MHz clock
        -- rst                 => reset_p,                         -- INPUT  -  1 bit  - reset
        -- din                 => fifo_read_din_s,                 -- INPUT  -  8 bits - data input bus to the fifo
        -- wr_en               => fifo_read_wr_en_s,               -- INPUT  -  1 bit  - write enable to the fifo
        -- rd_en               => fifo_read_rd_en_s,               -- INPUT  -  1 bit  - read enable to the fifo
        -- dout                => fifo_read_dout_s,                -- OUTPUT -  8 bits - data output bus from the fifo
        -- full                => fifo_read_full_s,                -- OUTPUT -  1 bit  - Full flag from the FIFO
        -- almost_full         => fifo_read_almost_full_s,         -- OUTPUT -  1 bit  - Almost full flag (triggers 1 byte before full)
        -- almost_empty        => fifo_read_almost_empty_s,        -- OUTPUT -  1 bit  - Almost empty flag (triggers with only 1 byte in the fifo)
        -- empty               => fifo_read_empty_s,               -- OUTPUT -  1 bit  - Empty flag 
        -- data_count          => fifo_read_data_count_s           -- OUTPUT - 13 bits - Number of bytes in the fifo
        -- );
    
    -- initialization of the SD Card Controller
    SD_Card_SPI_controller_inst : ENTITY work.SD_Card_SPI_controller
    PORT MAP(
        clk210_p                => clk210_p,                    -- INPUT  -  1 bit  - 105 MHz
        reset_p                 => reset_p,                     -- INPUT  -  1 bit  - reset
        sd_spi_ss_p             => sd_spi_ss_p,                 -- OUTPUT -  1 bit  - slave select for the SD Card
        sd_spi_sck_p            => sd_spi_sck_p,                -- OUTPUT -  1 bit  - s clock for the SD Card
        sd_spi_mosi_p           => sd_spi_mosi_p,               -- OUTPUT -  1 bit  - Master Out Slave IN
        sd_spi_miso_p           => sd_spi_miso_p,               -- INPUT  -  1 bit  - Master In Slave Out
        sd_ccs_bit_p            => sd_ccs_bit_p,                -- OUTPUT -  1 bit  - CCS bit (tells the SD Card type)
        sd_spi_init_done_p      => sd_spi_init_done_p,          -- OUTPUT -  1 bit  - indicates that the SD Card is initialized
        sd_spi_transfer_done_p  => sd_spi_transfer_done_p,      -- OUTPUT -  1 bit  - indicates that the transfer is done
        sd_spi_cntrl_status_p   => sd_spi_cntrl_status_p,       -- OUTPUT - 16 bits - control status
        sd_write_address_p      => sd_write_address_p,
        fifo_write_rd_en_p      => fifo_write_rd_en_s,          -- OUTPUT -  1 bit  - read enable to the "write" FIFO
        fifo_write_dout_p       => fifo_write_dout_s,           -- INPUT  -  8 bits - data out from the "write" FIFO
        fifo_write_data_count_p => fifo_write_data_count_s,     -- INPUT  - 13 bits - Number of bytes in the "write" FIFO
        fc_fifo_tx_din_p        => fc_fifo_tx_din_p,             -- OUTPUT - 16 bit  - data into the "read" FIFO
        fc_fifo_tx_wr_en_p      => fc_fifo_tx_wr_en_p,           -- OUTPUT -  1 bit  - write enable to the "read" FIFO
        fc_sd_read_cmd_p        => fc_sd_read_cmd_p,
        sd_sectors_written_p    => sd_sectors_written_p,
        sd_read_fault_p         => sd_read_fault_p,
        fc_sd_shutdown_cmd_p    => FC_SD_card_shutdown_p,
        SD_card_shutdown_ready_p=> SD_card_shutdown_ready_p,
        sd_format_button_p      => sd_format_button_p,
        sd_card_format_led_1_p  => sd_card_format_led_1_p,
        sd_card_format_led_2_p  => sd_card_format_led_2_p
        );
    
    
    -- data count
    WRITE_FIFO_DAT_COUNT_PROC:
    PROCESS (clk210_p, reset_p) BEGIN
    
        IF (reset_p = '1') THEN
            fifo_write_data_count_s     <= (OTHERS => '0');
            
        ELSIF RISING_EDGE (clk210_p) THEN
        
            IF (sd_write_fifo_wr_en_p = '1') THEN
                fifo_write_data_count_s <= fifo_write_data_count_s + '1';
            ELSIF (fifo_write_rd_en_s = '1') THEN
                fifo_write_data_count_s <= fifo_write_data_count_s - '1';
            END IF;
            
        END IF;
        
    END PROCESS;
    
    
    
    
    

END Behavioral;

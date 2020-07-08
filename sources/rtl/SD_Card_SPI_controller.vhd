----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/17/2017 05:33:17 PM
-- Design Name: 
-- Module Name: SD_Card_SPI_controller - Behavioral
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
use ieee.std_logic_unsigned.all;

LIBRARY work;
USE work.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY SD_Card_SPI_controller IS
 PORT (
    clk210_p                : IN    STD_LOGIC;                      -- INPUT  -  1 bit  - 105 MHz clock
    reset_p                 : IN    STD_LOGIC;                      -- INPUT  -  1 bit  - reset        
    sd_spi_ss_p             : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - slave select for the SD Card
    sd_spi_sck_p            : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - SCK for the SD Card
    sd_spi_mosi_p           : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - MOSI for the SD Card
    sd_spi_miso_p           : IN    STD_LOGIC;                      -- INPUT  -  1 bit  - MISO for the SD Card
    sd_ccs_bit_p            : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - CCS bit that is read from the SD Card. 1 indicates that it is SDHC or SDXC. 0 indicates it is simply an SD
    sd_spi_init_done_p      : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - indicates that the SD Card is initialized
    sd_spi_transfer_done_p  : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - 
    sd_spi_cntrl_status_p   : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0);
    sd_write_address_p      : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);
    fifo_write_rd_en_p      : OUT   STD_LOGIC;
    fifo_write_dout_p       : IN    STD_LOGIC_VECTOR( 7 DOWNTO 0);
    fifo_write_data_count_p : IN    STD_LOGIC_VECTOR(12 DOWNTO 0);
	fc_sd_shutdown_cmd_p	: IN	STD_LOGIC;						-- INPUT  -  1 bit  - indicates signal from flight computer telling to save pointers and shut down
    fc_sd_read_cmd_p        : IN    STD_LOGIC;
    fc_fifo_tx_din_p        : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0);
    fc_fifo_tx_wr_en_p      : OUT   STD_LOGIC;
    sd_sectors_written_p    : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);
    SD_card_shutdown_ready_p: OUT   STD_LOGIC_VECTOR(1 DOWNTO 0);u
    sd_read_fault_p         : OUT   STD_LOGIC;
    sd_format_button_p      : IN    STD_LOGIC;                      -- INPUT  -  1 bit  - This button needs to be pressed as the FPGA is booting up to enter formatting state   
    sd_card_format_led_1_p  : OUT   STD_LOGIC;                      -- OUTPUT -  1 bit  - indicates that the SD Card is starting the formatting
    sd_card_format_led_2_p  : OUT   STD_LOGIC                       -- OUTPUT -  1 bit  - indicates that the SD Card is done formatting
 );
END SD_Card_SPI_controller;

ARCHITECTURE BEHAVIORAL OF SD_Card_SPI_controller IS

    TYPE sd_spi_init_state_type IS(
        IDLE_st,                            --0
        WAIT_FOR_5ms_st,                    --1
        INIT_st,                            --2
        CMD0_st,                            --3
        CMD8_st,                            --4
        CMD55_st,                           --5
        ACMD41_st,                          --6
        CMD58_st,                           --7
        SEND_COMMAND_st,                    --8
        RESPONSE_WAIT_st,                   --9
        RESPONSE_1_st,                      --10
        RESPONSE_1_sslow_st,                --11
        RESPONSE_2_st,                      --12
        RESPONSE_3_st,                      --13
        RESPONSE_7_st,                      --14
        INIT_WAIT_FOR_TRANS_END_st,         --15
        DONE_INIT_st,                       --16
        READ_FIRST_SECTOR_st,               --17
        WAIT_FOR_START_TOKEN_st,            --18
        READ_START_WR_ADDRESS_st,           --19
        STORE_WR_ADDRESS_st,                --20
        READ_START_RD_ADDRESS_st,           --21
        STORE_RD_ADDRESS_st,                --22
        READ_REMAINING_BYTES_s,             --23
        WAIT_FOR_READ_OR_WRITE_st,          --24
        CMD24_st,                           --25
        TRANSFER_DATA_st,                   --26
        PULL_DOWN_RD_EN_st,                 --27
        CHECK_FOR_SD_DONE_st,               --28
        GET_1_BYTE_FROM_FIFO_st,            --29
        WAIT_FOR_SD_READY_st,               --30
        READ_st,                            --31  
        WAIT_FOR_START_TOKEN_N_READ_st,     --32    -- note that this state essentially does the same task at WAIT_FOR_START_TOKEN_st but this is for general reads
        READ_DATA_st,                       --33
        PULL_UP_WR_EN_st,                   --34
        WRITE_TO_FC_TX_FIFO_st,             --35
        TRANSFER_DONE_st,                   --36
        CMD13_st,                           --37
        ENTER_FORMAT_st,                    --38
        FORMAT_SECTORS_st,                  --39
        WRITE_FORMAT_DATA_st,               --40
        FORMAT_CHECK_FOR_SD_DONE_st,        --41
        FORMAT_WAIT_FOR_SD_READY_st,        --42
        DONE_FORMATTING_st,                 --43
        SHUTDOWN_PREP_st,                   --44
        NULL_st                             --45
    );

    -- commented this section to avoid confusion; apparently this is not used anywhere
    -- TYPE sd_spi_cntrl_state_type IS(
        -- WAIT_FOR_INITIALIZATION_st,
        -- IDLE_CNTRL_st,
        -- READ_DATA_st,
        -- WRITE_DATA_st,
        -- SEND_COMMAND_st,
        -- CNTRL_WAIT_FOR_TRANS_END_st    
    -- );
    
    
    SIGNAL      sd_spi_htransfer_in_s       : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL      sd_spi_htransfer_out_s      : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL      sd_spi_init_state_s         : sd_spi_init_state_type;
    SIGNAL      sd_spi_init_last_state_s    : sd_spi_init_state_type;    
    SIGNAL      sd_spi_init_next_cmd_s      : sd_spi_init_state_type;    
    SIGNAL      sd_spi_init_rtrn_cmd_s      : sd_spi_init_state_type;   
    SIGNAL      sd_spi_init_trans_s         : STD_LOGIC;    
    SIGNAL      sd_spi_init_wait_cntr_s     : INTEGER RANGE 0 TO 25000000;
    SIGNAL      sd_spi_byte_tfers_s         : INTEGER RANGE 0 TO 16;
    SIGNAL      sd_spi_response_type_s      : INTEGER RANGE 0 TO 16;
    SIGNAL      sd_spi_expected_resp_s      : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL      sd_spi_ss_s                 : STD_LOGIC;
    SIGNAL      sd_spi_select_speed_s       : STD_LOGIC;    
    SIGNAL      sd_spi_command_frame_s      : STD_LOGIC_VECTOR(55 DOWNTO 0);    
    SIGNAL      response_3_s                : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL      response_2_s                : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL      response_7_s                : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL      sd_ccs_bit_s                : STD_LOGIC;
    SIGNAL      sd_spi_byte_done_s          : STD_LOGIC;
    SIGNAL      sd_spi_init_done_s          : STD_LOGIC;
    SIGNAL      sd_spi_normal_baud_s        : STD_LOGIC;
    SIGNAL      sd_spi_init_baud_s          : STD_LOGIC;
    SIGNAL      sd_spi_transfer_done_s      : STD_LOGIC;
    SIGNAL      random_data_s               : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL      sd_transfer_status_s        : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL      sd_write_address_s          : STD_LOGIC_VECTOR(31 DOWNTO 0); 
	SIGNAL		sd_write_address_save_s		: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL      sd_read_address_s           : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL      fifo_write_rd_en_s          : STD_LOGIC;    
    SIGNAL      fc_fifo_tx_din_s            : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL      fc_fifo_tx_wr_en_s          : STD_LOGIC;    
    SIGNAL      sd_sectors_written_s        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL      sd_read_fault_s             : STD_LOGIC;
    
    -- SIGNAL      sd_spi_cntrl_state_s        : sd_spi_cntrl_state_type;    
    SIGNAL      sd_spi_byte_writes_s        : INTEGER RANGE 0 TO 1000;
    SIGNAL      sd_spi_byte_reads_s         : INTEGER RANGE 0 TO 1000;
    -- SIGNAL      sd_spi_cntrl_init_trans_s   : STD_LOGIC;    
    SIGNAL      sd_debugging_signal_s       : STD_LOGIC_VECTOR( 3 DOWNTO 0);
    
    CONSTANT    DEBUGGING_MODE_c            : INTEGER := 0;                         -- enable this (1) to enable debugging mode.
    
    -- CONSTANT    INIT_WAIT_COUNTER_c         : INTEGER := 24000000;                  -- around 5 ms wait time (24_000_000) type in 100 for simulation.
    CONSTANT    INIT_WAIT_COUNTER_c         : INTEGER := 100;                  -- around 5 ms wait time (24_000_000) type in 100 for simulation.
    CONSTANT    DUMMY_CYCLE_COUNT_c         : INTEGER := 10;
    CONSTANT    COMMAND_FRAME_COUNT_c       : INTEGER := 7;
    CONSTANT    RESPONSE_7_BYTE_COUNT_c     : INTEGER := 5;
    CONSTANT    RESPONSE_3_BYTE_COUNT_c     : INTEGER := 5;
    CONSTANT    SD_CARD_MAX_ADDRESS_c       : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"01DACBFF"; -- 31116287 sectors for a 16 GB card
    CONSTANT    SD_START_ADDRESS_c          : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000001"; -- Start Address
    CONSTANT    SD_CARD_FORMAT_SECTORS_MAX_c: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"000061AB";
    -------------------------------------------------------------------------//
    -- Parameter list for the command frames
    -- A Command frame is a composition of 6 bytes of data
    -- BYTE     1    --> 8'b01xx_xxxx        (the x's make the INDEX number 'n' in CMD'n')
    -- BYTES    2-5  --> Argument. This can be an address or just 0's if its
    --                             not a data transfer
    -- BYTE     6    --> CRC       (Clock Redundany Check) See the decription
    --                              above in the module for where to find information
    --                              on CRC. In short, its not used in this current
    --                              design except for the reset (CMD0) command
    --                              and the check voltage range command (CMD8) (pg 230)
    --                                             BYTE:  1  2  3  4  5  6
    --                                                 INDEX| ARGUMENT  |CRC 
                                                                            -- Note that there is an FF in front of all the commands. This is because I found a post suggesting that
                                                                            -- the SD Card should receive 1 byte of raw clocks without the CS being lowered.
                                                                            -- https://electronics.stackexchange.com/questions/303745/sd-card-initialization-problem-cmd8-wrong-response/303768
                                                                            -- Also see: http://stevenmerrifield.com/tools/sd.vhd 
    CONSTANT    CMD0_FRAME_c                : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF400000000095";       -- This is a reset command. It is used to change from SD mode to SPI mode
    CONSTANT    CMD1_FRAME_c                : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF410000000000";       -- 
    CONSTANT    CMD8_FRAME_c                : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF48000001AA87";       -- Table 4-18 page 92 (01 --> voltage range is 2.7V t0 3.6V)
    CONSTANT    CMD55_FRAME_c               : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF770000000001";       --
    CONSTANT    ACMD41_FRAME_c              : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF694000000000";       -- Index -> (101001) Bit 30 in argument (bit 38 in frame) -> HCS. HCS is set to 1 for SDHC cards
    CONSTANT    CMD58_FRAME_c               : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF7A0000000000";       -- no argument
    CONSTANT    CMD24_FRAME_c               : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"FF58";                 -- write command
    CONSTANT    CMD17_FRAME_c               : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"FF51";                 -- read command
    CONSTANT    CMD13_FRAME_c               : STD_LOGIC_VECTOR(55 DOWNTO 0) := x"FF4D0000000000";       -- cmd 13   
                                                                                                        
    CONSTANT    R1_CMD0_c                   : STD_LOGIC_VECTOR( 7 DOWNTO 0) := x"01";                   
    CONSTANT    R7_CMD8_c                   : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"1AA";                  -- we don't care about the first 5 nibbles. Just need to see the echo
    CONSTANT    R1_CMD55_c                  : STD_LOGIC_VECTOR( 7 DOWNTO 0) := x"01";
    CONSTANT    R1_ACMD41_c                 : STD_LOGIC_VECTOR( 7 DOWNTO 0) := x"00";
    CONSTANT    R1_CMD24_c                  : STD_LOGIC_VECTOR( 7 DOWNTO 0) := x"00";                   -- need to change this
    CONSTANT    R1_CMD17_c                  : STD_LOGIC_VECTOR( 7 DOWNTO 0) := x"00";                   -- need to change this
    CONSTANT    R1_TRANSFER_DAT_c           : STD_LOGIC_VECTOR( 7 DOWNTO 0) := x"00";
    
    attribute mark_debug    : string;
    attribute keep          : string;
    attribute mark_debug of sd_spi_init_state_s     : signal is "true";
    attribute mark_debug of sd_spi_init_last_state_s: signal is "true";
    attribute mark_debug of sd_spi_init_next_cmd_s  : signal is "true";
    attribute mark_debug of sd_spi_htransfer_in_s   : signal is "true";
    attribute mark_debug of sd_spi_htransfer_out_s  : signal is "true";
    attribute mark_debug of sd_spi_init_rtrn_cmd_s  : signal is "true";
    attribute mark_debug of sd_spi_ss_s             : signal is "true";
    attribute mark_debug of sd_spi_byte_writes_s    : signal is "true";
    attribute mark_debug of sd_spi_byte_reads_s     : signal is "true";
    attribute mark_debug of sd_write_address_s      : signal is "true";
    attribute mark_debug of sd_spi_byte_tfers_s     : signal is "true";
    attribute mark_debug of fifo_write_data_count_p : signal is "true";
    attribute mark_debug of sd_read_address_s       : signal is "true";
    attribute mark_debug of sd_debugging_signal_s   : signal is "true";
    -- attribute mark_debug of random_data_s           : signal is "true";
    
BEGIN

    -- output assignments
    sd_spi_ss_p         <= sd_spi_ss_s;
    sd_ccs_bit_p        <= sd_ccs_bit_s;
    sd_spi_init_done_p  <= sd_spi_init_done_s;     
    sd_spi_transfer_done_p  <= sd_spi_transfer_done_s;
    sd_spi_cntrl_status_p   <= response_2_s;
    fifo_write_rd_en_p  <= fifo_write_rd_en_s;
    fc_fifo_tx_din_p    <= fc_fifo_tx_din_s;
    fc_fifo_tx_wr_en_p  <= fc_fifo_tx_wr_en_s;    
    sd_sectors_written_p<= sd_sectors_written_s;    
    sd_read_fault_p     <= sd_read_fault_s;
    sd_write_address_p  <= sd_write_address_s;
    
    SPI_Byte_Transfer : ENTITY work.SD_Card_SPI_Byte_Transfer 
    PORT MAP(
        clk210_p                => clk210_p,                    -- INPUT  -  1 bit  - 210 MHz clock
        reset_p                 => reset_p,                     -- INPUT  -  1 bit  - reset
        sd_spi_mosi_p           => sd_spi_mosi_p,               -- OUTPUT -  1 bit  - MOSI
        sd_spi_miso_p           => sd_spi_miso_p,               -- INPUT  -  1 bit  - MISO
        sd_spi_sck_p            => sd_spi_sck_p,                -- OUTPUT -  1 bit  - SCK
        sd_spi_ltransfer_in_p   => sd_spi_htransfer_in_s,       -- OUTPUT -  8 bits - data that is received from the SD Card
        sd_spi_ltransfer_out_p  => sd_spi_htransfer_out_s,      -- INPUT  -  8 bits - data that is to be transfered to the SD Card
        sd_spi_init_trans_p     => sd_spi_init_trans_s,         -- INPUT  -  1 bit  - signal to start transfers
        sd_spi_byte_done_p      => sd_spi_byte_done_s,          -- OUTPUT -  1 bit  - signal that indicates that the byte transfer was complete
        sd_spi_select_speed_p   => sd_spi_select_speed_s,       -- INPUT  -  1 bit  - select speed (0 -> INIT Baud, 1 -> Normal Baud)
        sd_spi_normal_baud_p    => sd_spi_normal_baud_s,        -- INPUT  -  1 bit  - normal baud ticks    
        sd_spi_init_baud_p      => sd_spi_init_baud_s           -- INPUT  -  1 bit  - init baud ticks
    );
    
    SD_Card_SPI_baud_gen_inst : ENTITY work.SD_Card_SPI_baud_gen 
    GENERIC MAP(
        INIT_BAUD_CLKDIV_c      => 6,    --525
        NORMAL_BAUD_CLK_DIV_c   => 6       --6
        )
    PORT MAP(
        clk210_p                => clk210_p,                    -- INPUT  -  1 bit  - 210 MHz clock 
        reset_p                 => reset_p,                     -- INPUT  -  1 bit  - reset
        sd_spi_normal_baud_p    => sd_spi_normal_baud_s,        -- OUTPUT -  1 bit  - normal baud ticks        
        sd_spi_init_baud_p      => sd_spi_init_baud_s           -- OUTPUT -  1 bit  - init baud ticks
    );
    
--------------------------------------------------------------------------------------------------------------------------
-- This State Machine is the real operation which will be used in the final version. The State Machine after this one 
-- is used for debugging.
-- Following is a description of the state machine.    
--------------------------------------------------------------------------------------------------------------------------    
        
REAL_OPERATION: IF (DEBUGGING_MODE_c = 0) GENERATE
    
    INITIALIZATION_AND_CONTROL_SM:
    PROCESS (clk210_p, reset_p) BEGIN
    
        IF reset_p = '1' THEN
            sd_spi_init_state_s             <= IDLE_st;
            sd_spi_init_wait_cntr_s         <= 0;
            sd_spi_init_next_cmd_s          <= IDLE_st;
            sd_spi_init_rtrn_cmd_s          <= IDLE_st;
            sd_spi_init_last_state_s        <= IDLE_st;
            sd_spi_select_speed_s           <= '0';
            sd_spi_command_frame_s          <= (OTHERS => '0');
            sd_spi_htransfer_out_s          <= (OTHERS => '1');
            sd_spi_init_done_s              <= '0';
            response_3_s                    <= (OTHERS => '0');
            response_7_s                    <= (OTHERS => '0');
            sd_transfer_status_s            <= (OTHERS => '0');
            sd_spi_byte_writes_s            <= 0;
            sd_spi_byte_reads_s             <= 0;
            sd_write_address_s              <= (OTHERS => '0');
            fifo_write_rd_en_s              <= '0';
            fc_fifo_tx_wr_en_s              <= '0';
            fc_fifo_tx_din_s                <= (OTHERS => '0');    
            sd_sectors_written_s            <= (OTHERS => '0');
            sd_read_fault_s                 <= '0';
            sd_spi_ss_s                     <= '1';
            SD_card_shutdown_ready_p        <= b"00";    
            sd_card_format_led_1_p          <= '0';
            sd_card_format_led_2_p          <= '0';

        ELSIF RISING_EDGE (clk210_p) THEN
            
            CASE(sd_spi_init_state_s) IS
            
            -- This state is where all the defaults are set. 
            WHEN IDLE_st =>
                sd_spi_init_wait_cntr_s         <= 0;
                sd_spi_init_state_s             <= WAIT_FOR_5ms_st;
                sd_spi_init_next_cmd_s          <= IDLE_st;
                sd_spi_init_rtrn_cmd_s          <= IDLE_st;
                sd_spi_init_last_state_s        <= IDLE_st;
                sd_spi_select_speed_s           <= '0';
                sd_spi_init_done_s              <= '0';
                sd_spi_command_frame_s          <= (OTHERS => '0');
                sd_spi_htransfer_out_s          <= (OTHERS => '1');
                sd_spi_transfer_done_s          <= '0';
                SD_card_shutdown_ready_p        <= b"00";
                random_data_s                   <= (OTHERS => '0');
                sd_card_format_led_1_p          <= '0';
                sd_card_format_led_2_p          <= '0';

            -- It is recommended to wait for 1 millisecond after power up to allow the SD Card
            -- to achieve a stable voltage. Here, we use 5ms just to be safe.
            WHEN WAIT_FOR_5ms_st =>
                IF (sd_spi_init_wait_cntr_s = INIT_WAIT_COUNTER_c) THEN
                    sd_spi_init_state_s         <= INIT_st;
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_select_speed_s       <= '0';
                    sd_spi_init_wait_cntr_s     <= 0;
                ELSE 
                    sd_spi_init_wait_cntr_s     <= sd_spi_init_wait_cntr_s + 1;
                END IF;
            
            -- it is expected that the SD card receives atleast 74 cycles of dummy bits
            -- This allows it to perform some initializations
            WHEN INIT_st =>
                IF (sd_spi_byte_tfers_s = DUMMY_CYCLE_COUNT_c) THEN
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_init_state_s         <= CMD0_st;
                    sd_spi_command_frame_s      <= CMD0_FRAME_c;
                ELSE
                    SD_card_shutdown_ready_p    <= b"00";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_ss_s                 <= '1';
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st; 
                    sd_spi_init_last_state_s    <= INIT_st;
                END IF;
            
            -- send out command CMD0. This sets the SD card to SPI mode
            WHEN CMD0_st =>
                sd_spi_command_frame_s          <= CMD0_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= CMD8_st;
                sd_spi_init_rtrn_cmd_s          <= CMD0_st;
                sd_spi_response_type_s          <= 1;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD0_c;
            
            -- it is mandatory to send CMD8 before ACMD41. CMD8 verifies the operating voltage ranges
            WHEN CMD8_st =>
                sd_spi_command_frame_s          <= CMD8_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= CMD55_st;
                sd_spi_init_rtrn_cmd_s          <= CMD8_st;
                sd_spi_response_type_s          <= 7;
                sd_spi_expected_resp_s(11 DOWNTO 0) <= R7_CMD8_c;
                
            -- CMD 55 needs to be sent before ACMD41 can be sent. CMD55 is sent before any ACMD is sent
            WHEN CMD55_st =>
                sd_spi_command_frame_s          <= CMD55_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= ACMD41_st;
                sd_spi_init_rtrn_cmd_s          <= CMD55_st;
                sd_spi_response_type_s          <= 1;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD55_c;                

            -- send out ACMD41_FRAME_c. ACMD41 is used to initiate the initialization process.
            WHEN ACMD41_st =>
                sd_spi_command_frame_s          <= ACMD41_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= CMD58_st;
                sd_spi_init_rtrn_cmd_s          <= CMD55_st;
                sd_spi_response_type_s          <= 1;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_ACMD41_c;        
                
            -- This is used to read the OCR register for the CCS bit. Not really any useful information
            -- but this command is included because the SD Spec has included it in its initialization
            -- flow chart.
            WHEN CMD58_st =>    
                sd_spi_command_frame_s          <= CMD58_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= DONE_INIT_st;
                sd_spi_init_rtrn_cmd_s          <= DONE_INIT_st;
                sd_spi_response_type_s          <= 3;
                -- sd_spi_expected_resp_s          <= R3_CMD58_c;
            
            -- Initialization is done. This will allow the next state machine to start receiving data from
            -- the detector top and have it be stored.
            WHEN DONE_INIT_st =>
                
                IF (sd_format_button_p = '1') THEN                      -- This check is done only in this state.
                    sd_spi_init_state_s         <= ENTER_FORMAT_st;     -- When the button is pressed as soon as the FPGA 
                    sd_spi_init_done_s          <= '1';                 -- finishes initializing the SD Card, we go into the 
                    sd_spi_select_speed_s       <= '1';                 -- FORMATTING state. This mode only formats the SD Card
                    sd_read_address_s           <= x"00000000";         -- and won't do anything else after. So, the FPGA will
                                                                        -- need to be re-booted for the operations to happen as
                                                                        -- expected.
                    sd_card_format_led_1_p      <= '1';                 -- light up an LED to indicate that we are entering format state
                    sd_write_address_s          <= x"00000001";         -- start with sector 1
                ELSE                                                    -- If the format button option is not pressed, we 
                    sd_spi_init_state_s         <= READ_FIRST_SECTOR_st;-- shall go into the "normal" operation.
                    sd_spi_init_done_s          <= '1';
                    sd_spi_select_speed_s       <= '1';
                    sd_read_address_s           <= x"00000000";
                END IF;
            
            --------------------------------------------------------------------------------------------------
            ------------------------------- FORMAT OPERATION -------------------------------------------------
            --------------------------------------------------------------------------------------------------
            WHEN ENTER_FORMAT_st =>
                sd_spi_command_frame_s          <= CMD24_FRAME_c & sd_write_address_s & x"00";
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= FORMAT_SECTORS_st;
                sd_spi_init_rtrn_cmd_s          <= CMD24_st;
                sd_spi_response_type_s          <= 11;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD24_c;
                sd_spi_byte_tfers_s             <= 0;
                
            WHEN FORMAT_SECTORS_st =>
                IF (sd_spi_byte_writes_s = 0 OR sd_spi_byte_writes_s = 1) THEN          -- The first two bytes are just x"FF" with the slave select not pulled low.  
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- This is to allow the SD Card to finish anything that it needs to do.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= FORMAT_SECTORS_st;
                ELSIF (sd_spi_byte_writes_s = 2) THEN                                   -- This is the token (x"FE) that needs to be sent before data can be transfered
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FE";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= FORMAT_SECTORS_st;
                ELSIF (sd_spi_byte_writes_s = 515 OR sd_spi_byte_writes_s = 516) THEN   -- Two byes for CRC is allocated here. Since, CRC is disabled, we just send out x"FF"
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- for both the bytes.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= FORMAT_SECTORS_st;
                ELSIF (sd_spi_byte_writes_s > 516) THEN                                 -- After sending the data, the SD Card sends a response of 1 byte.
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- The response is of the form "xxx0ABC1"
                                                                                        -- ABC can be of three different types:
                                                                                        -- 010 -> Data accepted    
                                                                                        -- 101 -> Data rejected due to a CRC error
                                                                                        -- 110 -> Data rejected due to a write error
                    sd_spi_init_state_s         <= FORMAT_CHECK_FOR_SD_DONE_st;                                                                
                ELSE
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            
                    fifo_write_rd_en_s          <= '1';                             -- Pull up read enable for 1 clock cycle
                    sd_spi_init_state_s         <= WRITE_FORMAT_DATA_st;
                END IF;

            WHEN WRITE_FORMAT_DATA_st =>
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= x"00";                               -- write zeros
                    sd_spi_init_trans_s         <= '1';
                    fifo_write_rd_en_s          <= '0';
                    sd_spi_init_last_state_s    <= FORMAT_SECTORS_st;

            WHEN FORMAT_CHECK_FOR_SD_DONE_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN                       
                    sd_spi_init_last_state_s    <= FORMAT_SECTORS_st;          
                    sd_spi_init_trans_s         <= '1';                       
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                ELSE 
                    sd_spi_init_state_s         <= FORMAT_WAIT_FOR_SD_READY_st;
                    sd_spi_ss_s                 <= '0';
                    sd_transfer_status_s        <= sd_spi_htransfer_in_s;
                    sd_spi_byte_writes_s        <= 0;
                END IF;

            -- After a write, the SD Card takes a while to finish all the things that it needs to. While this is happening,
            -- the MISO is low and SCK needs to be sent to the card as long as this is the case. When we see that MISO is high,
            -- we know that the SD Card is done doing its thing and is available for other tasks. 
            WHEN FORMAT_WAIT_FOR_SD_READY_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN
                    IF (sd_write_address_s = SD_CARD_FORMAT_SECTORS_MAX_c) THEN
                        sd_spi_init_state_s     <= DONE_FORMATTING_st;
                    ELSE
                        sd_spi_init_state_s     <= ENTER_FORMAT_st;
                        sd_write_address_s      <= sd_write_address_s + '1';
                        sd_spi_byte_tfers_s     <= 0;
                        sd_spi_ss_s             <= '1';
                    END IF;
                ELSE 
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= FORMAT_WAIT_FOR_SD_READY_st;
                END IF;

            -- we are done formatting and we shall stay in this state forever untill a power cycle
            WHEN DONE_FORMATTING_st =>
                    sd_card_format_led_2_p      <= '1';
                    sd_spi_init_state_s         <= DONE_FORMATTING_st;

            --------------------------------------------------------------------------------------------------
            ------------------------------- NORMAL OPERATION -------------------------------------------------
            --------------------------------------------------------------------------------------------------
            -- Here, the controller goes into the first sector and reads it out to know where it last left off
            -- The last written address is stored here. -- we should include a last read address as well next
            WHEN READ_FIRST_SECTOR_st =>
                sd_spi_command_frame_s          <= CMD17_FRAME_c & sd_read_address_s & x"00";
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= WAIT_FOR_START_TOKEN_st;
                sd_spi_init_rtrn_cmd_s          <= READ_FIRST_SECTOR_st;
                sd_spi_response_type_s          <= 11;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD17_c;
                sd_spi_byte_tfers_s             <= 0;
                
            WHEN WAIT_FOR_START_TOKEN_st =>
                IF (sd_spi_htransfer_in_s = x"FE") THEN
                    sd_spi_init_state_s         <= READ_START_WR_ADDRESS_st;
                    sd_spi_byte_reads_s         <= 0;
                ELSE
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= WAIT_FOR_START_TOKEN_st;
                END IF;
                
            WHEN READ_START_WR_ADDRESS_st =>
                IF (sd_spi_byte_reads_s = 4) THEN
                    sd_spi_init_state_s         <= READ_START_RD_ADDRESS_st;                   
                ELSE 
                    sd_spi_byte_reads_s         <= sd_spi_byte_reads_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= STORE_WR_ADDRESS_st;
                END IF;
                
            WHEN STORE_WR_ADDRESS_st =>
                sd_write_address_s              <= sd_write_address_s(23 DOWNTO 0) & sd_spi_htransfer_in_s;
                sd_spi_init_state_s             <= READ_START_WR_ADDRESS_st;
                
            WHEN READ_START_RD_ADDRESS_st =>
                     IF (sd_spi_byte_reads_s = 8) THEN
                         sd_spi_init_state_s         <= READ_REMAINING_BYTES_s;                   
                     ELSE 
                         sd_spi_byte_reads_s         <= sd_spi_byte_reads_s + 1;
                         sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                         sd_spi_htransfer_out_s      <= x"FF";
                         sd_spi_init_trans_s         <= '1';
                         sd_spi_init_last_state_s    <= STORE_RD_ADDRESS_st;
                     END IF;
                     
                 WHEN STORE_RD_ADDRESS_st =>
                     sd_read_address_s              <= sd_read_address_s(23 DOWNTO 0) & sd_spi_htransfer_in_s;
                     sd_spi_init_state_s             <= READ_START_RD_ADDRESS_st;
                
            WHEN READ_REMAINING_BYTES_s =>
                IF (sd_spi_byte_reads_s = 514) THEN     -- 512 because there are 2 CRC bytes as well
                    sd_spi_byte_reads_s         <= 0;
                    sd_spi_ss_s                 <= '1';
                    sd_spi_init_state_s         <= WAIT_FOR_READ_OR_WRITE_st;
                    sd_read_address_s           <= sd_write_address_s;      -- initialize the read address to the starting write address.
                ELSE
                    sd_spi_byte_reads_s         <= sd_spi_byte_reads_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= READ_REMAINING_BYTES_s;
                END IF;
                
            -- Here you wait for two conditons:
            -- 1. The Flight Computer requests us for data.
            -- 2. Wait for the Detector Interface to fill up our TX (Write) FIFO
            --      beyond 512 bytes. When this happens, read 512 bytes and write to 
            --      the SD Card          
            -- Note that here, we give preference to the Flight Computer to READ_st
            -- from the SD Card. This is because we want to make sure that the SD Card 
            -- does not keep getting filled up.
            -- The downside to this is that we will need to have a large enough FIFO on board
            -- to make sure that we don't overflow it before a read from the FC is over.
            WHEN WAIT_FOR_READ_OR_WRITE_st =>
				IF (fc_sd_shutdown_cmd_p = '1') THEN
						sd_spi_init_state_s 	<= CMD24_st;
						sd_spi_init_next_cmd_s	<= SHUTDOWN_PREP_st;
                        SD_card_shutdown_ready_p<= b"01";
						sd_write_address_save_s <= sd_write_address_s;
						sd_write_address_s 		<= x"00000000";
                ELSIF (fc_sd_read_cmd_p = '1') THEN                            
                    IF ((sd_read_address_s /= SD_CARD_MAX_ADDRESS_c) AND (sd_sectors_written_s /= 0)) THEN
                        sd_spi_init_state_s     <= READ_st;
						sd_spi_init_next_cmd_s  <= TRANSFER_DATA_st;
                        sd_read_address_s       <= sd_read_address_s + '1';
                        sd_spi_byte_reads_s     <= 0;
                        sd_read_fault_s         <= '0';
                        sd_debugging_signal_s   <= x"1";
                    ELSIF ((sd_read_address_s = SD_CARD_MAX_ADDRESS_c) AND (sd_sectors_written_s /= 0)) THEN
                        sd_spi_init_state_s     <= READ_st;
						sd_spi_init_next_cmd_s  <= TRANSFER_DATA_st;
                        sd_read_address_s       <= x"00000001";
                        sd_spi_byte_reads_s     <= 0;     
                        sd_read_fault_s         <= '0';
                        sd_debugging_signal_s   <= x"2";
                    ELSE
                        sd_spi_init_state_s     <= WAIT_FOR_READ_OR_WRITE_st;
						sd_spi_init_next_cmd_s  <= TRANSFER_DATA_st;
                        sd_spi_byte_reads_s     <= 0;  
                        sd_read_fault_s         <= '1';
                        sd_debugging_signal_s   <= x"3";
                    END IF;
                ELSIF (fifo_write_data_count_p > 512) THEN
                    IF ((sd_write_address_s /= SD_CARD_MAX_ADDRESS_c) AND (sd_sectors_written_s /= SD_CARD_MAX_ADDRESS_c)) THEN
                        sd_spi_init_state_s     <= CMD24_st;                -- move to the write command
						sd_spi_init_next_cmd_s  <= TRANSFER_DATA_st;
                        sd_write_address_s      <= sd_write_address_s + '1';-- increment the write address by 1
                        sd_sectors_written_s    <= sd_sectors_written_s + '1';
                        sd_debugging_signal_s   <= x"4";
                    ELSIF ((sd_write_address_s = SD_CARD_MAX_ADDRESS_c) AND (sd_sectors_written_s /= SD_CARD_MAX_ADDRESS_c)) THEN
                        sd_write_address_s      <= x"00000001";
                        sd_sectors_written_s    <= sd_sectors_written_s + '1';
                        sd_spi_init_state_s     <= CMD24_st;
						sd_spi_init_next_cmd_s  <= TRANSFER_DATA_st;
                        sd_debugging_signal_s   <= x"5";    
                    ELSE
                        sd_spi_init_state_s     <= WAIT_FOR_READ_OR_WRITE_st;
                        sd_debugging_signal_s   <= x"6";
                    END IF;
                ELSE 
                    sd_spi_init_state_s         <= WAIT_FOR_READ_OR_WRITE_st;
                    sd_debugging_signal_s       <= x"7";
                END IF;
				
                
            
            -- CMD 24 is used to transfer a block of 512 bytes of data. 
            WHEN CMD24_st =>
                sd_spi_command_frame_s          <= CMD24_FRAME_c & sd_write_address_s & x"00";
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                -- sd_spi_init_next_cmd_s          <= TRANSFER_DATA_st;
                sd_spi_init_rtrn_cmd_s          <= CMD24_st;
                sd_spi_response_type_s          <= 11;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD24_c;
                sd_spi_byte_tfers_s             <= 0;
				
				
			WHEN SHUTDOWN_PREP_st =>
				IF (sd_spi_byte_writes_s = 0 OR sd_spi_byte_writes_s = 1) THEN          -- The first two bytes are just x"FF" with the slave select not pulled low.  
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- This is to allow the SD Card to finish anything that it needs to do.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= SHUTDOWN_PREP_st;
                ELSIF (sd_spi_byte_writes_s = 2) THEN                                   -- This is the token (x"FE) that needs to be sent before data can be transfered
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FE";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= SHUTDOWN_PREP_st;
				ELSIF (sd_spi_byte_writes_s < 7 AND sd_spi_byte_writes_s > 2) THEN
					sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= sd_write_address_save_s(31 downto 24);
					sd_write_address_save_s		<= sd_write_address_save_s(23 downto 0) & x"00";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= SHUTDOWN_PREP_st;
				ELSIF (sd_spi_byte_writes_s < 11 AND sd_spi_byte_writes_s > 6) THEN
					sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= sd_read_address_s(31 downto 24);
					sd_read_address_s			<= sd_read_address_s(23 downto 0) & x"00";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= SHUTDOWN_PREP_st;
                ELSIF (sd_spi_byte_writes_s = 515 OR sd_spi_byte_writes_s = 516) THEN   -- Two byes for CRC is allocated here. Since, CRC is disabled, we just send out x"FF"
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- for both the bytes. When CRC is implemented make sure to do so here.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= SHUTDOWN_PREP_st;
                ELSIF (sd_spi_byte_writes_s > 516) THEN                                 -- After sending the data, the SD Card sends a response of 1 byte.
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- The response is of the form "xxx0ABC1"
                                                                                        -- ABC can be of three different types:
                                                                                        -- 010 -> Data accepted    
                                                                                        -- 101 -> Data rejected due to a CRC error
                                                                                        -- 110 -> Data rejected due to a write error
                    sd_spi_init_state_s         <= CHECK_FOR_SD_DONE_st;    
					sd_spi_init_next_cmd_s		<= NULL_st;
                ELSE
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"00";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= SHUTDOWN_PREP_st;
                END IF;
			
				
			WHEN NULL_st =>
                    SD_card_shutdown_ready_p    <= b"10";
					sd_spi_init_state_s		    <= NULL_st;
			
            -- the block of data is transfered here.
            WHEN TRANSFER_DATA_st =>
                IF (sd_spi_byte_writes_s = 0 OR sd_spi_byte_writes_s = 1) THEN          -- The first two bytes are just x"FF" with the slave select not pulled low.  
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- This is to allow the SD Card to finish anything that it needs to do.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                ELSIF (sd_spi_byte_writes_s = 2) THEN                                   -- This is the token (x"FE) that needs to be sent before data can be transfered
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FE";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                ELSIF (sd_spi_byte_writes_s = 515 OR sd_spi_byte_writes_s = 516) THEN   -- Two byes for CRC is allocated here. Since, CRC is disabled, we just send out x"FF"
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- for both the bytes. Add later.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                ELSIF (sd_spi_byte_writes_s > 516) THEN                                 -- After sending the data, the SD Card sends a response of 1 byte.
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- The response is of the form "xxx0ABC1"
                                                                                        -- ABC can be of three different types:
                                                                                        -- 010 -> Data accepted    
                                                                                        -- 101 -> Data rejected due to a CRC error
                                                                                        -- 110 -> Data rejected due to a write error
                    sd_spi_init_state_s         <= CHECK_FOR_SD_DONE_st;
					sd_spi_init_next_cmd_s		<= TRANSFER_DATA_st;					
                ELSE
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            
                    fifo_write_rd_en_s          <= '1';                             -- Pull up read enable for 1 clock cycle
                    sd_spi_init_state_s         <= PULL_DOWN_RD_EN_st;
                END IF;
                
            WHEN CHECK_FOR_SD_DONE_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN                       
                    sd_spi_init_last_state_s    <= sd_spi_init_next_cmd_s;          
                    sd_spi_init_trans_s         <= '1';                       
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                ELSE 
                    sd_spi_init_state_s         <= WAIT_FOR_SD_READY_st;
                    sd_spi_ss_s                 <= '0';
                    sd_transfer_status_s        <= sd_spi_htransfer_in_s;
                    sd_spi_byte_writes_s        <= 0;
                END IF;
                
            WHEN PULL_DOWN_RD_EN_st =>
                    fifo_write_rd_en_s          <= '0';                             -- Pull down read enable
                    sd_spi_init_state_s         <= GET_1_BYTE_FROM_FIFO_st; 
                
            WHEN GET_1_BYTE_FROM_FIFO_st =>
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= fifo_write_dout_p;
                    sd_spi_init_trans_s         <= '1';
                    fifo_write_rd_en_s          <= '0';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                
                
            -- After a write, the SD Card takes a while to finish all the things that it needs to. While this is happening,
            -- the MISO is low and SCK needs to be sent to the card as long as this is the case. When we see that MISO is high,
            -- we know that the SD Card is done doing its thing and is available for other tasks. 
            WHEN WAIT_FOR_SD_READY_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN
                    sd_spi_init_state_s         <= WAIT_FOR_READ_OR_WRITE_st;
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_ss_s                 <= '1';
                ELSE 
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= WAIT_FOR_SD_READY_st;
                END IF;
            
            -- command CMD13 is used for checking the status of the SD Card. It tells if there was any addressing issue
            -- or other issues with the previous issued command.
            WHEN CMD13_st =>
                sd_spi_command_frame_s          <= CMD13_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= TRANSFER_DONE_st;
                sd_spi_response_type_s          <= 2;
                sd_spi_byte_tfers_s             <= 0;
                
            -- The transfers are done.            
            WHEN TRANSFER_DONE_st =>
                sd_spi_init_state_s             <= TRANSFER_DONE_st;
                sd_spi_transfer_done_s          <= '1';    
            
            
            -- The next few states deal with reading data from the SD Card and writing the read
            -- data from the SD card into the FC interface TX FIFO
            WHEN READ_st =>
                sd_spi_command_frame_s          <= CMD17_FRAME_c & sd_read_address_s & x"00";
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= WAIT_FOR_START_TOKEN_N_READ_st;
                sd_spi_init_rtrn_cmd_s          <= READ_st;
                sd_spi_response_type_s          <= 11;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD17_c;
                sd_spi_byte_tfers_s             <= 0;
                
            -- a start token is sent by the SD Card to indicate the start of the data packet
            WHEN WAIT_FOR_START_TOKEN_N_READ_st =>
                IF (sd_spi_htransfer_in_s = x"FE") THEN
                    sd_spi_init_state_s         <= READ_DATA_st;
                    sd_spi_byte_reads_s         <= 0;
                ELSE
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= WAIT_FOR_START_TOKEN_N_READ_st;
                END IF;
            
            -- read all the 512 bytes with two CRC bytes
            WHEN READ_DATA_st =>
                IF (sd_spi_byte_reads_s = 514) THEN     -- 512 because there are 2 CRC bytes as well, future add some logic to not store the two CRCs
                    sd_spi_byte_reads_s         <= 0;
                    fc_fifo_tx_wr_en_s          <= '0';
                    sd_sectors_written_s        <= sd_sectors_written_s - '1';
                    sd_spi_init_state_s         <= WAIT_FOR_READ_OR_WRITE_st;
                ELSE
                    sd_spi_byte_reads_s         <= sd_spi_byte_reads_s + 1;
                    fc_fifo_tx_wr_en_s          <= '0';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= WRITE_TO_FC_TX_FIFO_st;
                END IF;
            
            -- writes to the FC FIFO are handled here
            WHEN WRITE_TO_FC_TX_FIFO_st =>
                IF ((sd_spi_byte_reads_s mod 2) = 0) THEN  -- some "packetization". The FC FIFO is 16 bits in length whereas the SD card stores in 8 bit lengths. So, group them up.
                    fc_fifo_tx_din_s            <= fc_fifo_tx_din_s(7 DOWNTO 0) & sd_spi_htransfer_in_s;
                    sd_spi_init_state_s         <= PULL_UP_WR_EN_st;
                ELSE
                    fc_fifo_tx_din_s            <= x"00" & sd_spi_htransfer_in_s;
                    sd_spi_init_state_s         <= READ_DATA_st;
                END IF;
                
            -- PULL UP write enable for 1 clock cycle
            WHEN PULL_UP_WR_EN_st =>
                fc_fifo_tx_wr_en_s              <= '1';
                sd_spi_init_state_s             <= READ_DATA_st;
                
            
            -- All the states below are called by the above states
            -- They consist mainly of intermediary steps like sending out the command, receiving a response
            -- and checking the response.
            
            -- This state is where the command is sent out.    
            WHEN SEND_COMMAND_st =>
                IF (sd_spi_byte_tfers_s = COMMAND_FRAME_COUNT_c) THEN
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_last_state_s    <= RESPONSE_WAIT_st;        
                ELSE 
                    IF (sd_spi_byte_tfers_s = 0) THEN
                        sd_spi_ss_s             <= '1';             -- note that for the first byte (x"FF") slave select is not lowered.
                    ELSE
                        sd_spi_ss_s             <= '0';
                    END IF;
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= SEND_COMMAND_st;
                    sd_spi_htransfer_out_s      <= sd_spi_command_frame_s(55 DOWNTO 48);
                    sd_spi_command_frame_s      <= sd_spi_command_frame_s(47 DOWNTO  0) & x"00";
                END IF;
                
            -- Wait for the SD Card to give out a response. It should take a few 
            -- byte transfers for this to happen. 
            WHEN RESPONSE_WAIT_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= RESPONSE_WAIT_st;
                    sd_spi_byte_tfers_s         <= 0;
                ELSE
                    -- sd_spi_init_state_s         <= RESPONSE_1_st WHEN sd_spi_response_type_s = 1 ELSE
                                                   -- RESPONSE_3_st WHEN sd_spi_response_type_s = 3 ELSE
                                                   -- RESPONSE_7_st WHEN sd_spi_response_type_s = 7 ELSE
                                                   -- RESPONSE_1_st;
                    
                    -- the above commented out construct is preffered for its brevity but it is not supported
                    -- with the VHDL being used in this code.
                    CASE (sd_spi_response_type_s) IS
                    WHEN 1 => 
                        sd_spi_init_state_s     <= RESPONSE_1_st;
                    WHEN 11 =>
                        sd_spi_init_state_s     <= RESPONSE_1_sslow_st;
                    WHEN 2 =>
                        sd_spi_init_state_s     <= RESPONSE_2_st;
                    WHEN 3 => 
                        sd_spi_init_state_s     <= RESPONSE_3_st;
                    WHEN 7 => 
                        sd_spi_init_state_s     <= RESPONSE_7_st;
                    WHEN OTHERS =>
                        sd_spi_init_state_s     <= RESPONSE_1_st;
                    END CASE;
                    
                END IF;
            
            -- Response 1 is 8 bits in length. It is issued by commands CMD0, CMD55 and ACMD41.  
            WHEN RESPONSE_1_st =>
                IF (sd_spi_htransfer_in_s = sd_spi_expected_resp_s(7 DOWNTO 0)) THEN
                    sd_spi_init_state_s         <= sd_spi_init_next_cmd_s;
                ELSE
                    sd_spi_init_state_s         <= sd_spi_init_rtrn_cmd_s;
                END IF;
                sd_spi_ss_s                     <= '1';
                sd_spi_byte_tfers_s             <= 0;
            
            -- This response is just the same as response 1 in the previous state. However, this state
            -- does not raise slave select high. It keeps slave select low, hence the name of the state.
            WHEN RESPONSE_1_sslow_st=>
                IF (sd_spi_htransfer_in_s = sd_spi_expected_resp_s(7 DOWNTO 0)) THEN
                    sd_spi_init_state_s         <= sd_spi_init_next_cmd_s;
                ELSE
                    sd_spi_init_state_s         <= sd_spi_init_rtrn_cmd_s;
                END IF;
                sd_spi_ss_s                     <= '0';
                sd_spi_byte_tfers_s             <= 0;
                
            -- Response 2 is 16 bits in length and has a list of error flags that are raised if there was anything
            -- wrong in the previous transfer. It is issued after CMD13 is sent.
            WHEN RESPONSE_2_st =>
                IF (sd_spi_byte_tfers_s = 2) THEN
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_init_state_s         <= sd_spi_init_next_cmd_s;
                    sd_spi_ss_s                 <= '1';
                ELSE
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    response_2_s                <= response_2_s(7 DOWNTO 0) & sd_spi_htransfer_in_s;
                END IF;
                
                
            -- Response 3 is 40 bits in length. the M.S 8 bits make R1 and the 32 L.S bits make the OCR. 
            WHEN RESPONSE_3_st =>
                IF (sd_spi_byte_tfers_s = RESPONSE_3_BYTE_COUNT_c) THEN
                    sd_ccs_bit_s            <= response_3_s(30);            -- the 30th bit in the OCR register is the CCS bit.
                    sd_spi_init_state_s     <= sd_spi_init_next_cmd_s;
                    sd_spi_byte_tfers_s     <= 0;
                    sd_spi_ss_s             <= '1';
                ELSE
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= RESPONSE_3_st;
                    response_3_s                <= response_3_s(31 DOWNTO 0) & sd_spi_htransfer_in_s;
                END IF;        
                
            -- response 7 is 40 bits in length. The M.S 8 bits make R1 and the 32 L.S bits has other statuses including an echo back
            -- in the least significant 8 bits.
            WHEN RESPONSE_7_st =>
                IF (sd_spi_byte_tfers_s = RESPONSE_7_BYTE_COUNT_c) THEN
                    IF ((response_7_s(3 DOWNTO 0)&sd_spi_htransfer_in_s) = sd_spi_expected_resp_s(11 DOWNTO 0)) THEN
                        sd_spi_init_state_s     <= sd_spi_init_next_cmd_s;    
                    ELSE
                        sd_spi_init_state_s     <= sd_spi_init_rtrn_cmd_s;
                    END IF;
                    sd_spi_ss_s                 <= '1';
                    sd_spi_byte_tfers_s         <= 0;
                ELSE
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= RESPONSE_7_st;
                    response_7_s                <= response_7_s(31 DOWNTO 0) & sd_spi_htransfer_in_s;
                END IF;
            
            -- This state is reached whenever a transfer needs to be completed. The sd_spi_byte_done_p is polled to check if the
            -- transfer is complete and the data is captured.
            WHEN INIT_WAIT_FOR_TRANS_END_st =>
                IF (sd_spi_byte_done_s = '1') THEN
                    sd_spi_init_trans_s         <= '0';
                    sd_spi_byte_tfers_s         <= sd_spi_byte_tfers_s + 1;
                    sd_spi_init_state_s         <= sd_spi_init_last_state_s;
                ELSE
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                END IF;
                
            WHEN OTHERS =>
                sd_spi_init_state_s             <= IDLE_st;
            
            END CASE;
            
        END IF;
        
    END PROCESS;    
    
END GENERATE;

--------------------------------------------------------------------------------------------------------------------------
--
--Everything past here is debugging
--
--------------------------------------------------------------------------------------------------------------------------

DEBUGGING_OPERATION:
IF (DEBUGGING_MODE_c = 1) GENERATE
    
    INITIALIZATION_AND_CONTROL_SM:
    PROCESS (clk210_p, reset_p) BEGIN
    
        IF reset_p = '1' THEN
            sd_spi_init_state_s             <= IDLE_st;
            sd_spi_init_wait_cntr_s         <= 0;
            sd_spi_init_next_cmd_s          <= IDLE_st;
            sd_spi_init_rtrn_cmd_s          <= IDLE_st;
            sd_spi_init_last_state_s        <= IDLE_st;
            sd_spi_select_speed_s           <= '0';
            sd_spi_command_frame_s          <= (OTHERS => '0');
            sd_spi_htransfer_out_s          <= (OTHERS => '1');
            sd_spi_init_done_s              <= '0';
            response_3_s                    <= (OTHERS => '0');
            response_7_s                    <= (OTHERS => '0');
            sd_transfer_status_s            <= (OTHERS => '0');
            sd_spi_byte_writes_s            <= 0;
            SD_card_shutdown_ready_p        <= b"00";
            sd_write_address_s              <= (OTHERS => '0');
            
        ELSIF RISING_EDGE (clk210_p) THEN
            
            CASE(sd_spi_init_state_s) IS
            
            -- This state is where all the defaults are set. 
            WHEN IDLE_st =>
                sd_spi_init_wait_cntr_s         <= 0;
                sd_spi_init_state_s             <= WAIT_FOR_5ms_st;
                sd_spi_init_next_cmd_s          <= IDLE_st;
                sd_spi_init_rtrn_cmd_s          <= IDLE_st;
                sd_spi_init_last_state_s        <= IDLE_st;
                sd_spi_select_speed_s           <= '0';
                sd_spi_init_done_s              <= '0';
                sd_spi_command_frame_s          <= (OTHERS => '0');
                sd_spi_htransfer_out_s          <= (OTHERS => '1');
                sd_spi_transfer_done_s          <= '0';
                random_data_s                   <= (OTHERS => '0');
            
            -- It is recommended to wait for 1 millisecond after power up to allow the SD Card
            -- to achieve a stable voltage. Here, we use 5ms just to be safe.
            WHEN WAIT_FOR_5ms_st =>
                IF (sd_spi_init_wait_cntr_s = INIT_WAIT_COUNTER_c) THEN
                    sd_spi_init_state_s         <= INIT_st;
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_select_speed_s       <= '0';
                    sd_spi_init_wait_cntr_s     <= 0;
                ELSE 
                    sd_spi_init_wait_cntr_s     <= sd_spi_init_wait_cntr_s + 1;
                END IF;
            
            -- it is expected that the SD card receives atleast 74 cycles of dummy bits
            -- This allows it to perform some initializations
            WHEN INIT_st =>
                IF (sd_spi_byte_tfers_s = DUMMY_CYCLE_COUNT_c) THEN
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_init_state_s         <= CMD0_st;
                    sd_spi_command_frame_s      <= CMD0_FRAME_c;
                    SD_card_shutdown_ready_p    <= b"00";
                ELSE
                    SD_card_shutdown_ready_p    <= b"00";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_ss_s                 <= '1';
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st; 
                    sd_spi_init_last_state_s    <= INIT_st;
                END IF;
            
            -- send out command CMD0. This sets the SD card to SPI mode
            WHEN CMD0_st =>
                sd_spi_command_frame_s          <= CMD0_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= CMD8_st;
                sd_spi_init_rtrn_cmd_s          <= CMD0_st;
                sd_spi_response_type_s          <= 1;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD0_c;
            
            -- it is mandatory to send CMD8 before ACMD41. CMD8 verifies the operating voltage ranges
            WHEN CMD8_st =>
                sd_spi_command_frame_s          <= CMD8_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= CMD55_st;
                sd_spi_init_rtrn_cmd_s          <= CMD8_st;
                sd_spi_response_type_s          <= 7;
                sd_spi_expected_resp_s(11 DOWNTO 0) <= R7_CMD8_c;
                
            -- CMD 55 needs to be sent before ACMD41 can be sent. CMD55 is sent before any ACMD is sent
            WHEN CMD55_st =>
                sd_spi_command_frame_s          <= CMD55_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= ACMD41_st;
                sd_spi_init_rtrn_cmd_s          <= CMD55_st;
                sd_spi_response_type_s          <= 1;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD55_c;                

            -- send out ACMD41_FRAME_c. ACMD41 is used to initiate the initialization process.
            WHEN ACMD41_st =>
                sd_spi_command_frame_s          <= ACMD41_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= CMD58_st;
                sd_spi_init_rtrn_cmd_s          <= CMD55_st;
                sd_spi_response_type_s          <= 1;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_ACMD41_c;        
                
            -- This is used to read the OCR register for the CCS bit. Not really any useful information
            -- but this command is included because the SD Spec has included it in its initialization
            -- flow chart.
            WHEN CMD58_st =>    
                sd_spi_command_frame_s          <= CMD58_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= DONE_INIT_st;
                sd_spi_init_rtrn_cmd_s          <= DONE_INIT_st;
                sd_spi_response_type_s          <= 3;
                -- sd_spi_expected_resp_s          <= R3_CMD58_c;
            
            -- Initialization is done. This will allow the next state machine to start receiving data from
            -- the detector top and have it be stored.
            WHEN DONE_INIT_st =>
                sd_spi_init_done_s              <= '1';
                sd_spi_select_speed_s           <= '1';
                sd_spi_init_state_s             <= CMD24_st;
            
            -- CMD 24 is used to transfer a block of 512 bytes of data. 
            WHEN CMD24_st =>
                sd_spi_command_frame_s          <= CMD24_FRAME_c & sd_write_address_s & x"00";
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= TRANSFER_DATA_st;
                sd_spi_init_rtrn_cmd_s          <= CMD24_st;
                sd_spi_response_type_s          <= 11;
                sd_spi_expected_resp_s(7 DOWNTO 0) <= R1_CMD24_c;
                sd_spi_byte_tfers_s             <= 0;
            
            -- the block of data is transfered here.
            WHEN TRANSFER_DATA_st =>
                IF (sd_spi_byte_writes_s = 0 OR sd_spi_byte_writes_s = 1) THEN          -- The first two bytes are just x"FF" with the slave select not pulled low.  
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- This is to allow the SD Card to finish anything that it needs to do.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                ELSIF (sd_spi_byte_writes_s = 2) THEN                                   -- This is the token (x"FE) that needs to be sent before data can be transfered
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FE";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                ELSIF (sd_spi_byte_writes_s = 515 OR sd_spi_byte_writes_s = 516) THEN   -- Two byes for CRC is allocated here. Since, CRC is disabled, we just send out x"FF"
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- for both the bytes.
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                ELSIF (sd_spi_byte_writes_s > 516) THEN                                 -- After sending the data, the SD Card sends a response of 1 byte.
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- The response is of the form "xxx0ABC1"
                    IF (sd_spi_htransfer_in_s = x"FF") THEN                             -- ABC can be of three different types:
                        sd_spi_init_last_state_s    <= TRANSFER_DATA_st;                -- 010 -> Data accepted    
                        sd_spi_init_trans_s         <= '1';                             -- 101 -> Data rejected due to a CRC error
                        sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;      -- 110 -> Data rejected due to a write error
                        sd_spi_htransfer_out_s      <= x"FF";
                    ELSE 
                        sd_spi_init_state_s         <= WAIT_FOR_SD_READY_st;
                        sd_spi_ss_s                 <= '0';
                        sd_transfer_status_s        <= sd_spi_htransfer_in_s;
                    END IF;
                ELSE
                    sd_spi_byte_writes_s        <= sd_spi_byte_writes_s + 1;            -- Here's where the data is transfered. Right now it just random data but will be replaced 
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;          -- with actual data.
                    sd_spi_htransfer_out_s      <= random_data_s;
                    random_data_s               <= random_data_s + '1';
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_last_state_s    <= TRANSFER_DATA_st;
                END IF;
                
            -- After a write, the SD Card takes a while to finish all the things that it needs to. While this is happening,
            -- the MISO is low and SCK needs to be sent to the card as long as this is the case. When we see that MISO is high,
            -- we know that the SD Card is done doing its thing and is available for other tasks. 
            WHEN WAIT_FOR_SD_READY_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN
                    sd_spi_init_state_s         <= CMD13_st;
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_ss_s                 <= '1';
                ELSE 
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= WAIT_FOR_SD_READY_st;
                END IF;
            
            -- command CMD13 is used for checking the status of the SD Card. It tells if there was any addressing issue
            -- or other issues with the previous issued command.
            WHEN CMD13_st =>
                sd_spi_command_frame_s          <= CMD13_FRAME_c;
                sd_spi_init_state_s             <= SEND_COMMAND_st;
                sd_spi_init_next_cmd_s          <= TRANSFER_DONE_st;
                sd_spi_response_type_s          <= 2;
                sd_spi_byte_tfers_s             <= 0;
                
            -- The transfers are done.            
            WHEN TRANSFER_DONE_st =>
                sd_spi_init_state_s             <= TRANSFER_DONE_st;
                sd_spi_transfer_done_s          <= '1';    
            
            
            
            -- All the states below are called by the above states
            -- They consist mainly of intermediary steps like sending out the command, receiving a response
            -- and checking the response.
            
            -- This state is where the command is sent out.    
            WHEN SEND_COMMAND_st =>
                IF (sd_spi_byte_tfers_s = COMMAND_FRAME_COUNT_c) THEN
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_htransfer_out_s      <= x"FF";
                    sd_spi_init_last_state_s    <= RESPONSE_WAIT_st;        
                ELSE 
                    IF (sd_spi_byte_tfers_s = 0) THEN
                        sd_spi_ss_s             <= '1';             -- note that for the first byte (x"FF") slave select is not lowered.
                    ELSE
                        sd_spi_ss_s             <= '0';
                    END IF;
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= SEND_COMMAND_st;
                    sd_spi_htransfer_out_s      <= sd_spi_command_frame_s(55 DOWNTO 48);
                    sd_spi_command_frame_s      <= sd_spi_command_frame_s(47 DOWNTO  0) & x"00";
                END IF;
                
            -- Wait for the SD Card to give out a response. It should take a few 
            -- byte transfers for this to happen. 
            WHEN RESPONSE_WAIT_st =>
                IF (sd_spi_htransfer_in_s = x"FF") THEN
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= RESPONSE_WAIT_st;
                    sd_spi_byte_tfers_s         <= 0;
                ELSE
                    -- sd_spi_init_state_s         <= RESPONSE_1_st WHEN sd_spi_response_type_s = 1 ELSE
                                                   -- RESPONSE_3_st WHEN sd_spi_response_type_s = 3 ELSE
                                                   -- RESPONSE_7_st WHEN sd_spi_response_type_s = 7 ELSE
                                                   -- RESPONSE_1_st;
                    
                    -- the above commented out construct is preffered for its brevity but it is not supported
                    -- with the VHDL being used in this code.
                    CASE (sd_spi_response_type_s) IS
                    WHEN 1 => 
                        sd_spi_init_state_s     <= RESPONSE_1_st;
                    WHEN 11 =>
                        sd_spi_init_state_s     <= RESPONSE_1_sslow_st;
                    WHEN 2 =>
                        sd_spi_init_state_s     <= RESPONSE_2_st;
                    WHEN 3 => 
                        sd_spi_init_state_s     <= RESPONSE_3_st;
                    WHEN 7 => 
                        sd_spi_init_state_s     <= RESPONSE_7_st;
                    WHEN OTHERS =>
                        sd_spi_init_state_s     <= RESPONSE_1_st;
                    END CASE;
                    
                END IF;
            
            -- Response 1 is 8 bits in length. It is issued by commands CMD0, CMD55 and ACMD41.  
            WHEN RESPONSE_1_st =>
                IF (sd_spi_htransfer_in_s = sd_spi_expected_resp_s(7 DOWNTO 0)) THEN
                    sd_spi_init_state_s         <= sd_spi_init_next_cmd_s;
                ELSE
                    sd_spi_init_state_s         <= sd_spi_init_rtrn_cmd_s;
                END IF;
                sd_spi_ss_s                     <= '1';
                sd_spi_byte_tfers_s             <= 0;
            
            -- This response is just the same as response 1 in the previous state. However, this state
            -- does not raise slave select high. It keeps slave select low, hence the name of the state.
            WHEN RESPONSE_1_sslow_st=>
                IF (sd_spi_htransfer_in_s = sd_spi_expected_resp_s(7 DOWNTO 0)) THEN
                    sd_spi_init_state_s         <= sd_spi_init_next_cmd_s;
                ELSE
                    sd_spi_init_state_s         <= sd_spi_init_rtrn_cmd_s;
                END IF;
                sd_spi_ss_s                     <= '0';
                sd_spi_byte_tfers_s             <= 0;
                
            -- Response 2 is 16 bits in length and has a list of error flags that are raised if there was anything
            -- wrong in the previous transfer. It is issued after CMD13 is sent.
            WHEN RESPONSE_2_st =>
                IF (sd_spi_byte_tfers_s = 2) THEN
                    sd_spi_byte_tfers_s         <= 0;
                    sd_spi_init_state_s         <= sd_spi_init_next_cmd_s;
                    sd_spi_ss_s                 <= '1';
                ELSE
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    response_2_s                <= response_2_s(7 DOWNTO 0) & sd_spi_htransfer_in_s;
                END IF;
                
                
            -- Response 3 is 40 bits in length. the M.S 8 bits make R1 and the 32 L.S bits make the OCR. 
            WHEN RESPONSE_3_st =>
                IF (sd_spi_byte_tfers_s = RESPONSE_3_BYTE_COUNT_c) THEN
                    sd_ccs_bit_s            <= response_3_s(30);            -- the 30th bit in the OCR register is the CCS bit.
                    sd_spi_init_state_s     <= sd_spi_init_next_cmd_s;
                    sd_spi_byte_tfers_s     <= 0;
                    sd_spi_ss_s             <= '1';
                ELSE
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= RESPONSE_3_st;
                    response_3_s                <= response_3_s(31 DOWNTO 0) & sd_spi_htransfer_in_s;
                END IF;        
                
            -- response 7 is 40 bits in length. The M.S 8 bits make R1 and the 32 L.S bits has other statuses including an echo back
            -- in the least significant 8 bits.
            WHEN RESPONSE_7_st =>
                IF (sd_spi_byte_tfers_s = RESPONSE_7_BYTE_COUNT_c) THEN
                    IF ((response_7_s(3 DOWNTO 0)&sd_spi_htransfer_in_s) = sd_spi_expected_resp_s(11 DOWNTO 0)) THEN
                        sd_spi_init_state_s     <= sd_spi_init_next_cmd_s;    
                    ELSE
                        sd_spi_init_state_s     <= sd_spi_init_rtrn_cmd_s;
                    END IF;
                    sd_spi_ss_s                 <= '1';
                    sd_spi_byte_tfers_s         <= 0;
                ELSE
                    sd_spi_init_trans_s         <= '1';
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_spi_init_last_state_s    <= RESPONSE_7_st;
                    response_7_s                <= response_7_s(31 DOWNTO 0) & sd_spi_htransfer_in_s;
                END IF;
            
            -- This state is reached whenever a transfer needs to be completed. The sd_spi_byte_done_p is polled to check if the
            -- transfer is complete and the data is captured.
            WHEN INIT_WAIT_FOR_TRANS_END_st =>
                IF (sd_spi_byte_done_s = '1') THEN
                    sd_spi_init_trans_s         <= '0';
                    sd_spi_byte_tfers_s         <= sd_spi_byte_tfers_s + 1;
                    sd_spi_init_state_s         <= sd_spi_init_last_state_s;
                ELSE
                    sd_spi_init_state_s         <= INIT_WAIT_FOR_TRANS_END_st;
                END IF;
                
            WHEN OTHERS =>
                sd_spi_init_state_s             <= IDLE_st;
            
            END CASE;
            
        END IF;
        
    END PROCESS;
  
END GENERATE;  
    
END BEHAVIORAL;

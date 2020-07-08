`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/02/2017 06:24:28 PM
// Design Name:
// Module Name: SD_Card_SPI_controller
// Project Name:
// Target Devices:
// Tool Versions:
// Description: This module is a wrapper for the SD Card Byte Transfer module.
//      It uses the Byte Control module to send and receive data from the SD Card.
//      The higher module above this is only a plain wrapper.
//      Currently, the SPI Interface does not make use of CRC except for issuing CMD0.
//      Since, CMD0 is fixed, a real time CRC calculation is not necessary (it's a given)
//      Refer to page 222 of the SD Card Physical Layer Simplified Specification Version 6.0
//      document. You can find this document at https://www.sdcard.org/downloads/pls/index.html 
//      The comments in this file will constantly reference the SD Card Physical Layer doc.
//      If otherwise specified, all the page numbers will be of this document.
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module SD_Card_SPI_controller(
    clk210_p,
    reset_p,
    sd_spi_mosi_p,
    sd_spi_miso_p,
    sd_spi_ss_p,
    sd_spi_sck_p,
    sd_card_init_error_p,
    sd_card_initialized_p,
    sd_card_ccs_bit_p
    );

    input               clk210_p;
    input               reset_p;
    input               sd_spi_miso_p;

    output              sd_spi_mosi_p;
    output              sd_spi_sck_p;
    output              sd_spi_ss_p;
    output              sd_card_init_error_p;
    output              sd_card_initialized_p;
    output              sd_card_ccs_bit_p;
    
    // Variable declarations
    wire                sd_spi_mosi_p;
    wire                sd_spi_miso_p;
    wire                sd_spi_ss_p;
    wire                sd_spi_sck_p;
    
    reg                 sd_spi_ss_s                 = 1'b1;
    reg         [ 7:0]  sd_spi_htransfer_out_s      = 8'd0;
    wire        [ 7:0]  sd_spi_htransfer_in_s;
    reg                 sd_spi_init_trans_s         = 1'b0;
    wire                sd_spi_byte_done_p;
    wire                sd_spi_speed_select_s;
    wire                sd_spi_normal_baud_s;
    wire                sd_spi_init_baud_s;
    wire                sd_card_init_error_p;
    wire                sd_card_initialized_p;
    
    reg                 sd_card_dummy_speed_s       =  1'b1;
    reg                 sd_card_init_error_s        =  1'b0;    
    reg         [ 7:0]  sd_card_init_state_s        =  8'd0;
    reg         [ 7:0]  sd_card_init_rtrn_state_s   =  8'd0;
    reg                 sd_card_initialized_s       =  1'b0;    
    reg         [31:0]  sd_card_init_wait_counter_s = 32'd0;
    reg         [ 7:0]  sd_card_dummy_cycle_count_s =  8'd0;
    reg         [ 7:0]  sd_card_byte_tfer_count_s   =  8'd0;
    reg         [47:0]  sd_card_command_frame_s     = 48'd0;
    reg         [39:0]  sd_card_R7_response_s       = 40'd0;    
    reg         [39:0]  sd_card_R3_response_s       = 40'd0;    
    reg                 sd_card_ccs_bit_s           =  1'd0;
    reg         [ 7:0]  delay_ss_s                  =  8'd0;    
    wire                sd_card_ccs_bit_p;
    
    // Output assignments
    assign              sd_card_init_error_p    = sd_card_init_error_s;
    assign              sd_spi_ss_p             = sd_spi_ss_s;         
    assign              sd_card_initialized_p   = sd_card_initialized_s;
    assign              sd_spi_speed_select_s   = (sd_card_dummy_speed_s == 1'b0)?1:0;  // 400 KHz if not initialized
                                                                                        //  35 MHz if initialized
    assign              sd_card_ccs_bit_p       = sd_card_ccs_bit_s;
    
    // Parameter declarations for state machines
    parameter   [ 7:0]  INIT_IDLE_st                    = 8'd0;    
    parameter   [ 7:0]  WAIT_FOR_5_ms_st                = 8'd1;
    parameter   [ 7:0]  SEND_DUMMY_CLKS_st              = 8'd2;
    parameter   [ 7:0]  SET_TO_SPI_MODE_st              = 8'd3;
    parameter   [ 7:0]  INIT_WAIT_FR_R1_AFTR_CMD0_st    = 8'd4;
    parameter   [ 7:0]  CHECK_VOLT_RANGE_st             = 8'd5;
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R7_B1_st = 8'd6;
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R7_B2_st = 8'd7;
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R7_B3_st = 8'd8;
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R7_B4_st = 8'd9;
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R7_B5_st = 8'd10;
    parameter   [ 7:0]  CHECK_RESPONSE_R7_st            = 8'd11;
    parameter   [ 7:0]  INITIALIZE_SD_CARD_st           = 8'd12;
    parameter   [ 7:0]  INIT_WAIT_FR_R1_AFTR_ACMD41_st  = 8'd13;
    parameter   [ 7:0]  READ_OCR_st                     = 8'd14;    
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R3_B1_st = 8'd15;    
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R3_B2_st = 8'd16;    
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R3_B3_st = 8'd17;    
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R3_B4_st = 8'd18;    
    parameter   [ 7:0]  INIT_WAIT_FOR_RESPONSE_R3_B5_st = 8'd19;    
    parameter   [ 7:0]  CHECK_RESPONSE_R3_st            = 8'd20;    
    parameter   [ 7:0]  INIT_WAIT_FOR_TRANS_END_st      = 8'd21;
    parameter   [ 7:0]  INIT_DONE_st                    = 8'd22;
    parameter   [ 7:0]  DELAY_SS_LOW_st                 = 8'd23;
    //-----------------------------------------------------------------------//
    // Parameters for constants
    parameter   [31:0]  INITIALIZATION_WAIT_TIME_c  = 32'd00_000_010;   // 24,000,000 counts - a little higher than 5 ms (23809523.809523809523809523809524)
    parameter   [ 7:0]  SD_CARD_DUMMY_BYTES_c       = 8'd10;
    parameter   [ 7:0]  SD_CARD_CMD_FRAME_LNTH_c    = 8'd6;  
    parameter   [39:0]  SD_CARD_R7_RESP_FR_CMD8_c   = 40'h01_00_01_AA;  // This is the expected R7 response for command CMD8
    //-----------------------------------------------------------------------//
    
    
    //-----------------------------------------------------------------------//
    // Parameter list for the command frames
    // A Command frame is a composition of 6 bytes of data
    // BYTE     1    --> 8'b01xx_xxxx        (the x's make the INDEX number 'n' in CMD'n')
    // BYTES    2-5  --> Argument. This can be an address or just 0's if its
    //                             not a data transfer
    // BYTE     6    --> CRC       (Clock Redundany Check) See the decription
    //                              above in the module for where to find information
    //                              on CRC. In short, its not used in this current
    //                              design except for the reset (CMD0) command
    //                              and the check voltage range command (CMD8) (pg 230)
    //                                             BYTE:  1  2  3  4  5  6
    //                                                 INDEX| ARGUMENT  |CRC 
    parameter   [47:0]  CMD0_FRAME_c                = 48'h40_00_00_00_00_95;        // This is a reset command. It is used to change from SD mode to SPI mode
    parameter   [47:0]  CMD1_FRAME_c                = 48'h41_00_00_00_00_00;        // 
    parameter   [47:0]  CMD8_FRAME_c                = 48'h48_00_00_01_AA_87;        // Table 4-18 page 92 (01 --> voltage range is 2.7V t0 3.6V)
    parameter   [47:0]  ACMD41_FRAME_c              = 48'h69_40_00_00_00_00;        // Index -> (101001) Bit 30 in argument (bit 38 in frame) -> HCS. HCS is set to 1 for SDHC cards
    parameter   [47:0]  CMD58_FRAME_c               = 48'h7A_00_00_00_00_00;        // no argument
    
    //-----------------------------------------------------------------------//
    
    
    // Module declarations
    SD_Card_SPI_Byte_Transfer SD_Byte_Transfer_inst(
    .clk210_p               (clk210_p),                     // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                (reset_p),                      // INPUT  -  1 bit  - Global reset
    .sd_spi_mosi_p          (sd_spi_mosi_p),                // OUTPUT -  1 bit  - SPI MOSI
    .sd_spi_miso_p          (sd_spi_miso_p),                // INPUT  -  1 bit  - SPI MISO
    .sd_spi_sck_p           (sd_spi_sck_p),                 // OUTPUT -  1 bit  - SPI SCK
    .sd_spi_ltransfer_in_p  (sd_spi_htransfer_in_s),        // OUTPUT -  8 bits - data that is transfered in from the SD card to the FPGA
    .sd_spi_ltransfer_out_p (sd_spi_htransfer_out_s),       // INPUT  -  8 bits - data that is transfered in to the SD Card from the FPGA
    .sd_spi_init_trans_p    (sd_spi_init_trans_s),          // INPUT  -  1 bit  - signal to initiate a transfer
    .sd_spi_byte_done_p     (sd_spi_byte_done_p),           // OUTPUT -  1 bit  - signal that indicates that a byte has been trnasfered
    .sd_spi_select_speed_p  (sd_spi_speed_select_s),        // INPUT  -  1 bit  - Speed Select (0 --> INITIALIZATION, 1 --> NORMAL OPERATION)
    .sd_spi_normal_baud_p   (sd_spi_normal_baud_s),         // INPUT  -  1 bit  - NORMAL operation speed
    .sd_spi_init_baud_p     (sd_spi_init_baud_s)            // INPUT  -  1 bit  - INITIALIZATION speed
    );

    SD_Card_SPI_baud_gen
    #(
            525,                // INIT_BAUD_CLKDIV_c 
            6                   // NORMAL_BAUD_CLK_DIV_c
            )
    baud_gen_for_SD_spi(
    .clk210_p               (clk210_p),                     // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                (reset_p),                      // INPUT  -  1 bit  - Global reset
    .sd_spi_normal_baud_p   (sd_spi_normal_baud_s),         // OUTPUT -  1 bit  - normal operation speed
    .sd_spi_init_baud_p     (sd_spi_init_baud_s)            // OUTPUT -  1 bit  - initialization speed
    );

    
    //-----------------------------------------------------------------------//
    // State Machine (INITIALIZATION ONLY):
    // Refer to the webpage: http://elm-chan.org/docs/mmc/mmc_e.html for more
    // information. Here, there will be a brief description of the processes going on.
    // This state machine initializes the SD card and sets it in operation mode.
    // When initialization is done, it sets the sd_card_initialized_s high.
    // For more info, refer to Pg229 of the SD Card Spec doc. Specifically,
    // look at the flowchart.
    //-----------------------------------------------------------------------//
    
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            sd_card_init_state_s        <= INIT_IDLE_st;
            sd_card_initialized_s       <= 1'b0;
            sd_card_init_wait_counter_s <= 32'd0;
            sd_spi_ss_s                 <= 1'b1;
            sd_card_byte_tfer_count_s   <= 8'd0;
            sd_card_R7_response_s       <= 40'd0;
            sd_card_init_error_s        <= 1'b0;
            sd_card_dummy_speed_s       <= 1'b1;
            end
        else begin
            
            case (sd_card_init_state_s)
            
            // This is the start of the state machine
            INIT_IDLE_st: begin
                    sd_card_initialized_s       <= 1'b0;
                    sd_card_init_state_s        <= WAIT_FOR_5_ms_st;
                    sd_card_init_wait_counter_s <= 32'd0;
                    sd_spi_ss_s                 <= 1'b1;
                    sd_card_R7_response_s       <= 40'd0;
                    sd_card_init_error_s        <= 1'b0;
                    sd_card_dummy_speed_s       <= 1'b1;
                end
                
            // Here, wait for the SD Card to power up. Theoretically, it should only take
            // around 1 ms to power up but we shall wait a little longer than 5 ms to
            // give the card adequate time to power up
            WAIT_FOR_5_ms_st: begin
                    if (sd_card_init_wait_counter_s == INITIALIZATION_WAIT_TIME_c) begin
                        sd_card_init_state_s        <= SEND_DUMMY_CLKS_st;
                        sd_card_dummy_cycle_count_s <= 8'd0;
                        sd_card_init_wait_counter_s <= 32'd0;
                        end
                    else begin
                        sd_card_init_wait_counter_s <= sd_card_init_wait_counter_s + 1;
                        sd_card_init_state_s        <= WAIT_FOR_5_ms_st;
                    end
                end
            
            // This state will send 80 clock cycles to the SD card with dummy bytes.
            // Theoretically, the card only needs 74 cycles of the SCK, but we will be sending
            // 80 since that will be 10 bytes. All the bytes will be high (0xFF) 
            SEND_DUMMY_CLKS_st: begin
                    if (sd_card_dummy_cycle_count_s == SD_CARD_DUMMY_BYTES_c) begin
                        sd_card_init_state_s        <= SET_TO_SPI_MODE_st;
                        sd_card_command_frame_s     <= CMD0_FRAME_c;    // Set the command frame to transfer a reset command to change the SD card to SPI mode from SD mode
                        sd_card_dummy_cycle_count_s <= 8'd0;
                        sd_card_byte_tfer_count_s   <= 8'd0;
                        sd_card_dummy_speed_s       <= 1'b0;
                        end
                    else begin
                        sd_spi_ss_s                 <= 1'b1;            // Chip select needs to high during dummy bit transfers
                        sd_spi_init_trans_s         <= 1'b1;            // initiate SPI Transfer
                        sd_spi_htransfer_out_s      <= 8'hFF;           // Send hFF out on the line
                        sd_card_dummy_cycle_count_s <= sd_card_dummy_cycle_count_s + 1;  
                        sd_card_init_rtrn_state_s   <= SEND_DUMMY_CLKS_st;              // at the wait for trans_end state, change to this state
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;      // send the SM to the wait for trans_end state
                    end
                end
                               
            // This state sends a command to the SD card to transfer to the SPI mode of communication
            // The default mode is SD mode. Hence, it needs to be changed to SPI mode before talking to it.
            // The command is 0x00 and abbreviated CMD0
            SET_TO_SPI_MODE_st: begin   
                    if (sd_card_byte_tfer_count_s == SD_CARD_CMD_FRAME_LNTH_c) begin
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_spi_htransfer_out_s      <= 8'hFF;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FR_R1_AFTR_CMD0_st;            // return to the state to check for response R1
                        sd_card_byte_tfer_count_s   <= 8'd0;
                        end
                    else begin
                        sd_spi_init_trans_s         <= 1'b1;                                    // start an SPI transfer
                        sd_spi_ss_s                 <= 1'b0;                                    // Pull the slave select down. This will be pulled low till a response is received
                        sd_spi_htransfer_out_s      <= sd_card_command_frame_s[47:40];          // Data that needs to be transfered out
                        sd_card_command_frame_s     <= {sd_card_command_frame_s[39:0], 8'd0};   // Shift the command frame by a byte
                        sd_card_byte_tfer_count_s   <= sd_card_byte_tfer_count_s + 1;           // increment the byte counts
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;              // go to the state where the SM waits for the lower module to indicate that the transaction is done
                        sd_card_init_rtrn_state_s    <= SET_TO_SPI_MODE_st;                        
                    end
                end            
                    
            // This state waits for a response from the SD Card. This is typically 0 to 8 bytes for SD Cards but can be longer
            INIT_WAIT_FR_R1_AFTR_CMD0_st: begin
                    if (sd_spi_htransfer_in_s == 8'h01)begin                // bit 0 (idle) should be 1
                        sd_card_init_state_s        <= DELAY_SS_LOW_st;
                        sd_card_init_rtrn_state_s   <= CHECK_VOLT_RANGE_st;
                        sd_card_command_frame_s     <= CMD8_FRAME_c;        // CMD8 is issued to initialize the SD Card
                        sd_spi_ss_s                 <= 1'b1;                // Pull slave select high    
                        end
                    else if (sd_spi_htransfer_in_s == 8'hFF) begin          // still waiting for the SD card to send a response 
                        sd_spi_htransfer_out_s      <= 8'hFF;
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_spi_ss_s                 <= 1'b0;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FR_R1_AFTR_CMD0_st;
                        end
                    else begin    // a valid response has not been detected. Issue the command again
                        sd_card_init_state_s        <= DELAY_SS_LOW_st;
                        sd_card_init_rtrn_state_s   <= SET_TO_SPI_MODE_st;
                        sd_card_command_frame_s     <= CMD0_FRAME_c;
                        sd_spi_ss_s                 <= 1'b1;
                    end
                end
                       
            // This next state issues the CMD8 Frame that initializes the SD Card. This command
            // is mandatory to be issued prior to issuing the ACMD41 command. (Pg 211) 
            CHECK_VOLT_RANGE_st: begin
                    if (sd_card_byte_tfer_count_s == SD_CARD_CMD_FRAME_LNTH_c) begin
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_spi_htransfer_out_s      <= 8'hFF;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FOR_RESPONSE_R7_B1_st;         // The CMD8 command reponds with an R7 response which consists of 5 bytes
                        sd_card_byte_tfer_count_s   <= 8'd0;
                        end
                    else begin
                        sd_spi_init_trans_s         <= 1'b1;                                    // initialize a transfer
                        sd_spi_ss_s                 <= 1'b0;                                    // pull SS low
                        sd_spi_htransfer_out_s      <= sd_card_command_frame_s[47:40];          // send one byte of a command at a time
                        sd_card_command_frame_s     <= {sd_card_command_frame_s[39:0], 8'd0};
                        sd_card_byte_tfer_count_s   <= sd_card_byte_tfer_count_s + 1;           // increment by a byte
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;              
                        sd_card_init_rtrn_state_s   <= CHECK_VOLT_RANGE_st;
                    end
                end
                               
            // The next 5 states checks the response R7. R7 is 5 bytes in length with the first (M.S) byte 
            // being the response R1. See page 242 for the correct response pattern
            // Respnse should be 0x01_00_01_AA
            INIT_WAIT_FOR_RESPONSE_R7_B1_st: begin            
                    if (sd_spi_htransfer_in_s == 8'hFF) begin                   // wait for the SD card to start sending the response.
                                                                                // This check is only performed on the B1 state since after the 
                                                                                // SD card sends byte 1, it coninues to send the other bytes without
                                                                                // any delay
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FOR_RESPONSE_R7_B1_st;
                        end
                    else begin
                        sd_card_R7_response_s[39:32]<= sd_spi_htransfer_in_s;   // get the first byte of the response in here
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FOR_RESPONSE_R7_B2_st;
                    end
                end
                
            // Byte 2 of response R7
            INIT_WAIT_FOR_RESPONSE_R7_B2_st: begin
                    sd_card_R7_response_s[31:24]    <= sd_spi_htransfer_in_s;   // get the second byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_card_init_state_s            <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_card_init_rtrn_state_s       <= INIT_WAIT_FOR_RESPONSE_R7_B3_st;
                end
                                
            // Byte 3 of response R7
            INIT_WAIT_FOR_RESPONSE_R7_B3_st: begin
                    sd_card_R7_response_s[23:16]    <= sd_spi_htransfer_in_s;   // get the third byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_card_init_state_s            <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_card_init_rtrn_state_s       <= INIT_WAIT_FOR_RESPONSE_R7_B4_st;
                end
                                
            // Byte 4 of response R7
            INIT_WAIT_FOR_RESPONSE_R7_B4_st: begin
                    sd_card_R7_response_s[15:8]     <= sd_spi_htransfer_in_s;   // get the fourth byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_card_init_state_s            <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_card_init_rtrn_state_s       <= INIT_WAIT_FOR_RESPONSE_R7_B5_st;
                end
                            
            // Byte 5 of response R7
            INIT_WAIT_FOR_RESPONSE_R7_B5_st: begin
                    sd_card_R7_response_s[7:0]      <= sd_spi_htransfer_in_s;   // get the fifth byte in
                    sd_spi_ss_s                     <= 1'b1;                    // Pull slave select high disabling the SD card
                    sd_card_init_state_s            <= DELAY_SS_LOW_st;
                    sd_card_init_rtrn_state_s       <= CHECK_RESPONSE_R7_st;
                end
                
            // Check response 7 and see that it matches what it needs to be
            CHECK_RESPONSE_R7_st: begin
                    if (sd_card_R7_response_s == SD_CARD_R7_RESP_FR_CMD8_c) begin  // matches the expected response
                        sd_card_init_state_s        <= INITIALIZE_SD_CARD_st;
                        sd_card_command_frame_s     <= ACMD41_FRAME_c;
                        end
                    else begin
                    
                    
                        sd_card_init_state_s        <= INITIALIZE_SD_CARD_st;       // This needs to be updated to have an else state
                        sd_card_command_frame_s     <= ACMD41_FRAME_c;
                        sd_card_init_error_s        <= 1'b1;
                    end
                end
                
            // This state is where the initialization command is issued
            // This command is called ACDM41. 
            INITIALIZE_SD_CARD_st: begin
                    if (sd_card_byte_tfer_count_s == SD_CARD_CMD_FRAME_LNTH_c) begin
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_spi_htransfer_out_s      <= 8'hFF;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FR_R1_AFTR_ACMD41_st;          // Wait for a response from the SD card. 
                        sd_card_byte_tfer_count_s   <= 8'd0;
                        end
                    else begin
                        sd_spi_init_trans_s         <= 1'b1;                                    // initialize a transfer
                        sd_spi_ss_s                 <= 1'b0;                                    // pull SS low
                        sd_spi_htransfer_out_s      <= sd_card_command_frame_s[47:40];          // send one byte of a command at a time
                        sd_card_command_frame_s     <= {sd_card_command_frame_s[39:0], 8'd0};
                        sd_card_byte_tfer_count_s   <= sd_card_byte_tfer_count_s + 1;           // increment by a byte
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;              
                        sd_card_init_rtrn_state_s   <= INITIALIZE_SD_CARD_st;
                    end
                end
                 

            // Response for ACMD41. If the SD card indicates that it is out of the idle state,
            // you can move to the state to check for CCS. If the SD card doesn't move out of 
            // the idle state, continue to poll until it does.
            INIT_WAIT_FR_R1_AFTR_ACMD41_st: begin
                    if (sd_spi_htransfer_in_s == 8'h00) begin                   // bit 0 should be 0 -> idicates that the SD card is in busy state
                        sd_card_init_rtrn_state_s   <= READ_OCR_st;             // next state is to check card type
                        sd_card_command_frame_s     <= CMD58_FRAME_c;           // CMD58 frame
                        sd_spi_ss_s                 <= 1'b1;
                        sd_card_init_state_s        <= DELAY_SS_LOW_st;
                        end
                    else if (sd_spi_htransfer_in_s == 8'h01) begin              // if the SD card is in idle state, try initializing again
                        sd_spi_ss_s                 <= 1'b1;
                        sd_card_init_state_s        <= DELAY_SS_LOW_st;
                        sd_card_init_rtrn_state_s   <= INITIALIZE_SD_CARD_st;
                        sd_card_command_frame_s     <= ACMD41_FRAME_c;
                        end
                    else if (sd_spi_htransfer_in_s == 8'hFF) begin              // card hasn't sent a response yet, wait for it.
                        sd_spi_ss_s                 <= 1'b0;
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FR_R1_AFTR_ACMD41_st;
                        sd_spi_htransfer_out_s      <= 8'hFF;
                        end
                    else begin                                                  // repeat the command, if the response is unknown.
                        sd_spi_ss_s                 <= 1'b1;
                        sd_card_init_state_s        <= DELAY_SS_LOW_st;
                        sd_card_init_rtrn_state_s   <= INITIALIZE_SD_CARD_st;
                        sd_card_command_frame_s     <= ACMD41_FRAME_c;
                    end
                end
               
            
            // CMD 58. This is to check for CCS
            READ_OCR_st: begin
                    if (sd_card_byte_tfer_count_s == SD_CARD_CMD_FRAME_LNTH_c) begin
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_spi_htransfer_out_s      <= 8'hFF;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FOR_RESPONSE_R3_B1_st;
                        sd_card_byte_tfer_count_s   <= 8'd0;
                        end
                    else begin
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_spi_ss_s                 <= 1'b0;
                        sd_spi_htransfer_out_s      <= sd_card_command_frame_s[47:40];
                        sd_card_command_frame_s     <= {sd_card_command_frame_s[39:0], 8'd0};
                        sd_card_byte_tfer_count_s   <= sd_card_byte_tfer_count_s + 1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= READ_OCR_st;
                    end
                end
                
            INIT_WAIT_FOR_RESPONSE_R3_B1_st: begin
                    if (sd_spi_htransfer_in_s == 8'hFF) begin                   // wait for the SD card to start sending the response.
                                                                                // This check is only performed on the B1 state since after the 
                                                                                // SD card sends byte 1, it coninues to send the other bytes without
                                                                                // any delay
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FOR_RESPONSE_R3_B1_st;
                        end
                    else begin
                        sd_card_R3_response_s[39:32]<= sd_spi_htransfer_in_s;   // get the first byte of the response in here
                        sd_spi_init_trans_s         <= 1'b1;
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                        sd_card_init_rtrn_state_s   <= INIT_WAIT_FOR_RESPONSE_R3_B2_st;
                    end
                end
                
            // Byte 2 of response R3
            INIT_WAIT_FOR_RESPONSE_R3_B2_st: begin
                    sd_card_R3_response_s[31:24]    <= sd_spi_htransfer_in_s;   // get the second byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_card_init_state_s            <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_card_init_rtrn_state_s       <= INIT_WAIT_FOR_RESPONSE_R3_B3_st;
                end
                                
            // Byte 3 of response R3
            INIT_WAIT_FOR_RESPONSE_R3_B3_st: begin
                    sd_card_R3_response_s[23:16]    <= sd_spi_htransfer_in_s;   // get the third byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_card_init_state_s            <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_card_init_rtrn_state_s       <= INIT_WAIT_FOR_RESPONSE_R3_B4_st;
                end
                                
            // Byte 4 of response R3
            INIT_WAIT_FOR_RESPONSE_R3_B4_st: begin
                    sd_card_R3_response_s[15:8]     <= sd_spi_htransfer_in_s;   // get the fourth byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_card_init_state_s            <= INIT_WAIT_FOR_TRANS_END_st;
                    sd_card_init_rtrn_state_s       <= INIT_WAIT_FOR_RESPONSE_R3_B5_st;
                end
                            
            // Byte 5 of response R3
            INIT_WAIT_FOR_RESPONSE_R3_B5_st: begin
                    sd_card_R3_response_s[7:0]      <= sd_spi_htransfer_in_s;   // get the fifth byte in
                    sd_spi_init_trans_s             <= 1'b1;
                    sd_spi_ss_s                     <= 1'b1;                    // Pull slave select high disabling the SD card
                    sd_card_init_rtrn_state_s       <= CHECK_RESPONSE_R3_st;
                    sd_card_init_state_s            <= DELAY_SS_LOW_st;
                end
             
            // Check Response 3 and see what CCS is. CCS is assigned to the 30th bit in the OCR
            CHECK_RESPONSE_R3_st: begin
                    sd_card_ccs_bit_s               <= sd_card_R3_response_s[30];
                    sd_card_init_state_s            <= INIT_DONE_st;
                    sd_card_init_rtrn_state_s       <= INIT_DONE_st;
                end        
            
            // This state waits for the transaction to be done. Once, the transaction is done, the
            // state will change to what was entered to next_state_s
            INIT_WAIT_FOR_TRANS_END_st: begin
                    if (sd_spi_byte_done_p == 1'b1) begin
                        sd_card_init_state_s        <= sd_card_init_rtrn_state_s;
                        sd_spi_init_trans_s         <= 1'b0;
                        end
                    else begin
                        sd_card_init_state_s        <= INIT_WAIT_FOR_TRANS_END_st;
                    end
                end
                
            DELAY_SS_LOW_st: begin
                    if (delay_ss_s == 8'd100) begin
                        delay_ss_s                  <= 8'd0;
                        sd_card_init_state_s        <= sd_card_init_rtrn_state_s;
                        end
                    else begin
                        delay_ss_s                  <= delay_ss_s + 1;
                        sd_card_init_state_s        <= DELAY_SS_LOW_st;
                    end
                end
            
            // INITIALIZATION is done
            INIT_DONE_st: begin
                    sd_card_initialized_s           <= 1'b1;
                    sd_card_init_state_s            <= INIT_DONE_st;    
                    sd_card_init_error_s            <= 1'b0;
                end
                
                
            default: begin
                    sd_card_init_state_s        <= INIT_IDLE_st;
                    sd_card_init_rtrn_state_s   <= INIT_IDLE_st;
                end
            endcase
        end
    end
    
    //-----------------------------------------------------------------------//
    // STATE MACHINE: NORMAL OPERATION
    // This state machine 
    //-----------------------------------------------------------------------//
    
    
                
endmodule

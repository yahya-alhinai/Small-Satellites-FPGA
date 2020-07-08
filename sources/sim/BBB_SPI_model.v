`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2017 02:00:00 PM
// Design Name: 
// Module Name: BBB_SPI_model
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module BBB_SPI_model(
    clk210_p,
    reset_p,
    spi_mosi_p,
    spi_miso_p,
    spi_ss_p,
    spi_sck_p,
    spi_state_s,
    spi_rd_data_s,                  // INPUT  - 16 bits - data from the memory map 
    spi_wr_data_p,                  // OUTPUT - 16 bits - data to the memory map
    spi_wr_addr_p,                  // INTPUT - 16 bits - address to which data needs to be written to in the Memory Map    
    spi_rd_addr_p,                  // INPUT  - 16 bits - address from which data needs to be obtained from
    spi_initial,                    // INPUT  -  1 bit  - TB control
    spi_command_p                   // INPUT  - 16 bits - command for receiving sd card data
    );
    
    input               clk210_p;
    input               reset_p;
    input               spi_miso_p;   
    input               spi_wr_data_p;
    input               spi_wr_addr_p;
    input               spi_rd_addr_p;
    input               spi_initial;
    input               spi_command_p;
    
    output              spi_mosi_p;
    output              spi_ss_p;
    output              spi_sck_p;
    output              spi_rd_data_s;
    output              spi_state_s;
    
    //-----------------------------------------------------------------------//
    // variable declaration
    //-----------------------------------------------------------------------//
    
    // formal variable declarations
    wire        [15:0]  spi_rd_addr_p;
    wire        [15:0]  spi_wr_addr_p;
    wire        [15:0]  spi_wr_data_p;
    reg         [15:0]  spi_rd_data_s;

    wire        [15:0]  spi_command_p;

    // variables used in the module
    reg                 spi_init_trans_s        =  1'b0;
    wire        [15:0]  spi_htransfer_in_s;
    reg         [15:0]  spi_htransfer_out_s     = 16'd0;
    wire                spi_word_done_p;
    wire                spi_init_trans_p;
    
    reg         [ 7:0]  spi_state_s             =  8'd0;
    reg         [ 7:0]  spi_next_state_s        =  8'd0;
    
    reg                 spi_ss_s                = 1'b0;
    
    reg         [15:0]  spi_sd_fifo_received_s  = 16'b0;
    
    // memory map related tasks
    //reg         [15:0]  spi_rd_addr_p= 16'd0;
    //reg         [15:0]  spi_wr_addr_s= 16'd0;
    //reg         [15:0]  spi_wr_data_s= 16'd0;
    
    //-----------------------------------------------------------------------//
    // output assignments
    //-----------------------------------------------------------------------//
    assign      spi_init_trans_p        = spi_init_trans_s;
    assign      spi_ss_p                = spi_ss_s;
    
    //-----------------------------------------------------------------------//
    // Parameters
    //-----------------------------------------------------------------------//
    
    // State Machine
    parameter   [ 7:0]  IDLE_st                 = 8'd0;
    parameter   [ 7:0]  WAIT_FOR_TRANS_END_st   = 8'd1;
    parameter   [ 7:0]  DECODE_STRT_COMMAND_st  = 8'd2;
    parameter   [ 7:0]  DECODE_TFR_COMMAND_st   = 8'd3;
    parameter   [ 7:0]  DECODE_WRITE_ADDR_st    = 8'd4;
    parameter   [ 7:0]  DECODE_READ_ADDR_st     = 8'd5;
    parameter   [ 7:0]  SEND_STOP_TOKEN_st      = 8'd6;
    parameter   [ 7:0]  INITIATE_TRANSFER_st    = 8'd7;
    parameter   [ 7:0]  GET_DATA_FROM_MEM_MAP_st= 8'd8;
    parameter   [ 7:0]  WRITE_DATA_TO_MEM_MAP_st= 8'd9;
    parameter   [ 7:0]  DELAY_ONE_CLOCK_st      = 8'd10;
    parameter   [ 7:0]  RECEIVE_SD_DATA_WAIT_st = 8'd20;
    parameter   [ 7:0]  RECEIVE_SD_DATA_st      = 8'd21;
    
    // Constants
    parameter   [15:0]  START_COMMAND_c         = 16'd1;
    parameter   [15:0]  WRITE_REG_COMMAND_c     = 16'd2;
    parameter   [15:0]  READ_REG_COMMAND_c      = 16'd3;
    parameter   [15:0]  READ_FLASH_COMMAND_c    = 16'd4;
    parameter   [15:0]  SUCCESSFUL_TRANSFER_c   = 16'd20;
    parameter   [15:0]  UNSUCCESSFUL_TRANSFER_c = 16'd27;
    parameter   [15:0]  RECEIVE_ACK_c           = 16'd21;
    parameter   [15:0]  STOP_TOKEN_c            = 16'd22;
    parameter   [15:0]  SD_READ_REG_COMMAND_1_c = 16'd5;
    parameter   [15:0]  SD_READ_REG_COMMAND_2_c = 16'd6;
    
    //-----------------------------------------------------------------------//
    // Module declarations (need to be fixed)
    //-----------------------------------------------------------------------//
    TB_BBB_SPI_Word_Transfer  word_transfer_inst(
    .clk210_p           (clk210_p),                 // INPUT  -  1 bit  - 210 MHz clock
    .reset_p            (reset_p),                  // INPUT  -  1 bit  - reset 
    .spi_mosi_p         (spi_mosi_p),               // OUTPUT  -  1 bit  - MOSI
    .spi_miso_p         (spi_miso_p),               // INPUT -  1 bit  - MISO
    .spi_ss_p           (spi_ss_p),                 // INPUT  -  1 bit  - Slave Select
    .spi_sck_p          (spi_sck_p),                // OUTPUT  -  1 bit  - SCK
    .spi_ltransfer_in_p (spi_htransfer_in_s),       // OUTPUT - 16 bits - Data transfered in from FC
    .spi_ltransfer_out_p(spi_htransfer_out_s),      // INPUT  - 16 bits - Data transfered to FC
    .spi_init_trans_p   (spi_init_trans_p),         // INPUT  -  1 bit  - signal to initiate transaction
    .spi_word_done_p    (spi_word_done_p)           // OUTPUT -  1 bit  - word is done transfering
    );
    
    //-----------------------------------------------------------------------//
    // STATE MACHINE: This SM will control the lower module, SPI_Word_Transfer.
    // When SS is pulled low, this SM initiates the Word Tranfer to receive a
    // word. This word is decoded and when the START COMMAND is received, it
    // moves to the READ/WRITE command. Next, it receives 16 bits of address
    // information. This address points to the memory map and data that needs
    // to be transfered via SPI is received from the memory map.
    // STATE MAP:
    // IDLE_st --> INITIATE_TRANSFER_st --> WAIT_FOR_TRANS_END_st  --> DECODE_STRT_COMMAND_st --> DECODE_TFR_COMMAND_st
    //                                                              IDLE_st <--|(if no start detected)      |--> DECODE_READ_ADDR_st (if read command)  --> GET_DATA_FROM_MEM_MAP_st
    //                                                                                                      |--> DECODE_WRITE_ADDR_st(if write command) --> GET_WRITE_DATA_st
    //                                                              IDLE_st <-- (if wrong command seen)  <--|
    //-----------------------------------------------------------------------// 
    always @(posedge clk210_p)
    begin
        if (reset_p == 1) begin
            spi_state_s             <= IDLE_st;
            spi_ss_s                <= 1'b1;
            end
        else begin
            
            case (spi_state_s)
            
                // Wait for the slave select pin to go low (redundant step). The SM will then move to 
                // the initiate transfer stage
                IDLE_st: begin
                        if (spi_initial == 1'b1) begin
                            spi_ss_s            <= 1'b0;
                            spi_htransfer_out_s <= START_COMMAND_c;                          
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_next_state_s    <= DECODE_STRT_COMMAND_st;  
                            end
                        else begin
                            spi_state_s         <= IDLE_st;
                        end
                    end
                   
                // This state will initiate the Word transfer
                INITIATE_TRANSFER_st: begin
                        spi_init_trans_s    <= 1'b1;
                        spi_state_s         <= WAIT_FOR_TRANS_END_st;
                    end
                    
                // This state will be visited any time a transaction is initiated. 
                // It will check what the last SPI state was and based on the last state 
                // it will decide what the next state needs to be.
                WAIT_FOR_TRANS_END_st: begin
                        if (spi_word_done_p == 1'b1) begin
                            spi_init_trans_s    <= 1'b0;
                            spi_state_s         <= spi_next_state_s;
                            end
                        else begin
                            spi_state_s         <= WAIT_FOR_TRANS_END_st;
                        end
                    end
                    
                // Wait for the transfer to be completed. Here, decode the command. It needs to be the
                // Start Command. Else, send an error in the next transmission and have the next state
                // be IDLE_st
                DECODE_STRT_COMMAND_st: begin
                        if (spi_htransfer_in_s  == 16'b0) begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            if(spi_command_p == 16'd5) begin
                                spi_htransfer_out_s <= spi_command_p;
                                spi_next_state_s    <= RECEIVE_SD_DATA_WAIT_st;
                                end
                            else begin
                                spi_htransfer_out_s <= spi_command_p;
                                spi_next_state_s    <= DECODE_TFR_COMMAND_st;
                                end
                            end
                        else begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s <= UNSUCCESSFUL_TRANSFER_c;
                            spi_next_state_s    <= IDLE_st;
                            end
                        end
                    
                // This state decodes the transfer command - If it is a read command or a write command.
                DECODE_TFR_COMMAND_st: begin
                        if (spi_htransfer_in_s  == SUCCESSFUL_TRANSFER_c) begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            if(spi_command_p == 16'd3) begin
                                spi_htransfer_out_s <= spi_rd_addr_p;
                                spi_next_state_s    <= DECODE_READ_ADDR_st;
                                end
                            else begin
                                spi_htransfer_out_s <= spi_wr_addr_p;
                                spi_next_state_s    <= DECODE_WRITE_ADDR_st;
                                end
                        end
                        else begin 
                            // none of the above have been detected. Go to the IDLE_st and wait for 
                            // transmissions to restart. Send the host the error message
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s <= UNSUCCESSFUL_TRANSFER_c;
                            spi_next_state_s    <= IDLE_st;
                        end
                    end
                    
                DECODE_READ_ADDR_st: begin
                    spi_state_s                     <= DELAY_ONE_CLOCK_st;
                    end
                DELAY_ONE_CLOCK_st : begin
                    spi_state_s                     <= GET_DATA_FROM_MEM_MAP_st;
                    end
                GET_DATA_FROM_MEM_MAP_st: begin
                    spi_htransfer_out_s             <= 1'b0;
                    spi_state_s                     <= INITIATE_TRANSFER_st;
                    spi_next_state_s                <= SEND_STOP_TOKEN_st;
                    end
					
                    
                DECODE_WRITE_ADDR_st: begin
                    spi_htransfer_out_s             <= spi_wr_data_p;
                    spi_state_s                     <= INITIATE_TRANSFER_st;
                    spi_next_state_s                <= SEND_STOP_TOKEN_st;
                    end
                    
                /*WRITE_DATA_TO_MEM_MAP_st: begin
                    spi_next_state_s                <= SEND_STOP_TOKEN_st;
                    end*/
                    
                RECEIVE_SD_DATA_WAIT_st: begin
                    spi_state_s                     <= INITIATE_TRANSFER_st;
                    if(spi_htransfer_in_s == SUCCESSFUL_TRANSFER_c) begin
                        spi_next_state_s            <= RECEIVE_SD_DATA_st;
                        end
                    else begin
                        spi_next_state_s            <= SEND_STOP_TOKEN_st;
                        end
                    end
                    
                RECEIVE_SD_DATA_st: begin
                    spi_rd_data_s                   <= spi_htransfer_in_s;
                    spi_htransfer_out_s             <= 1'b0;
                    spi_state_s                     <= INITIATE_TRANSFER_st;
                    spi_sd_fifo_received_s          <= spi_sd_fifo_received_s + 1;
                    if(spi_sd_fifo_received_s < 508) begin
                        spi_next_state_s            <= RECEIVE_SD_DATA_st;
                        end
                    else begin
                        spi_sd_fifo_received_s      <= 16'b0;
                        spi_next_state_s            <= SEND_STOP_TOKEN_st;
                    end
                    if(spi_htransfer_in_s == UNSUCCESSFUL_TRANSFER_c) begin
                        spi_next_state_s            <= SEND_STOP_TOKEN_st;
                        end
                    end
                    
                SEND_STOP_TOKEN_st: begin
                    spi_rd_data_s                   <= spi_htransfer_in_s;
                    spi_htransfer_out_s             <= 1'b0;
                    spi_state_s                     <= INITIATE_TRANSFER_st;
                    spi_next_state_s                <= IDLE_st;
                    end
                    
                default: begin
                    spi_state_s                     <= IDLE_st;
                    spi_next_state_s                <= IDLE_st;
                    end
                endcase
                end
            
        end   
    
endmodule

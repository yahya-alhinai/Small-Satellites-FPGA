`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2017 10:02:13 PM
// Design Name: 
// Module Name: FC_intfc_SPI_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is an SPI Slave Controller that operates at a frequency of
// 105 MHz and has a built in CDR that is capable of communicating with a master 
// at speeds upto 25 MHz. 
// Bit width : 16 bits 
// CPOL      : 0
// NCPHA     : 1 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// `define DEBUGGING_MODE     // Use this mode to send random SD Card data to the Flight Computer
`define NORMAL_MODE        // Use this mode to send the correct SD Card data to the FC
module FC_intfc_SPI_controller(
    clk210_p,                       // INPUT  -  1 bit  - 105 MHz clock
    reset_p,                        // INPUT  -  1 bit  - reset
    spi_mosi_p,                     // INPUT  -  1 bit  - MOSI from the FC (FC is the master)
    spi_miso_p,                     // OUTPUT -  1 bit  - MISO to the FC (remember that the FC is the master
    spi_ss_p,                       // INPUT  -  1 bit  - FC slave select
    spi_sck_p,                      // INPUT  -  1 bit  - SCK from the FC
    memory_map_spi_rd_data_p,       // INPUT  - 16 bits - data from the memory map 
    memory_map_spi_wr_data_p,       // OUTPUT - 16 bits - data to the memory map
    memory_map_spi_wr_addr_p,       // OUTPUT - 16 bits - address to which data needs to be written to in the Memory Map    
    memory_map_spi_rd_addr_p,       // OUTPUT - 16 bits - address from which data needs to be obtained from
    memory_map_spi_wr_en_p,         // OUTPUT -  1 bit  - write enable to the memory map
    memory_map_spi_rd_en_p,         // OUTPUT -  1 bit  - read enable to the memory map
    fc_fifo_tx_ready_p,             // INPUT  -  1 bit  - indicates that the FC FIFO is full (at the limit that FC wants which is why the full flag is not used instead)
    fc_fifo_tx_rd_en_p,             // OUTPUT -  1 bit  - read enable to the fifo
    fc_fifo_tx_dout_p,              // INPUT  - 16 bits - data output bus from the fifo
    fc_fifo_tx_empty_p,             // INPUT  -  1 bit  - empty flag from the fifo
    fc_fifo_num_transfers_p,        // OUTPUT - 16 bits - fifo counter used for indication whether there is an slave select glitch
    fc_sd_shutdown_cmd_p
    );
    
    input               clk210_p;
    input               reset_p;
    input               spi_mosi_p;
    input               spi_ss_p;
    input               spi_sck_p;
    input               memory_map_spi_rd_data_p;
    input               fc_fifo_tx_ready_p;
    input               fc_fifo_tx_empty_p;
    input               fc_fifo_tx_dout_p;
    
    output              spi_miso_p;
    output              memory_map_spi_rd_en_p;
    output              memory_map_spi_wr_en_p;
    output              memory_map_spi_wr_data_p;
    output              memory_map_spi_wr_addr_p;
    output              memory_map_spi_rd_addr_p;
    output              fc_fifo_tx_rd_en_p;    
    output              fc_fifo_num_transfers_p;
    output              fc_sd_shutdown_cmd_p;
    
    //-----------------------------------------------------------------------//
    // variable declaration
    //-----------------------------------------------------------------------//
    
    // formal variable declarations
    wire                memory_map_spi_rd_en_p;  
    wire                memory_map_spi_wr_en_p;  
    wire        [15:0]  memory_map_spi_rd_addr_p;
    wire        [15:0]  memory_map_spi_wr_addr_p;
    wire        [15:0]  memory_map_spi_wr_data_p;
    wire        [15:0]  memory_map_spi_rd_data_p;

    // variables used in the module
    reg                 spi_init_trans_s        =  1'b0;
    wire        [15:0]  spi_htransfer_in_s;
    reg         [15:0]  spi_htransfer_out_s     = 16'd0;
    wire                spi_word_done_p;
    wire                spi_init_trans_p;
    
    reg         [ 7:0]  spi_state_s             =  8'd0;
    reg         [ 7:0]  spi_next_state_s        =  8'd0;
    
    // memory map related tasks
    reg                 memory_map_spi_rd_en_s  =  1'b0;
    reg                 memory_map_spi_wr_en_s  =  1'b0;
    reg         [15:0]  memory_map_spi_rd_addr_s= 16'd0;
    reg         [15:0]  memory_map_spi_wr_addr_s= 16'd0;
    reg         [15:0]  memory_map_spi_wr_data_s= 16'd0;
    
    // FC TX FIFO Related
    reg                 fc_fifo_tx_rd_en_s      = 1'b0;
    wire                fc_fifo_tx_rd_en_p;    
    wire        [15:0]  fc_fifo_tx_dout_p;
    wire                fc_fifo_tx_ready_p;
    wire        [15:0]  fc_fifo_num_transfers_p;
    reg         [15:0]  fc_fifo_num_transfers_s = 16'd0;
    
    //Shutdown command for SD card
    reg                 fc_sd_shutdown_cmd_s    = 1'b0;
    
    // Debugging mode sd card data
    reg         [15:0]  sd_card_rand_data_s     = 16'd0;
    
    //-----------------------------------------------------------------------//
    // output assignments
    //-----------------------------------------------------------------------//
    assign      spi_init_trans_p        = spi_init_trans_s; 
    assign      memory_map_spi_rd_en_p  = memory_map_spi_rd_en_s;
    assign      memory_map_spi_wr_en_p  = memory_map_spi_wr_en_s;
    assign      memory_map_spi_rd_addr_p= memory_map_spi_rd_addr_s;
    assign      memory_map_spi_wr_addr_p= memory_map_spi_wr_addr_s;
    assign      memory_map_spi_wr_data_p= memory_map_spi_wr_data_s;
    assign      fc_fifo_tx_rd_en_p      = fc_fifo_tx_rd_en_s;
    assign      fc_fifo_num_transfers_p = fc_fifo_num_transfers_s;
    assign      fc_sd_shutdown_cmd_p    = fc_sd_shutdown_cmd_s;
    
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
    parameter   [ 7:0]  CHECK_FC_TX_FIFO_st     = 8'd11;
    parameter   [ 7:0]  SDCARD_FC_SERVICE_st    = 8'd12;    
    parameter   [ 7:0]  PULL_DOWN_RD_EN_st      = 8'd13;
    parameter   [ 7:0]  TRANSFER_DATA_st        = 8'd14;
        
    // Constants
    parameter   [15:0]  START_COMMAND_c         = 16'd1;
    parameter   [15:0]  WRITE_REG_COMMAND_c     = 16'd2;
    parameter   [15:0]  READ_REG_COMMAND_c      = 16'd3;
    parameter   [15:0]  READ_FLASH_COMMAND_c    = 16'd4;
    parameter   [15:0]  SUCCESSFUL_TRANSFER_c   = 16'd20;
    parameter   [15:0]  UNSUCCESSFUL_TRANSFER_c = 16'd27;
    parameter   [15:0]  FIFO_NOT_READY_c        = 16'd28;
    parameter   [15:0]  SHUTDOWN_COMMAND_c      = 16'd83;
    parameter   [15:0]  RECEIVE_ACK_c           = 16'd21;
    parameter   [15:0]  STOP_TOKEN_c            = 16'd22;
    parameter   [15:0]  SD_READ_REG_COMMAND_c   = 16'd5;
    
    //-----------------------------------------------------------------------//
    // Module declarations
    //-----------------------------------------------------------------------//
    FC_intfc_SPI_Word_Transfer  word_transfer_inst(
    .clk210_p           (clk210_p),                 // INPUT  -  1 bit  - 105 MHz clock
    .reset_p            (reset_p),                  // INPUT  -  1 bit  - reset 
    .spi_mosi_p         (spi_mosi_p),               // INPUT  -  1 bit  - MOSI
    .spi_miso_p         (spi_miso_p),               // OUTPUT -  1 bit  - MISO
    .spi_ss_p           (spi_ss_p),                 // INPUT  -  1 bit  - Slave Select
    .spi_sck_p          (spi_sck_p),                // INPUT  -  1 bit  - SCK
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
            memory_map_spi_rd_en_s  <= 1'b0;
            memory_map_spi_wr_en_s  <= 1'b0;
            fc_fifo_num_transfers_s <= 16'd0;
            fc_sd_shutdown_cmd_s    <= 1'b0;
            end
        else begin
        
        // If at any point SS goes high during a transaction, the state machine will return to the IDLE state and 
        // will reset all communications. The master will need to start at the beginning again and cannot resume
        // where it left off.
            if (spi_ss_p == 1'b0) begin
            
                case (spi_state_s)
                
                // Wait for the slave select pin to go low (redundant step). The SM will then move to 
                // the initiate transfer stage
                IDLE_st: begin
                        if (spi_ss_p == 1'b0) begin
                            spi_htransfer_out_s <= 16'd0; 
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
                            spi_init_trans_s        <= 1'b0;
                            spi_state_s             <= spi_next_state_s;
                            memory_map_spi_rd_en_s  <= 1'b0;
                            memory_map_spi_wr_en_s  <= 1'b0;
                            end
                        else begin
                            spi_state_s             <= WAIT_FOR_TRANS_END_st;
                            memory_map_spi_rd_en_s  <= 1'b0;
                            memory_map_spi_wr_en_s  <= 1'b0;
                        end
                    end
                
                // Wait for the transfer to be completed. Here, decode the command. It needs to be the
                // Start Command. Else, send an error in the next transmission and have the next state
                // be IDLE_st
                DECODE_STRT_COMMAND_st: begin
                        if (spi_htransfer_in_s  == START_COMMAND_c) begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s <= SUCCESSFUL_TRANSFER_c;
                            spi_next_state_s    <= DECODE_TFR_COMMAND_st;
                            end
                        else begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s <= UNSUCCESSFUL_TRANSFER_c;
                            spi_next_state_s    <= IDLE_st;
                        end
                    end
                    
                // This state decodes the transfer command - If it is a read command or a write command. Currently implementing a shutdown command as well.
                DECODE_TFR_COMMAND_st: begin
                        if (spi_htransfer_in_s == SHUTDOWN_COMMAND_c) begin
                           spi_state_s        <= INITIATE_TRANSFER_st;
                           spi_htransfer_out_s<= SUCCESSFUL_TRANSFER_c;
                           fc_sd_shutdown_cmd_s <= 1'b1;
                           spi_next_state_s   <= IDLE_st;
                           end
                        if (spi_htransfer_in_s  == READ_REG_COMMAND_c) begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s <= SUCCESSFUL_TRANSFER_c;
                            spi_next_state_s    <= DECODE_READ_ADDR_st;
                            end
                        else if (spi_htransfer_in_s == WRITE_REG_COMMAND_c) begin
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s <= SUCCESSFUL_TRANSFER_c;
                            spi_next_state_s    <= DECODE_WRITE_ADDR_st;
                            end
                        else if (spi_htransfer_in_s == SD_READ_REG_COMMAND_c) begin
                            spi_state_s         <= CHECK_FC_TX_FIFO_st;
                            end
                        else begin 
                            // none of the above have been detected. Go to the IDLE_st and wait for 
                            // transmissions to restart. Send the host the error message
                            //spi_state_s         <= IDLE_st;
                            //spi_next_state_s    <= IDLE_st;
                            //spi_htransfer_out_s <= UNSUCCESSFUL_TRANSFER_c;
                            
                            spi_htransfer_out_s <= UNSUCCESSFUL_TRANSFER_c;
                            spi_state_s         <= INITIATE_TRANSFER_st;
                            spi_next_state_s    <= IDLE_st;
                        end
                    end
                
                // Here the read command's following statements are executed. Get the adddress of the register
                // that will be read.
                DECODE_READ_ADDR_st: begin
                        memory_map_spi_rd_addr_s    <= spi_htransfer_in_s;
                        memory_map_spi_rd_en_s      <= 1'b1;
                        spi_state_s                 <= DELAY_ONE_CLOCK_st;
                    end
                    
                DELAY_ONE_CLOCK_st: begin
                        spi_state_s                 <= GET_DATA_FROM_MEM_MAP_st;
                    end
                    
                // Get the data corresponding to the read address and transfer it out.
                GET_DATA_FROM_MEM_MAP_st: begin
                        spi_htransfer_out_s         <= memory_map_spi_rd_data_p;
                        spi_state_s                 <= INITIATE_TRANSFER_st;
                        spi_next_state_s            <= SEND_STOP_TOKEN_st;
                    end
                    
                // Here the write command's following statements are executed. Get the address of the register to be written to
                DECODE_WRITE_ADDR_st: begin
                        memory_map_spi_wr_addr_s    <= spi_htransfer_in_s;
                        spi_state_s                 <= INITIATE_TRANSFER_st;
                        spi_htransfer_out_s         <= SUCCESSFUL_TRANSFER_c;
                        spi_next_state_s            <= WRITE_DATA_TO_MEM_MAP_st;
                    end
                    
                // Write the data to the memory map
                WRITE_DATA_TO_MEM_MAP_st: begin
                        memory_map_spi_wr_data_s    <= spi_htransfer_in_s;
                        memory_map_spi_wr_en_s      <= 1'b1;
                        spi_state_s                 <= SEND_STOP_TOKEN_st;
                    end
                
                `ifdef NORMAL_MODE
                
                    // Here, the state machine checks to see if the TX_FIFO has the amount of data that the FC team can handle.
                    // This threshold is set from the higher level module.
                    CHECK_FC_TX_FIFO_st: begin
                            if (fc_fifo_tx_ready_p == 1'b0) begin // FIFO is not full to the extent the FC wants it to be
                                spi_state_s             <= INITIATE_TRANSFER_st;
                                spi_htransfer_out_s     <= FIFO_NOT_READY_c;
                                spi_next_state_s        <= IDLE_st;
                                end
                            else if (fc_fifo_tx_ready_p == 1'b1) begin
                                spi_state_s             <= INITIATE_TRANSFER_st;
                                spi_htransfer_out_s     <= SUCCESSFUL_TRANSFER_c;
                                spi_next_state_s        <= SDCARD_FC_SERVICE_st;
                                end
                            else begin              // Meta stable state? not sure - just added this error out condition
                                spi_state_s             <= INITIATE_TRANSFER_st;
                                spi_htransfer_out_s     <= SUCCESSFUL_TRANSFER_c;
                                spi_next_state_s        <= SDCARD_FC_SERVICE_st;
                            end
                        end
                        
                    // This state is where the FPGA will transfer data from the FC TX FIFO into the FC    
                    SDCARD_FC_SERVICE_st: begin
                            if (fc_fifo_num_transfers_s >= 16'd500) begin       // check to see that the FIFO is not empty
                                spi_state_s             <= SEND_STOP_TOKEN_st;
                                fc_fifo_num_transfers_s <= 16'd0;
                                end
                            else begin
                                fc_fifo_tx_rd_en_s      <= 1'b1;
                                spi_state_s             <= PULL_DOWN_RD_EN_st;
                                fc_fifo_num_transfers_s <= fc_fifo_num_transfers_s + 16'd1;
                            end
                        end
                
                `endif
                
                `ifdef DEBUGGING_MODE
                
                    CHECK_FC_TX_FIFO_st: begin
                            spi_state_s             <= INITIATE_TRANSFER_st;
                            spi_htransfer_out_s     <= SUCCESSFUL_TRANSFER_c;
                            spi_next_state_s        <= SDCARD_FC_SERVICE_st;
                        end
                        
                    SDCARD_FC_SERVICE_st: begin
                            if (sd_card_rand_data_s < 16'd512) begin
                                spi_htransfer_out_s <= sd_card_rand_data_s;
                                sd_card_rand_data_s <= sd_card_rand_data_s + 1'b1;
                                spi_state_s         <= INITIATE_TRANSFER_st;
                                spi_next_state_s    <= SDCARD_FC_SERVICE_st;
                                end
                            else begin
                                spi_state_s             <= SEND_STOP_TOKEN_st;
                                sd_card_rand_data_s     <= 16'd0;
                            end
                        end
                            
                `endif
                
                // FIFO's RD enable signal needs to be set only for 1 clock cycle
                PULL_DOWN_RD_EN_st: begin
                        fc_fifo_tx_rd_en_s          <= 1'b0;
                        spi_state_s                 <= TRANSFER_DATA_st;
                    end
                    
                // transfer the actual data    
                TRANSFER_DATA_st: begin
                        spi_htransfer_out_s         <= fc_fifo_tx_dout_p;
                        spi_state_s                 <= INITIATE_TRANSFER_st;
                        spi_next_state_s            <= SDCARD_FC_SERVICE_st;
                    end
                            
                
                // Send an acknowledgement stop token at the end of the command
                // cycle
                SEND_STOP_TOKEN_st: begin
                        spi_htransfer_out_s         <= STOP_TOKEN_c;
                        spi_state_s                 <= INITIATE_TRANSFER_st;
                        spi_next_state_s            <= IDLE_st;
                    end
                    
                default:
                    spi_state_s     <= IDLE_st;
                endcase
                end
                
            else begin  // If the ss is pulled low anytime
                spi_state_s         <= IDLE_st;
                spi_next_state_s    <= IDLE_st;
            end
            
        end
    end
    
    
endmodule

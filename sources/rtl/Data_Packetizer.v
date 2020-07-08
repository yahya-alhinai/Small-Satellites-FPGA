`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/04/2017 01:51:56 PM
// Design Name: 
// Module Name: Data_Packetizer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This file creates a module that will be used to packetize data from
//      all the channels and store it into the SD Card's write FIFO. The reason this 
//      module is required is, we need a section of code that will save channel information
//      and also appends a barker code (Start Token) to each of the packets.
//      Since there are multiple channels, we'll need a central facilitating unit to take 
//      care of all of this and this is precisely what this module does.
//      Note that there are two modes in this module:
//      SAVE_PREPROCESSING_DATA: This mode saves the preprocessed data to the FIFO.
//      SAVE_PROCESSED_DATA: This mode saves the processed data to the FIFO.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// `define SAVE_PREPROCESSING_DATA
`define SAVE_PROCESSED_DATA

module Data_Packetizer(
    clk210_p,                       // INPUT  -  1 bit  - 210 MHz clock
    reset_p,                        // INPUT  -  1 bit  - reset
    `ifdef SAVE_PREPROCESSING_DATA
    fifo_adc_1_rd_en_p,             // OUTPUT -  1 bit  - read enable to the FIFO
    fifo_adc_1_data_count_p,        // INPUT  - 10 bits - FIFO data count    
    fifo_adc_1_dout_p,              // INPUT  - 80 bits - FIFO data output
    `endif
    `ifdef SAVE_PROCESSED_DATA
    fifo_processing_1_rd_en_p,      // OUTPUT -  1 bit  - read enable to the processing FIFO
    fifo_processing_1_data_count_p, // INPUT  - 10 bits - FIFO data count
    fifo_processing_1_dout_p,       // INPUT  - 88 bits - FIFO data output 
    `endif
    sd_write_fifo_din_p,            // OUTPUT -  8 bits - FIFO data in bus for the SD Card    
    sd_write_fifo_wr_en_p,          // OUTPUT -  1 bit  - FIFO write enable
    sd_write_fifo_full_p            // INPUT  -  1 bit  - Indicates that the FIFO is full
    );
    
    input               clk210_p;
    input               reset_p;
    
    `ifdef SAVE_PREPROCESSING_DATA
    input               fifo_adc_1_data_count_p;
    input               fifo_adc_1_dout_p;
    output              fifo_adc_1_rd_en_p;
    `endif
    
    `ifdef SAVE_PROCESSED_DATA
    input               fifo_processing_1_data_count_p;
    input               fifo_processing_1_dout_p;
    output              fifo_processing_1_rd_en_p;
    `endif
    
    input               sd_write_fifo_full_p;
    output              sd_write_fifo_din_p;
    output              sd_write_fifo_wr_en_p;
    
    //-----------------------------------------------------------------------//
    // Variable Declarations
    //-----------------------------------------------------------------------//
    wire        [79:0]  fifo_adc_1_dout_p;
    wire        [10:0]  fifo_adc_1_data_count_p;
    
    wire       [107:0]  fifo_processing_1_dout_p;
    wire        [ 9:0]  fifo_processing_1_data_count_p;
    wire                fifo_processing_1_rd_en_p;
    reg                 fifo_processing_1_rd_en_s = 1'b0;
    
    reg                 fifo_adc_1_rd_en_s      =  1'b0;
    reg         [ 7:0]  packetizer_state_s      =  8'd0;
    reg         [ 7:0]  packetizer_nxt_state_s  =  8'd0;
    reg         [ 7:0]  channel_info_s          =  8'd0;   
    reg         [ 7:0]  byte_len_pkt_buf_s[0:15];       // This is an 8 bit wide, 16 byte deep buffer
                                                        // It will be associated with a Start Token (Barker Code)
                                                        // as the first byte and the remainder of the bytes contain the
                                                        // time stamp and the ADC Data value.
    reg        [107:0]  data_packet_s           =108'd0;
    reg         [ 7:0]  data_packet_index_s     =  8'd0;// This is used to index the byte_len_pkt_buf_s array
    wire        [ 7:0]  sd_write_fifo_din_p;
    reg         [ 7:0]  sd_write_fifo_din_s     =  8'd0;
    wire                sd_write_fifo_full_p;
    wire                sd_write_fifo_wr_en_p;
    reg                 sd_write_fifo_wr_en_s   =  1'b0;
    
    //-----------------------------------------------------------------------//
    // Parameter Declarations for packetizer_state_s for the preprocessed
    // processed data. Note that it might be confusing since we're using the same
    // variables for both the data sets. This was done to prevent multiple variables
    // that do the same thing. The `defines define which set of data is packetized.
    //-----------------------------------------------------------------------//
    parameter   [ 7:0]  CHECK_FIFO_1_st             = 8'd0;  
    parameter   [ 7:0]  READ_A_LINE_st              = 8'd1;  
    parameter   [ 7:0]  PULL_DOWN_RD_EN_st          = 8'd2;    
    parameter   [ 7:0]  ASSIGN_TO_BYTE_BUFFER_st    = 8'd3;        
    parameter   [ 7:0]  TFR_TO_SD_WRITE_FIFO_st     = 8'd4;
    parameter   [ 7:0]  PULL_UP_SD_FIFO_WR_EN_st    = 8'd5;
    parameter   [ 7:0]  PULL_DWN_SD_FIFO_WR_EN_st   = 8'd6;
    
    //-----------------------------------------------------------------------//
    // other parameters
    //-----------------------------------------------------------------------//
    parameter   [ 7:0]  BARKER_CODE_c           = 8'hF1;    // More research into how to choose this number is needed.
                                                            // This denotes the start of a packet.
    
    //-----------------------------------------------------------------------//
    // Output assignments
    //-----------------------------------------------------------------------//
    assign  fifo_adc_1_rd_en_p          = fifo_adc_1_rd_en_s;
    assign  sd_write_fifo_wr_en_p       = sd_write_fifo_wr_en_s;
    assign  sd_write_fifo_din_p         = sd_write_fifo_din_s;
    assign  fifo_processing_1_rd_en_p   = fifo_processing_1_rd_en_s;
    
    `ifdef SAVE_PREPROCESSING_DATA
    //-----------------------------------------------------------------------//
    // State Machine to store all the preprocessed data from all the channels
    // to the SD Card - Currently has only 1 channel's worth of data but it can 
    // be expanded to all 8 channels
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            packetizer_state_s      <= 8'd0;
            fifo_adc_1_rd_en_s      <= 1'b0;
            data_packet_index_s     <= 8'd0;
            sd_write_fifo_wr_en_s   <= 1'b0;
            sd_write_fifo_din_s     <= 8'd0;
            packetizer_nxt_state_s  <= 8'd0;
            end
        else begin
            case (packetizer_state_s) 
            
            // Check to see if there is any data available in the first fifo
            CHECK_FIFO_1_st: begin
                    if (fifo_processing_1_data_count_p > 0) begin
                        channel_info_s      <= 8'd1;
                          <= 1'b1;
                        packetizer_state_s  <= PULL_DOWN_RD_EN_st;
                        packetizer_nxt_state_s  <= CHECK_FIFO_1_st;
                        end
                    else begin
                        packetizer_state_s  <= CHECK_FIFO_1_st;         // Change this to FIFO2 when there are more than one channel being used
                                                                        // obviously make sure the final implementation with 8 channels does not
                                                                        // have some kind of a preference order. A simple IF ELSE statement will
                                                                        // give the first IF statement preference.
                    end
                end
            
            // Pull Down read enable
            PULL_DOWN_RD_EN_st: begin
                    fifo_adc_1_rd_en_s      <= 1'b0;
                    packetizer_state_s      <= READ_A_LINE_st;
                end
            
            // This state is recached after every Check_FIFO state if there was data in any of the FIFOs
            // The Case statement tells which was the last state and the assignment is made
            // accordingly.
            READ_A_LINE_st: begin
                    case(channel_info_s)
                    8'd1: begin
                            data_packet_s       <= {28'd0, fifo_adc_1_dout_p};  // The reason to have the 0s is because the same variables
                                                                                // is used for the processed data as well.
                        end
                    default: begin
                            data_packet_s       <= {28'd0, fifo_adc_1_dout_p};
                        end
                    endcase
                    packetizer_state_s      <= ASSIGN_TO_BYTE_BUFFER_st;
                end                   
                
            // Here, we assign the 80 bit packet from the preprocesser to the byte_len_pkt_buf_s
            ASSIGN_TO_BYTE_BUFFER_st: begin
                    byte_len_pkt_buf_s[ 0]  <= BARKER_CODE_c;               // Barker code
                    byte_len_pkt_buf_s[ 1]  <= channel_info_s;              // Channel info
                    byte_len_pkt_buf_s[ 2]  <= data_packet_s[79:72];        // timestamp
                    byte_len_pkt_buf_s[ 3]  <= data_packet_s[71:64];        // timestamp
                    byte_len_pkt_buf_s[ 4]  <= data_packet_s[63:56];        // timestamp
                    byte_len_pkt_buf_s[ 5]  <= data_packet_s[55:48];        // timestamp
                    byte_len_pkt_buf_s[ 6]  <= data_packet_s[47:40];        // timestamp
                    byte_len_pkt_buf_s[ 7]  <= data_packet_s[39:32];        // timestamp
                    byte_len_pkt_buf_s[ 8]  <= data_packet_s[31:24];        // timestamp
                    byte_len_pkt_buf_s[ 9]  <= data_packet_s[23:16];        // timestamp
                    byte_len_pkt_buf_s[10]  <= data_packet_s[15: 8];        // adc_data
                    byte_len_pkt_buf_s[11]  <= data_packet_s[ 7: 0];        // adc_data
                    packetizer_state_s      <= TFR_TO_SD_WRITE_FIFO_st;
                    data_packet_index_s     <= 0;
                end
    
            // This state is responsible for transfering the data from the the detector top module
            // to the SD Card Write FIFO
            TFR_TO_SD_WRITE_FIFO_st: begin
                    if (~sd_write_fifo_full_p) begin
                        packetizer_state_s      <= PULL_UP_SD_FIFO_WR_EN_st;
                        sd_write_fifo_din_s     <= byte_len_pkt_buf_s[data_packet_index_s];
                        data_packet_index_s     <= data_packet_index_s + 1'b1;
                        end
                    else begin
                        packetizer_state_s      <= TFR_TO_SD_WRITE_FIFO_st;
                    end
                end
    
            // Pull up write enable for a clock cycle
            PULL_UP_SD_FIFO_WR_EN_st: begin
                    sd_write_fifo_wr_en_s   <= 1'b1;
                    packetizer_state_s      <= PULL_DWN_SD_FIFO_WR_EN_st;
                end
                
            // Pull down write enable
            PULL_DWN_SD_FIFO_WR_EN_st: begin
                    sd_write_fifo_wr_en_s   <= 1'b0;
                    if (data_packet_index_s > 8'd11) begin
                        data_packet_index_s <= 8'd0;
                        packetizer_state_s  <= packetizer_nxt_state_s;
                        end
                    else begin
                        packetizer_state_s  <= TFR_TO_SD_WRITE_FIFO_st;
                    end
                end
            
            default: begin
                    packetizer_state_s      <= CHECK_FIFO_1_st;
                end
            
            endcase
        
        end
        
    end
    `endif
    
    `ifdef SAVE_PROCESSED_DATA
    //-----------------------------------------------------------------------//
    // State Machine to store all the processed data from the processing_top
    // module
    // Currently the data packet from the processing fifo is as follows: 
    // {param_a,param_c,error,time_stamp}
    // We will add a barker code and also a channel number to the packet here.
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            packetizer_state_s          <= 8'd0;
            fifo_processing_1_rd_en_s   <= 1'b0;
            data_packet_index_s         <= 8'd0;
            sd_write_fifo_wr_en_s       <= 1'b0;
            sd_write_fifo_din_s         <= 8'd0;
            packetizer_nxt_state_s      <= 8'd0;
            end
        else begin
            case (packetizer_state_s) 
            
            // Check to see if there is any data available in the first fifo
            CHECK_FIFO_1_st: begin
                    if (fifo_processing_1_data_count_p > 0) begin
                        channel_info_s              <= 8'd1;
                        fifo_processing_1_rd_en_s   <= 1'b1;
                        packetizer_state_s          <= PULL_DOWN_RD_EN_st;
                        packetizer_nxt_state_s      <= CHECK_FIFO_1_st;
                        end
                    else begin
                        packetizer_state_s  <= CHECK_FIFO_1_st;         // Change this to FIFO2 when there are more than one channel being used
                    end
                end
            
            // Pull Down read enable
            PULL_DOWN_RD_EN_st: begin
                    fifo_processing_1_rd_en_s       <= 1'b0;
                    packetizer_state_s              <= READ_A_LINE_st;
                end
            
            // This state is recached after every Check_FIFO state if there was data in any of the FIFOs
            // The Case statement tells which was the last state and the assignment is made
            // accordingly.
            READ_A_LINE_st: begin
                    case(channel_info_s)
                    8'd1: begin
                            data_packet_s       <= fifo_processing_1_dout_p;
                        end
                    default: begin
                            data_packet_s       <= fifo_processing_1_dout_p;
                        end
                    endcase
                    packetizer_state_s      <= ASSIGN_TO_BYTE_BUFFER_st;
                end                   
                
            // Here, we assign the 80 bit packet from the preprocesser to the byte_len_pkt_buf_s
            ASSIGN_TO_BYTE_BUFFER_st: begin
                    byte_len_pkt_buf_s[ 0]  <= BARKER_CODE_c;               // Barker code
                    byte_len_pkt_buf_s[ 1]  <= channel_info_s;              // Channel info
                    byte_len_pkt_buf_s[ 2]  <= data_packet_s[107:100];      // param a (16 bits)
                    byte_len_pkt_buf_s[ 3]  <= data_packet_s[ 99: 92];      // param a 
                    byte_len_pkt_buf_s[ 4]  <= data_packet_s[ 91: 84];      // param c (8 bits)
                    byte_len_pkt_buf_s[ 5]  <= {4'd0,data_packet_s[ 83:80]}; // error (20 bits)
                    byte_len_pkt_buf_s[ 6]  <= data_packet_s[ 79:72];       // error
                    byte_len_pkt_buf_s[ 7]  <= data_packet_s[ 71:64];       // error
                    byte_len_pkt_buf_s[ 8]  <= data_packet_s[ 63:56];       // timestamp (64 bits)
                    byte_len_pkt_buf_s[ 9]  <= data_packet_s[ 55:48];       // timestamp
                    byte_len_pkt_buf_s[10]  <= data_packet_s[ 47:40];       // timestamp
                    byte_len_pkt_buf_s[11]  <= data_packet_s[ 39:32];       // timestamp
                    byte_len_pkt_buf_s[12]  <= data_packet_s[ 31:24];       // timestamp
                    byte_len_pkt_buf_s[13]  <= data_packet_s[ 23:16];       // timestamp
                    byte_len_pkt_buf_s[14]  <= data_packet_s[ 15: 8];       // timestamp
                    byte_len_pkt_buf_s[15]  <= data_packet_s[  7: 0];       // timestamp
                    packetizer_state_s      <= TFR_TO_SD_WRITE_FIFO_st;
                    data_packet_index_s     <= 0;
                end
    
            // This state is responsible for transfering the data from the the detector top module
            // to the SD Card Write FIFO
            TFR_TO_SD_WRITE_FIFO_st: begin
                    sd_write_fifo_din_s     <= byte_len_pkt_buf_s[data_packet_index_s];
                    data_packet_index_s     <= data_packet_index_s + 1'b1;
                    if (~sd_write_fifo_full_p) begin
                        packetizer_state_s      <= PULL_UP_SD_FIFO_WR_EN_st;
                        end
                    else begin
                        packetizer_state_s      <= TFR_TO_SD_WRITE_FIFO_st;
                    end
                end
    
            // Pull up write enable for a clock cycle
            PULL_UP_SD_FIFO_WR_EN_st: begin
                    sd_write_fifo_wr_en_s   <= 1'b1;
                    packetizer_state_s      <= PULL_DWN_SD_FIFO_WR_EN_st;
                end
                
            // Pull down write enable
            PULL_DWN_SD_FIFO_WR_EN_st: begin
                    sd_write_fifo_wr_en_s   <= 1'b0;
                    if (data_packet_index_s > 8'd15) begin
                        data_packet_index_s <= 8'd0;
                        packetizer_state_s  <= packetizer_nxt_state_s;
                        end
                    else begin
                        packetizer_state_s  <= TFR_TO_SD_WRITE_FIFO_st;
                    end
                end
            
            default: begin
                    packetizer_state_s      <= CHECK_FIFO_1_st;
                end
            
            endcase
        
        end
        
    end
    `endif
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2017 02:56:43 PM
// Design Name: 
// Module Name: TB_SD_Card_Spi_Slave
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


module TB_SD_Card_Spi_Slave(
    clk_p,
    tb_spi_miso_p,
    tb_spi_mosi_p,
    tb_spi_sck_p,
    tb_spi_ss_p
    );
    
    input               clk_p;
    input               tb_spi_mosi_p;
    input               tb_spi_ss_p;
    input               tb_spi_sck_p;
            
    output              tb_spi_miso_p;
    
    // Variable declarations
    
    reg         [7:0]   tb_data_to_transfer_s       = 8'd0;
    reg                 tb_init_transfer_s          = 1'b0;
    reg         [7:0]   tb_spi_slave_rtrn_state_s   = 8'd0;
    reg         [7:0]   received_bytes_s            = 8'd0;
    reg         [7:0]   response_R1_s               = 8'd0;
    reg         [39:0]  response_R3_s               = 40'd0;
    reg         [39:0]  response_R7_s               = 40'd0;
    reg         [7:0]   tb_spi_slave_state_s        = 8'd0;
    reg         [47:0]  tb_command_s                = 48'd0;
    reg         [7:0]   response_counter_s          = 8'd0;
    wire        [7:0]   tb_spi_data_in_s;
    reg         [15:0]  tb_num_byte_tfers_s         = 16'd0;
    
    // output assignments
    
    
    // Parameters
    parameter   [7:0]   IDLE_st                     = 8'd0;    
    parameter   [7:0]   WAIT_FOR_TRANSMIT_DONE_st   = 8'd1;
    parameter   [7:0]   GET_CMD_st                  = 8'd2;
    parameter   [7:0]   MAKE_RESPONSE_st            = 8'd3;
    parameter   [7:0]   DELAY_1_BYTE_st             = 8'd4;
    parameter   [7:0]   RESPONSE_1_st               = 8'd5;
    parameter   [7:0]   RESPONSE_3_st               = 8'd6;
    parameter   [7:0]   RESPONSE_7_st               = 8'd7;
    parameter   [7:0]   WAIT_FOR_SS_HIGH_st         = 8'd8;
    parameter   [7:0]   TRANSMIT_FF_st              = 8'd9;
    parameter   [7:0]   TRANSFER_OUT_DATA_st        = 8'd10;
    parameter   [7:0]   RECEIVE_DATA_st             = 8'd11;
    
    // constants
    parameter   [7:0]   CMD_BYTES_c                 = 8'd6;
    
    // Commands
    parameter   [47:0]  CMD0_FRAME_c                = 48'h40_00_00_00_00_95;        // This is a reset command. It is used to change from SD mode to SPI mode
    parameter   [47:0]  CMD1_FRAME_c                = 48'h41_00_00_00_00_00;        // 
    parameter   [47:0]  CMD8_FRAME_c                = 48'h48_00_00_01_AA_87;        // Table 4-18 page 92 (01 --> voltage range is 2.7V t0 3.6V)
    parameter   [47:0]  CMD55_FRAME_c               = 48'h77_00_00_00_00_01;        // Table 4-18 page 92 (01 --> voltage range is 2.7V t0 3.6V)
    parameter   [47:0]  ACMD41_FRAME_c              = 48'h69_40_00_00_00_00;        // Index -> (101001) Bit 30 in argument (bit 38 in frame) -> HCS. HCS is set to 1 for SDHC cards
    parameter   [47:0]  CMD58_FRAME_c               = 48'h7A_00_00_00_00_00;        // no argument
    parameter   [ 7:0]  CMD24_FRAME_c               =  8'h58;                       // no argument
    parameter   [ 7:0]  CMD17_FRAME_c               =  8'h51;                       // no argument
    
    // Responses
    parameter   [7:0]   RESPONSE_1_IDLE_c           = 8'h00;
    parameter   [7:0]   RESPONSE_1_BUSY_c           = 8'h01;
    parameter   [39:0]  SD_CARD_R7_RESP_FR_CMD8_c   = 40'h01_00_01_AA;  // This is the expected R7 response for command CMD8
    parameter   [39:0]  CMD58_response_c            = 40'h00_40_00_00;  // expected response
    parameter   [7:0]   RESPONSE_1_SD_OK_c          = 8'hE5;
    
    TB_SD_Card_Byte_Transfer TB_SD_Card_Byte_Transfer_inst(
    .clk_p                  (clk_p),
    .tb_spi_sck_p           (tb_spi_sck_p),
    .tb_spi_miso_p          (tb_spi_miso_p),
    .tb_spi_mosi_p          (tb_spi_mosi_p),
    .tb_data_to_transfer_p  (tb_data_to_transfer_s),
    .tb_init_transfer_p     (tb_init_transfer_s),
    .tb_transfer_done_p     (tb_transfer_done_p),
    .tb_spi_data_in_p       (tb_spi_data_in_s)
    );
    
    
    
    
    always @(posedge clk_p)
    begin
        
        case (tb_spi_slave_state_s)
        
        // wait for the Slave select to be pulled low (Active)
        IDLE_st: begin
                if (tb_spi_ss_p == 1'b0) begin
                    tb_init_transfer_s      <= 1'b1;
                    tb_data_to_transfer_s   <= 8'hFF;
                    tb_spi_slave_state_s    <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s <= GET_CMD_st;
                    received_bytes_s        <= 0;
                    end
                else begin
                    tb_spi_slave_state_s    <= IDLE_st;
                end
            end
            
        // decode the command - the first 6 bytes.    
        GET_CMD_st: begin
                if (received_bytes_s == CMD_BYTES_c) begin
                    tb_command_s            <= {tb_command_s[47:0], tb_spi_data_in_s};
                    received_bytes_s        <= 0;
                    tb_spi_slave_state_s    <= DELAY_1_BYTE_st;
                    end
                else begin
                    tb_command_s            <= {tb_command_s[47:0], tb_spi_data_in_s};
                    tb_init_transfer_s      <= 1'b1;
                    tb_data_to_transfer_s   <= 8'hFF;
                    tb_spi_slave_state_s    <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s <= GET_CMD_st;
                end
            end
        
        DELAY_1_BYTE_st: begin
                tb_init_transfer_s          <= 1'b1;
                tb_data_to_transfer_s       <= 8'hFF;
                tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                tb_spi_slave_rtrn_state_s   <= MAKE_RESPONSE_st;
            end
        
        // Using the decoded command, select a response that needs to be sent
        MAKE_RESPONSE_st: begin
                if (tb_command_s == CMD0_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_1_st;
                    response_R1_s           <= RESPONSE_1_BUSY_c;
                    end
                else if (tb_command_s == CMD8_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_7_st;
                    response_R7_s           <= SD_CARD_R7_RESP_FR_CMD8_c;
                    end
                else if (tb_command_s == CMD58_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_3_st;
                    response_R3_s           <= CMD58_response_c;
                    end
                else if (tb_command_s == CMD55_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_1_st;
                    response_R1_s           <= RESPONSE_1_BUSY_c;
                    end
                else if (tb_command_s == ACMD41_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_1_st;
                    response_R1_s           <= RESPONSE_1_IDLE_c;
                    end
                else if (tb_command_s[47:40] == CMD17_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_1_st;
                    response_R1_s           <= RESPONSE_1_IDLE_c;
                    end
                else begin if (tb_command_s[47:40] == CMD24_FRAME_c) begin
                    tb_spi_slave_state_s    <= RESPONSE_1_st;
                    response_R1_s           <= RESPONSE_1_IDLE_c;
                    end
                end                
            end
            
        TRANSMIT_FF_st: begin
                tb_init_transfer_s          <= 1'b1;
                tb_data_to_transfer_s       <= 8'hFF;
                tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                tb_spi_slave_rtrn_state_s   <= TRANSFER_OUT_DATA_st;
                tb_num_byte_tfers_s         <= 0;
            end
         // $fopen("E:/HASP/Code/Current_Code/SD_Card_Intfc/FPGA-Code-CMOD-A7/sources/sim/DAT_adc_tb_data.txt","r")       
        TRANSFER_OUT_DATA_st: begin
                if (tb_num_byte_tfers_s == 0) begin
                    tb_num_byte_tfers_s         <= tb_num_byte_tfers_s + 1;
                    tb_init_transfer_s          <= 1'b1;
                    tb_data_to_transfer_s       <= 8'hFE;
                    tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s   <= TRANSFER_OUT_DATA_st;
                    end
                else if (tb_num_byte_tfers_s == 513) begin
                    tb_num_byte_tfers_s         <= tb_num_byte_tfers_s + 1;
                    tb_init_transfer_s          <= 1'b1;
                    tb_data_to_transfer_s       <= 8'hFF;
                    tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s   <= TRANSFER_OUT_DATA_st;
                    end
                else if (tb_num_byte_tfers_s == 514) begin
                    tb_num_byte_tfers_s         <= tb_num_byte_tfers_s + 1;
                    tb_init_transfer_s          <= 1'b1;
                    tb_data_to_transfer_s       <= 8'hF5;
                    tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s   <= TRANSFER_OUT_DATA_st;
                    end
                else if (tb_num_byte_tfers_s > 515) begin
                    tb_spi_slave_state_s        <= WAIT_FOR_SS_HIGH_st;
                    tb_num_byte_tfers_s         <= 0;
                    end
                else begin
                    tb_num_byte_tfers_s         <= tb_num_byte_tfers_s + 1;
                    tb_init_transfer_s          <= 1'b1;
                    tb_data_to_transfer_s       <= 8'h01;
                    tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s   <= TRANSFER_OUT_DATA_st;
                end
            end
          
        RECEIVE_DATA_st: begin
                if (tb_num_byte_tfers_s > 519) begin
                    tb_spi_slave_state_s        <= WAIT_FOR_SS_HIGH_st;
                    tb_num_byte_tfers_s         <= 0;
                    end
                else if (tb_num_byte_tfers_s == 517) begin
                    tb_num_byte_tfers_s         <= tb_num_byte_tfers_s + 1;
                    tb_init_transfer_s          <= 1'b1;
                    tb_data_to_transfer_s       <= 8'h00;
                    tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s   <= RECEIVE_DATA_st;
                    end
                else begin
                    tb_num_byte_tfers_s         <= tb_num_byte_tfers_s + 1;
                    tb_init_transfer_s          <= 1'b1;
                    tb_data_to_transfer_s       <= 8'hFF;
                    tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s   <= RECEIVE_DATA_st;
                end
            end
            
        RESPONSE_1_st: begin
                tb_init_transfer_s          <= 1'b1;
                tb_data_to_transfer_s       <= response_R1_s;
                tb_spi_slave_state_s        <= WAIT_FOR_TRANSMIT_DONE_st;
                if (tb_command_s[47:40] == CMD17_FRAME_c) 
                    tb_spi_slave_rtrn_state_s   <= TRANSMIT_FF_st;
                else if (tb_command_s[47:40] == CMD24_FRAME_c)
                    tb_spi_slave_rtrn_state_s   <= RECEIVE_DATA_st;
                else
                    tb_spi_slave_rtrn_state_s   <= WAIT_FOR_SS_HIGH_st;
            end
            
        RESPONSE_3_st: begin
                if (response_counter_s == 5) begin
                    tb_spi_slave_state_s    <= WAIT_FOR_SS_HIGH_st;
                    response_counter_s      <= 0;
                    end
                else begin
                    tb_init_transfer_s      <= 1'b1;
                    tb_data_to_transfer_s   <= response_R3_s[39:32];
                    response_R3_s           <= {response_R3_s[31:0],8'd0};
                    response_counter_s      <= response_counter_s + 1;
                    tb_spi_slave_state_s    <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s <= RESPONSE_3_st;
                end
            end
            
        RESPONSE_7_st: begin
                if (response_counter_s == 5) begin
                    tb_spi_slave_state_s    <= WAIT_FOR_SS_HIGH_st;
                    response_counter_s      <= 0;
                    end
                else begin
                    tb_init_transfer_s      <= 1'b1;
                    tb_data_to_transfer_s   <= response_R7_s[39:32];
                    response_R7_s           <= {response_R7_s[31:0],8'd0};
                    response_counter_s      <= response_counter_s + 1;
                    tb_spi_slave_state_s    <= WAIT_FOR_TRANSMIT_DONE_st;
                    tb_spi_slave_rtrn_state_s <= RESPONSE_7_st;
                end
            end
        
        WAIT_FOR_TRANSMIT_DONE_st: begin
                if (tb_transfer_done_p == 1'b1) begin
                    tb_init_transfer_s      <= 1'b0;
                    received_bytes_s        <= received_bytes_s + 1;
                    tb_spi_slave_state_s    <= tb_spi_slave_rtrn_state_s;
                    end
                else begin
                    tb_spi_slave_state_s    <= WAIT_FOR_TRANSMIT_DONE_st;
                end
            end
    
        WAIT_FOR_SS_HIGH_st: begin
                if (tb_spi_ss_p == 1'b1) begin
                    tb_spi_slave_state_s    <= IDLE_st;
                    end
                else begin
                    tb_spi_slave_state_s    <= WAIT_FOR_SS_HIGH_st;
                end
            end         
        
        default: begin
                tb_spi_slave_state_s    <= IDLE_st;
            end
            
        endcase     
    end 
    
endmodule


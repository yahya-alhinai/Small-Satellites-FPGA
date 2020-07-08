`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2017 02:49:16 PM
// Design Name: 
// Module Name: uart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a Top level module that includes the Rx and Tx part of UART.
//  It mainly interfaces with the Memory Map module that stores all the information
//  that would be communicated to the User. The RX module receives addresses from the
//  laptop and the data corresponding to the read addresses is sent back.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_top(
    clk210_p,
    reset_p,
    tx_p,
    rx_p,
    memory_map_adrs_p,
    // memory_map_wr_data_p,
    memory_map_rd_data_p
    // memory_map_wr_req_p,
    // memory_map_rd_req_p,
    // memory_map_rd_ack_p,    
    // memory_map_wr_ack_p,    
    // memory_map_er_p 
    );
    
    input           clk210_p;
    input           reset_p;
    input           memory_map_rd_data_p;
    input           rx_p;
    // input           memory_map_rd_ack_p;
    // input           memory_map_wr_ack_p;
    // input           memory_map_er_p;
    
    output          tx_p;
    output          memory_map_adrs_p;
    // output          memory_map_wr_data_p;
    // output          memory_map_rd_req_p;
    // output          memory_map_wr_req_p;
    
    // variable declaration
    
    wire            baud_16_x_p;
    wire            baud_1_x_p;
    wire            tx_p;
    wire            rx_p;
    wire            transmit_done_p;
    
    reg             transmit_done_ack_p     = 1'b0;
    reg             transmit_req_p          = 1'b0;
    reg     [15:0]  transmit_data_p         = 16'd0;
    reg     [7:0]   fifo_tx_din_p           = 8'd0;
    reg             fifo_tx_wr_en_p         = 1'b0;
    wire    [4:0]   fifo_tx_data_count_p;
    wire            fifo_tx_empty_p;
    
    wire            received_data_read_req_p;
    wire    [7:0]   fifo_rx_dout_p;
    wire    [4:0]   fifo_rx_data_count_p;
    wire            fifo_rx_empty_p;
    reg             fifo_rx_rd_en_p         = 1'b0;
    reg             received_data_ack_p     = 1'b0;
    
    reg     [15:0]   memory_map_adrs_p      = 16'd0;
    reg     [15:0]  memory_map_wr_data_p    = 16'd0;
    wire    [15:0]  memory_map_rd_data_p;
    
    reg     [7:0]   uart_state_s            = 8'd0;
    reg     [7:0]   uart_return_state_s     = 8'd0;
    reg     [7:0]   write_counter_s         = 8'd0;
    reg     [7:0]   read_data_s             = 8'd0;
    reg     [15:0]  read_address_s          = 15'd0;
    reg     [7:0]   decoded_command_s       = 8'd0;
    reg     [7:0]   tx_fifo_fill_counter_s  = 8'd0; 
    
    // Parameter declarations
    parameter   [7:0]   IDLE_c              = 8'd0;
    parameter   [7:0]   READ_1_BYTE_c       = 8'd1;
    parameter   [7:0]   DECODE_BYTE_c       = 8'd2;
    parameter   [7:0]   WAIT_FR_START_CMD_c = 8'd3;
    parameter   [7:0]   DECODE_COMMAND_c    = 8'd4;
    parameter   [7:0]   DECODE_ADDRESS_MSB_c= 8'd5;
    parameter   [7:0]   DECODE_ADDRESS_LSB_c= 8'd6;
    parameter   [7:0]   SEND_ADDR_TO_MEM_c  = 8'd7;
    parameter   [7:0]   GET_DATA_FROM_MEM_c = 8'd8;
    parameter   [7:0]   PULL_UP_TX_FIFO_WE_c= 8'd9;
    parameter   [7:0]   LOAD_TX_FIFO_c      = 8'd10;
    parameter   [7:0]   TRANSMIT_DATA_c     = 8'd11;
    parameter   [7:0]   WAIT_FOR_TX_DONE_c  = 8'd12;
    parameter   [7:0]   WRITE_DATA_TO_ADDR_c= 8'd13;
    
    parameter   [7:0]   START_INDICATOR_c   = 8'd1;
    parameter   [7:0]   READ_COMMAND_c      = 8'd2;
    parameter   [7:0]   WRITE_COMMAND_c     = 8'd3;
    parameter   [7:0]   NUMBER_OF_BYTES_c   = 8'd2;         // currently a constant, can change this
    
    // Module Declaration
    uart_tx tx_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .baud_1_x_p                 (baud_1_x_p),
    .tx_p                       (tx_p),
    .transmit_req_p             (transmit_req_p),
    .transmit_done_p            (transmit_done_p),
    .transmit_done_ack_p        (transmit_done_ack_p),
    .fifo_tx_din_p              (fifo_tx_din_p),
    .fifo_tx_wr_en_p            (fifo_tx_wr_en_p),
    .fifo_tx_data_count_p       (fifo_tx_data_count_p),
    .fifo_tx_empty_p            (fifo_tx_empty_p)
    );
    
    uart_rx rx_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .rx_p                       (rx_p),
    .baud_16_x_p                (baud_16_x_p),
    .received_data_read_req_p   (received_data_read_req_p),
    .received_data_ack_p        (received_data_ack_p),
    .fifo_rx_dout_p             (fifo_rx_dout_p),
    .fifo_rx_rd_en_p            (fifo_rx_rd_en_p),
    .fifo_rx_data_count_p       (fifo_rx_data_count_p),
    .fifo_rx_empty_p            (fifo_rx_empty_p)
    );
    
    baud_generator  baud_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .baud_16_x_p                (baud_16_x_p),
    .baud_1_x_p                 (baud_1_x_p)
    );

    // state machine to control transactions
    always @(posedge clk210_p)
    begin
        if(reset_p)
            begin
                uart_state_s                        <= IDLE_c;
                uart_return_state_s                 <= IDLE_c;
                fifo_rx_rd_en_p                     <= 1'b0;
                transmit_data_p                     <= 16'd0;
                transmit_req_p                      <= 1'b0;
                fifo_tx_wr_en_p                     <= 1'b0;
                decoded_command_s                   <= 8'd0;
                read_data_s                         <= 8'd0;
            end
        else
            begin
                case(uart_state_s)
                IDLE_c:
                    begin
                        if(fifo_rx_data_count_p >0 ) begin
                            uart_state_s            <= READ_1_BYTE_c;
                            fifo_rx_rd_en_p         <= 1'b1;
                            end 
                        else
                            uart_state_s            <= IDLE_c;
                    end
                
                READ_1_BYTE_c:
                    begin
                        fifo_rx_rd_en_p             <= 1'b0;                    // Read enable is pulled up
                                                                            // only for 1 clock cycle
                        uart_state_s                <= DECODE_BYTE_c;
                    end
                
                DECODE_BYTE_c:
                    begin
                        read_data_s                 <= fifo_rx_dout_p;
                                                                            // Based on the return state, decide where the
                                                                            // state will go to next                    
                        if(uart_return_state_s == IDLE_c) begin
                            uart_state_s            <= WAIT_FR_START_CMD_c;
                            end
                        else if (uart_return_state_s == WAIT_FR_START_CMD_c) begin
                            uart_state_s            <= DECODE_COMMAND_c;
                            end
                        else if (uart_return_state_s == DECODE_COMMAND_c) begin
                            uart_state_s            <= DECODE_ADDRESS_MSB_c;
                            end
                        else if (uart_return_state_s == DECODE_ADDRESS_MSB_c) begin
                            uart_state_s            <= DECODE_ADDRESS_LSB_c;
                            end
                        else begin
                            uart_state_s            <= IDLE_c;
                            uart_return_state_s     <= IDLE_c;
                        end
                    end
    
                WAIT_FR_START_CMD_c:
                    begin
                        if (read_data_s == START_INDICATOR_c) begin
                            uart_state_s            <= IDLE_c;
                            uart_return_state_s     <= WAIT_FR_START_CMD_c;
                            end
                        else begin
                            uart_state_s            <= IDLE_c;              // Reset if Start indicator is not seen
                            uart_return_state_s     <= IDLE_c;              // as the first byte
                            end
                    end
                    
                DECODE_COMMAND_c:
                    begin
                        if (read_data_s == READ_COMMAND_c) begin
                            uart_state_s            <= IDLE_c;
                            uart_return_state_s     <= DECODE_COMMAND_c;
                            decoded_command_s       <= READ_COMMAND_c;
                            end
                        else if (read_data_s == WRITE_COMMAND_c) begin
                            uart_state_s            <= IDLE_c;              // currently there is no feature for writing
                            uart_return_state_s     <= IDLE_c;              // data from the computer to the FPGA. So, return
                            decoded_command_s       <= WRITE_COMMAND_c;     // to IDLE state if a Write Command is issued
                            end
                        else begin
                            uart_state_s            <= IDLE_c;
                            uart_return_state_s     <= IDLE_c;
                        end
                    end
                    
                DECODE_ADDRESS_MSB_c:
                    begin
                        read_address_s[15:8]        <= read_data_s;
                        uart_state_s                <= IDLE_c;
                        uart_return_state_s         <= DECODE_ADDRESS_MSB_c;
                    end
                
                DECODE_ADDRESS_LSB_c:
                    begin
                        read_address_s[7:0]         <= read_data_s;
                        uart_state_s                <= SEND_ADDR_TO_MEM_c;  // This logic needs to be changed for the WRITE DATA Command
                                                                            // maybe do something similar to the uart_return_state_s type logic.
                        uart_return_state_s         <= IDLE_c;
                    end
                
                SEND_ADDR_TO_MEM_c:
                    begin
                        memory_map_adrs_p           <= read_address_s;
                        uart_state_s                <= GET_DATA_FROM_MEM_c;
                    end
                
                GET_DATA_FROM_MEM_c:
                    begin
                        transmit_data_p             <= memory_map_rd_data_p;
                        uart_state_s                <= PULL_UP_TX_FIFO_WE_c;
                    end
                
                PULL_UP_TX_FIFO_WE_c:
                    begin
                        if(tx_fifo_fill_counter_s   == NUMBER_OF_BYTES_c) begin
                            uart_state_s            <= TRANSMIT_DATA_c;
                            tx_fifo_fill_counter_s  <= 0;
                            end
                        else begin
                            fifo_tx_wr_en_p         <= 1'b1;
                            uart_state_s            <= LOAD_TX_FIFO_c;
                            tx_fifo_fill_counter_s  <= tx_fifo_fill_counter_s + 1'b1;
                            case(tx_fifo_fill_counter_s)
                            0:  fifo_tx_din_p       <= transmit_data_p[15:8];
                            1:  fifo_tx_din_p       <= transmit_data_p[ 7:0];
                            // 0:  fifo_tx_din_p       <= transmit_data_p[79:72];
                            // 1:  fifo_tx_din_p       <= transmit_data_p[71:64];
                            // 2:  fifo_tx_din_p       <= transmit_data_p[63:56];
                            // 3:  fifo_tx_din_p       <= transmit_data_p[55:48];
                            // 4:  fifo_tx_din_p       <= transmit_data_p[47:40];
                            // 5:  fifo_tx_din_p       <= transmit_data_p[39:32];
                            // 6:  fifo_tx_din_p       <= transmit_data_p[31:24];
                            // 7:  fifo_tx_din_p       <= transmit_data_p[23:16];
                            // 8:  fifo_tx_din_p       <= transmit_data_p[15: 8];
                            // 9:  fifo_tx_din_p       <= transmit_data_p[ 7: 0];
                            default: 
                                fifo_tx_din_p       <= transmit_data_p[ 7: 0];
                            endcase
                        end
                    end
                    
                LOAD_TX_FIFO_c:
                    begin
                        fifo_tx_wr_en_p             <= 1'b0;
                        uart_state_s                <= PULL_UP_TX_FIFO_WE_c;
                    end
                    
                TRANSMIT_DATA_c:
                    begin
                        transmit_req_p              <= 1'b1;
                        uart_state_s                <= WAIT_FOR_TX_DONE_c;
                    end
                
                WAIT_FOR_TX_DONE_c:
                    begin
                        if(transmit_done_p == 1) begin
                            transmit_req_p          <= 1'b0;
                            uart_state_s            <= IDLE_c;
                            end
                        else
                            uart_state_s            <= WAIT_FOR_TX_DONE_c;
                    end
                
                default:
                    uart_state_s                    <= IDLE_c;
                endcase
            end
    end
        
    
endmodule

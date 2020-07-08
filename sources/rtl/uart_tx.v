`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2017 02:49:16 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    clk210_p,
    reset_p,
    baud_1_x_p,
    tx_p,
    transmit_data_p,
    transmit_req_p,
    transmit_done_p,
    transmit_done_ack_p,
    fifo_tx_din_p,
    fifo_tx_wr_en_p,
    fifo_tx_data_count_p,
    fifo_tx_empty_p
    );
    
    input               clk210_p;
    input               reset_p;
    input               baud_1_x_p;
    input               transmit_data_p;
    input               transmit_req_p;
    input               transmit_done_ack_p;
    input               fifo_tx_din_p;
    input               fifo_tx_wr_en_p;
    
    output              tx_p;
    output              transmit_done_p;
    output              fifo_tx_data_count_p;
    output              fifo_tx_empty_p;
    
    // variable declaration
    wire        [7:0]   transmit_data_p;
    wire                transmit_done_ack_p;
    
    reg         [7:0]   uart_tx_state_s     = 8'd0;
    reg         [7:0]   uart_tx_bit_count_s = 8'd0;
    reg                 transmit_done_p     = 1'd0;
    reg         [7:0]   data_tx_s           = 8'd0;
    reg                 tx_p                = 1'b1;
    reg                 uart_tx_last_op_s   = 1'b0;
    
    reg                 fifo_tx_rd_en_s     = 1'b0;
    wire                fifo_tx_full_s;
    wire                fifo_tx_almost_full_s;
    wire                fifo_tx_almost_empty_s;
    wire        [7:0]   fifo_tx_dout_s;
    wire        [4:0]   fifo_tx_data_count_p;
    wire                fifo_tx_empty_p;
    wire        [7:0]   fifo_tx_din_p;
    wire                fifo_tx_wr_en_p;
    
    // (* mark_debug = "true" *) wire [7:0] uart_tx_state_s_debug;  
    // assign uart_tx_state_s_debug = uart_tx_state_s;
    // parameter declaration
    parameter   [7:0]   TX_IDLE_c           = 8'd0;
    parameter   [7:0]   PULL_DWN_RD_EN_c    = 8'd1;
    parameter   [7:0]   TX_START_BIT_c      = 8'd2;
    parameter   [7:0]   TX_TRANSMIT_BYTE_c  = 8'd3;
    parameter   [7:0]   TX_STOP_BIT_c       = 8'd4;
    parameter   [7:0]   TX_DONE_c           = 8'd5;
    parameter   [7:0]   INITIATE_TX_c       = 8'd6;
    parameter   [7:0]   GET_BYTE_c          = 8'd7;
    parameter   [7:0]   TX_WAIT_FOR_ACK_c   = 8'd8;
    
    // Module Declarations
    fifo_tx fifo_tx_inst(                                                       // This is a 32 byte deep FIFO.
    .clk                        (clk210_p),                                     // Data is loaded into the FIFO from the top level
    .rst                        (reset_p),                                      // module and the loaded data is transmitted back
    .din                        (fifo_tx_din_p),                                // when the top decides to.
    .wr_en                      (fifo_tx_wr_en_p),                              // 
    .rd_en                      (fifo_tx_rd_en_s),
    .dout                       (fifo_tx_dout_s),
    .full                       (fifo_tx_full_s),
    .almost_full                (fifo_tx_almost_full_s),
    .almost_empty               (fifo_tx_almost_empty_s),
    .empty                      (fifo_tx_empty_p),
    .data_count                 (fifo_tx_data_count_p)
    );  
    
    
    always @(posedge clk210_p)
    begin
        if(reset_p) 
            begin
                uart_tx_state_s             <= TX_IDLE_c;
                uart_tx_bit_count_s         <= 8'd0;
                transmit_done_p             <= 1'd0;
                tx_p                        <= 1'b1;
                uart_tx_last_op_s           <= 1'b0;
            end
        else
            begin
                case(uart_tx_state_s)
                TX_IDLE_c:
                    begin
                        if(transmit_req_p == 1)
                            begin
                                uart_tx_state_s     <= GET_BYTE_c;
                                tx_p                <= 1'b1;
                                uart_tx_bit_count_s <= 8'd0;
                                transmit_done_p     <= 1'b0;
                                // fifo_tx_rd_en_s      <= 1'b1;
                                transmit_done_p     <= 1'b0;
                                uart_tx_last_op_s   <= 1'b0;
                            end
                        else
                            begin
                                uart_tx_state_s     <= TX_IDLE_c;
                                uart_tx_bit_count_s <= 8'd0;
                                transmit_done_p     <= 1'b0;    
                                tx_p                <= 1'b1;
                            end
                    end
                
                GET_BYTE_c:
                    begin
                        if(fifo_tx_almost_empty_s)
                            begin
                                fifo_tx_rd_en_s     <= 1'b1;
                                uart_tx_state_s     <= PULL_DWN_RD_EN_c;
                                uart_tx_last_op_s   <= 1'b1;
                            end
                        else
                            begin
                                fifo_tx_rd_en_s     <= 1'b1;
                                uart_tx_state_s     <= PULL_DWN_RD_EN_c;
                            end
                    end
                
                PULL_DWN_RD_EN_c:
                    begin
                        fifo_tx_rd_en_s             <= 1'b0;
                        uart_tx_state_s             <= INITIATE_TX_c;
                    end
                
                INITIATE_TX_c:
                    begin
                        data_tx_s                   <= fifo_tx_dout_s;
                        uart_tx_state_s             <= TX_START_BIT_c;
                    end
                
                TX_START_BIT_c:
                    begin
                        if(baud_1_x_p)
                            begin
                                tx_p                <= 1'b0;
                                uart_tx_state_s     <= TX_TRANSMIT_BYTE_c;
                            end
                        else
                            begin
                                tx_p                <= 1'b1;
                                uart_tx_state_s     <= TX_START_BIT_c;
                            end
                    end
                
                TX_TRANSMIT_BYTE_c:
                    begin
                        if(uart_tx_bit_count_s != 8'd8)
                            begin
                                if(baud_1_x_p)
                                    begin
//                                      tx_p                <= data_tx_s[8'd7-uart_tx_bit_count_s];
                                        tx_p                <= data_tx_s[uart_tx_bit_count_s];
                                        uart_tx_bit_count_s <= uart_tx_bit_count_s + 1;
                                    end
                                else
                                    tx_p                    <= tx_p;
                            end
                        else
                            begin
                                uart_tx_bit_count_s         <= 8'd0;
                                uart_tx_state_s             <= TX_STOP_BIT_c;
                            end
                    end
                    
                TX_STOP_BIT_c:
                    begin
                        if(baud_1_x_p)
                            begin
                                tx_p                <= 1'b1;
                                uart_tx_state_s     <= TX_DONE_c;
                            end
                        else
                            tx_p                    <= tx_p;
                    end
                
                TX_DONE_c:
                    begin
                        if(uart_tx_last_op_s == 1)
                            begin
                                uart_tx_state_s     <= TX_WAIT_FOR_ACK_c;
                                transmit_done_p     <= 1'b1;
                                uart_tx_last_op_s   <= 1'b0;
                            end
                        else
                            uart_tx_state_s         <= GET_BYTE_c;
                    end
                    
                TX_WAIT_FOR_ACK_c:
                    begin
                        if(~transmit_req_p)
                            begin
                                uart_tx_state_s     <= TX_IDLE_c;
                                transmit_done_p     <= 1'b0;
                            end
                        else
                            uart_tx_state_s         <= TX_WAIT_FOR_ACK_c;
                    end
                    
                default:
                    uart_tx_state_s                 <= TX_IDLE_c;
                endcase
            end
    end 
    
endmodule

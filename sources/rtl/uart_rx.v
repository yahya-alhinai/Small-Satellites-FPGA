`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2017 02:49:16 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    clk210_p,
    reset_p,
    rx_p,
    baud_16_x_p,
    received_data_read_req_p,
    received_data_ack_p,
    fifo_rx_dout_p,
    fifo_rx_rd_en_p,
    fifo_rx_data_count_p,
    fifo_rx_empty_p
    );
    
    input           clk210_p;
    input           reset_p;
    input           rx_p;
    input           baud_16_x_p;
    input           received_data_ack_p;
    input           fifo_rx_rd_en_p;
    
    output          received_data_read_req_p;
    output          fifo_rx_dout_p;
    output          fifo_rx_data_count_p;
    output          fifo_rx_empty_p;
    
    // variable declarations
    reg     [7:0]   received_data_s             = 8'd0;             // This is the received data.
    reg     [7:0]   uart_rx_state_s             = 8'd0;             // UART receiver state 
    reg     [7:0]   sync_counter_s              = 8'd0;             // This counter is used to synchronize the sampler
                                                                    // to sample at the 8th cycle from the rising edge of 
                                                                    // the Rx signal. The UART Receiver operates as a 16x 
                                                                    // oversampler CDR (Clock and Data Recovery).
    reg     [7:0]   received_bit_count_s        = 8'd0;             // counts the number of bits received so far
    reg             uart_rx_error_s             = 1'd0;             // indicates that an error occured
    reg             received_data_read_req_p    = 1'd0;             
    
    reg     [7:0]   fifo_rx_din_s               = 8'd0;             // data that would be loaded into the FIFO
    reg             fifo_rx_wr_en_s             = 1'd0;             // 
    
    wire            fifo_rx_rd_en_p;                                // UART TOP will use this signal
    wire            fifo_rx_full;
    wire            fifo_rx_almost_full;
    wire            fifo_rx_almost_empty;
    wire    [7:0]   fifo_rx_dout_p;
    wire    [4:0]   fifo_rx_data_count_p;
    wire            fifo_rx_empty_p;
    
    // parameter declarations
    parameter   [7:0]   WAIT_FOR_START_c    = 8'd0;
    parameter   [7:0]   SYNC_TO_SOURCE_c    = 8'd1;
    parameter   [7:0]   RECEIVE_BYTE_c      = 8'd2;
    parameter   [7:0]   STOP_BIT_c          = 8'd3;
    parameter   [7:0]   ENTER_TO_FIFO_c     = 8'd4;
    parameter   [7:0]   SEND_REQ_READ_c     = 8'd5;

    // Module Declarations
    fifo_rx fifo_rx_inst(                                                       // This is a 32 byte deep FIFO.
    .clk                        (clk210_p),                                     // Data that is seen from the receiver is 
    .rst                        (reset_p),                                      // loaded onto the FIFO as and when it arrives.
    .din                        (fifo_rx_din_s),                                // fifo_rx_data_count_p will be used to determine
    .wr_en                      (fifo_rx_wr_en_s),                              // when data needs to be read out.
    .rd_en                      (fifo_rx_rd_en_p),
    .dout                       (fifo_rx_dout_p),
    .full                       (fifo_rx_full),
    .almost_full                (fifo_rx_almost_full),
    .almost_empty               (fifo_rx_almost_empty),
    .empty                      (fifo_rx_empty_p),
    .data_count                 (fifo_rx_data_count_p)
    );  
    
    always @(posedge clk210_p)
    begin
        if(reset_p)
            begin
                uart_rx_state_s                 <= WAIT_FOR_START_c;
                sync_counter_s                  <= 8'd0;
                received_bit_count_s            <= 8'd0;
                uart_rx_error_s                 <= 1'd0;
                received_data_s                 <= 8'd0;
                received_data_read_req_p        <= 1'b0;
            end
        else
            begin
                case(uart_rx_state_s)
                WAIT_FOR_START_c:                                               // waits for a signal to show up
                    begin                                                       // at RX
                        if(rx_p == 1'b0)
                            begin
                                uart_rx_state_s         <= SYNC_TO_SOURCE_c;
                                sync_counter_s          <= 8'd0;
                                received_bit_count_s    <= 8'd0;
                                uart_rx_error_s         <= 1'd0;
                                received_data_s         <= 8'd0;
                                received_data_read_req_p<= 1'b0;
                                fifo_rx_din_s           <= 8'd0;
                                fifo_rx_wr_en_s         <= 1'b0;
                            end
                        else
                            begin
                                uart_rx_state_s         <= WAIT_FOR_START_c;
                                fifo_rx_wr_en_s         <= 1'b0;
                            end
                    end
                    
                SYNC_TO_SOURCE_c:                                               // the UART receiver is configured to 
                    begin                                                       // operate at 16 times the baud rate.
                        if(baud_16_x_p == 1'b1)                                 // Once an edge is detected, the 
                            begin                                               // synchronizer alignes the sampler to
                                if((rx_p == 1'b0)&(sync_counter_s != 8'd8))     // sample at the 8th cycle after the rising
                                    begin                                       // edge. This is to ensure data integrity.
                                        sync_counter_s  <= sync_counter_s + 1'b1;   // This sample was decided since data is usually
                                        uart_rx_state_s <= SYNC_TO_SOURCE_c;        // most stable at the middle.
                                    end                                         // The condition says rx_p == 1'b0 since the 
                                else                                            // start bit is a low signal.
                                    begin
                                        sync_counter_s  <= 8'd0;
                                        uart_rx_state_s <= RECEIVE_BYTE_c;
                                    end
                            end
                        else
                            uart_rx_state_s             <= SYNC_TO_SOURCE_c;
                    end
                    
                RECEIVE_BYTE_c:                                                 // This state is where the bit from the Rx
                    begin                                                       // is sampled and shifted in to received_data_s
                        if(baud_16_x_p == 1'b1)
                            begin
                                if(received_bit_count_s != 8'd8)
                                    begin
                                        if(sync_counter_s == 8'd15)
                                            begin
//                                              received_data_s[7:0]    <= {received_data_s[6:0], rx_p};
                                                received_data_s[7:0]    <= {rx_p,received_data_s[7:1]};
                                                sync_counter_s          <= 8'd0;
                                                received_bit_count_s    <= received_bit_count_s + 1'b1;
                                            end
                                        else
                                            sync_counter_s              <= sync_counter_s + 1'b1;
                                    end
                                else
                                    begin
                                        uart_rx_state_s                 <= STOP_BIT_c;
                                        received_bit_count_s            <= 8'd0;
                                        sync_counter_s                  <= sync_counter_s + 1'b1;
                                    end
                            end
                        else
                            uart_rx_state_s             <= RECEIVE_BYTE_c;
                    end
                    
                STOP_BIT_c:                                                     // This state looks for the stop bit which is
                    begin                                                       // 1'b1.
                        if(baud_16_x_p == 1'b1)
                            begin
                                if(sync_counter_s == 8'd15)
                                    begin
                                        if(rx_p == 1'b1)
                                            begin
                                                uart_rx_state_s         <= ENTER_TO_FIFO_c;
                                                fifo_rx_din_s               <= received_data_s;
                                            end
                                        else
                                            uart_rx_error_s         <= 1'b1;
                                            sync_counter_s          <= 8'd0;
                                    end
                                else
                                    sync_counter_s                  <= sync_counter_s + 1'b1;
                            end
                        else
                            uart_rx_state_s             <= STOP_BIT_c;
                    end

                ENTER_TO_FIFO_c:                                                // The received byte is entered into the FIFO
                    begin
                        fifo_rx_wr_en_s                 <= 1'b1;
                        // uart_rx_state_s                  <= SEND_REQ_READ_c; // currently the receiver is set to just keep
                                                                                // receiving data without letting the top level 
                                                                                // module know that data has been received.
                                                                                // The top level module will be responsible for
                                                                                // decoding on the fly.
                        uart_rx_state_s                 <= WAIT_FOR_START_c;
                        received_data_read_req_p        <= 1'b1;
                    end
                    
                default:
                    uart_rx_state_s                     <= WAIT_FOR_START_c;                    
                endcase
            end
    end
    
endmodule

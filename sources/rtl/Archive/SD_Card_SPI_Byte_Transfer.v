`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/31/2017 10:41:03 PM
// Design Name:
// Module Name: SD_Card_SPI_Byte_Transfer
// Project Name:
// Target Devices:
// Tool Versions:
// Description: This module only transfers a byte of data. The higher module needs
// to control it to use it as it wishes. This module doesn't contain the SS signal.
// The SS signal is handled by the higher module.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module SD_Card_SPI_Byte_Transfer(
    clk210_p,
    reset_p,
    sd_spi_mosi_p,
    sd_spi_miso_p,
    sd_spi_sck_p,
    sd_spi_ltransfer_in_p,
    sd_spi_ltransfer_out_p,
    sd_spi_init_trans_p,
    sd_spi_byte_done_p,
    sd_spi_select_speed_p,
    sd_spi_normal_baud_p,
    sd_spi_init_baud_p
    );

    input               clk210_p;                       // 210 MHz clock
    input               reset_p;                        // reset
    input               sd_spi_miso_p;                  // MISO (MASTER --> FPGA, SLAVE --> SD Card)
    input               sd_spi_ltransfer_out_p;         // data that needs to be transfered out.
                                                        // This data is sent from the higher module
                                                        // down to this module (hence the prefex "l").
                                                        // In the higher module, this same name will have
                                                        // a prefix "h"
    input               sd_spi_init_trans_p;            // initiates a transfer
    input               sd_spi_select_speed_p;          // This is a binary number that decides the speed of communication
                                                        // 1 --> Normal speed (Currently 35 MHz)
                                                        // 0 --> Initialization Speed (400 KHz)
    input               sd_spi_normal_baud_p;           // Ticks used during normal speed transfered
    input               sd_spi_init_baud_p;             // Ticks used during initialization

    output              sd_spi_ltransfer_in_p;          // Data that is transfered in from the SD card
    output              sd_spi_mosi_p;                  // MOSI (MASTER --> FPGA, SLAVE --> SD Card)
    output              sd_spi_sck_p;                   // S Clock
    output              sd_spi_byte_done_p;             // indication to the higher module that a byte has been transfered


    // Variable Declaration
    wire                sd_spi_byte_done_p;
    wire                sd_spi_sck_p;
    wire        [7:0]   sd_spi_ltransfer_in_p;
    wire        [7:0]   sd_spi_ltransfer_out_p;

    wire                sd_spi_baud_rate_s;             // selection between Normal Baud rate and initialization baud rate
    reg         [7:0]   sd_spi_state_s          = 8'd0; // state signals for the State Machine
    reg         [7:0]   sd_spi_ltransfer_in_s   = 8'd0;
    reg         [7:0]   sd_spi_ltransfer_out_s  = 8'd0;
    reg         [7:0]   sd_spi_num_bit_tfers_s  = 8'd0;

    reg                 sd_spi_byte_done_s      = 1'b0;
    reg                 sd_spi_mosi_s           = 1'b0;
    reg                 sd_spi_sck_s            = 1'b0;

    // Output assignments
    assign              sd_spi_mosi_p           = sd_spi_mosi_s;
    assign              sd_spi_sck_p            = sd_spi_sck_s;
    assign              sd_spi_ltransfer_in_p   = sd_spi_ltransfer_in_s;
    assign              sd_spi_byte_done_p      = sd_spi_byte_done_s;
    
    // Parameter List
    parameter   [7:0]   IDLE_st                 = 8'd0;
    parameter   [7:0]   WAIT_FOR_SCK_HIGH_st    = 8'd1;
    parameter   [7:0]   CAPTURE_DATA_MISO_st    = 8'd2;
    parameter   [7:0]   WAIT_FOR_SCK_LOW_st     = 8'd3;
    parameter   [7:0]   DONE_st                 = 8'd4;

    //-----------------------------------------------------------------------//
    // State Machine:
    // This state machine will be responsible in transfering a byte of data
    // on the SPI bus. This is a very "dumb" module in that it just transfers
    // data that is sent by the higher module just as is. The speed at which
    // data will be sent is decided by the sd_spi_select_speed_p signal and
    // is wired up to sd_spi_baud_rate_s essentially by a mux.
    //-----------------------------------------------------------------------//

    assign      sd_spi_baud_rate_s  = (sd_spi_select_speed_p == 1'b1) ?  sd_spi_normal_baud_p : sd_spi_init_baud_p;
                                    // The sd_spi_baud_rate_s pulses high every clock edge, not just on the rising or
                                    // falling. So, in the state machine alternate tasks take place every consecutive
                                    // tick.
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            sd_spi_state_s              <= IDLE_st;
            sd_spi_sck_s                <= 1'b0;
            sd_spi_mosi_s               <= 1'b1;
            sd_spi_num_bit_tfers_s      <= 8'd0;
            sd_spi_byte_done_s          <= 1'b0;
            end
        else begin
            case(sd_spi_state_s)

            // This state waits for the init_transfer_s signal goes high
            IDLE_st: begin
                    if (sd_spi_init_trans_p) begin
                        sd_spi_ltransfer_out_s      <= {sd_spi_ltransfer_out_p[6:0], 1'b1};     // get the data that needs to be transfered out
                                                                                                // Note that the ltransfer_s register is being shifted
                                                                                                // by a bit already. This is because ltransfer_out_p[7] is
                                                                                                // used on the mosi_p line on the start (immediately after
                                                                                                // SS is pulled low by the higher module - or during the middle
                                                                                                // of a bunch of transactions but at the start of a new byte)
                        sd_spi_mosi_s               <= sd_spi_ltransfer_out_p[7];
                        sd_spi_state_s              <= WAIT_FOR_SCK_HIGH_st;
                        sd_spi_sck_s                <= 1'b0;
                        sd_spi_num_bit_tfers_s      <= 8'd0;
                        sd_spi_byte_done_s          <= 1'b0;
                        end
                    else begin
                        sd_spi_sck_s                <= 1'b0;
                        sd_spi_state_s              <= IDLE_st;
                        sd_spi_num_bit_tfers_s      <= 8'd0;
                        sd_spi_byte_done_s          <= 1'b0;
                    end
                end

            // Here, wait for the sd_spi_baud_rate_s to go high (pulse high)
            // When it pulses high, raise the SCK signal and in the next clock cycle,
            // capture the data from the line.
            WAIT_FOR_SCK_HIGH_st: begin
                    if (sd_spi_baud_rate_s) begin                   // baud rate has ticked
                        sd_spi_sck_s                <= 1'b1;
                        sd_spi_state_s              <= CAPTURE_DATA_MISO_st;
                        end
                    else begin
                        sd_spi_state_s              <= WAIT_FOR_SCK_HIGH_st;
                    end
                end

            // Here, capture the data from the slave. This can (or maybe should) be adjusted
            // to capture data after a cycle to give the slave more time. But given how close the
            // frequencies are between the 210MHz clock and the 35 MHz clock, it is probably not
            // advisable to waste a clock cycle. If it is decided to delay by a clock, add another
            // state in  between this one and the previous one.
            CAPTURE_DATA_MISO_st: begin
                    sd_spi_ltransfer_in_s       <= {sd_spi_ltransfer_in_s[6:0],sd_spi_miso_p};  // Capture the MSB first
                    sd_spi_state_s              <= WAIT_FOR_SCK_LOW_st;
                end

            // Wait for the sd_spi_baud_rate_s signal to tick so you can send the next bit. Unlike
            // how data is captured at the next cycle in the above two states, here data is sent out
            // simultaneously as SCK is pulled low.
            WAIT_FOR_SCK_LOW_st: begin
                    if (sd_spi_baud_rate_s) begin
                            if (sd_spi_num_bit_tfers_s == 7) begin                                  // it is 7 here since the counter never gets to 8
                                                                                                    // given that it starts out at 0.
                                sd_spi_state_s          <= DONE_st;
                                sd_spi_num_bit_tfers_s  <= 8'd0;
                                sd_spi_byte_done_s      <= 1'b1;                                    // indicates to the higher module that the byte is transfered
                                end
                            else begin
                                sd_spi_sck_s            <= 1'b0;                                    // pull SCK low
                                sd_spi_mosi_s           <= sd_spi_ltransfer_out_s[7];               // shift out MSB first
                                sd_spi_ltransfer_out_s  <= {sd_spi_ltransfer_out_s[6:0], 1'b0};     // Shift the register after the transfer out
                                sd_spi_num_bit_tfers_s  <= sd_spi_num_bit_tfers_s + 1;
                                sd_spi_state_s          <= WAIT_FOR_SCK_HIGH_st;
                            end
                        end
                    else begin
                        sd_spi_state_s              <= WAIT_FOR_SCK_LOW_st;
                    end
                end

            // This is the done state. Here, the State Machine waits for the higher module to turn off init_transfer_s.
            // This is done so the Word transfer module doesn't free run continuously. Instead it is event driven.
            DONE_st: begin
                    if (sd_spi_init_trans_p == 1'b0) begin
                        sd_spi_state_s          <= IDLE_st;
                        sd_spi_byte_done_s      <= 1'b0;
                        end
                    else begin
                        sd_spi_state_s          <= DONE_st;
                    end
                end

            // default to IDLE_st
            default: begin
                    sd_spi_state_s              <= IDLE_st;
                end
            endcase
        end
    end

endmodule






`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2017 06:47:50 PM
// Design Name: 
// Module Name: SD_Card_SPI_baud_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module generates the Baud rate for both the initialization
// clock frequency of 400 KHz and the normal operation clock frequency of 35 MHz
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SD_Card_SPI_baud_gen 
#(
    parameter   INIT_BAUD_CLKDIV_c      = 525,      // specify the clkdiv factor for 400 KHz clock
                NORMAL_BAUD_CLK_DIV_c   =   6       // specify the clkdiv factor for 35 MHz clock
                                                    // Note that the clocks produced by this module is double the actual actual
                                                    // That is, INIT BAUD Clock is actually 800 KHz
                                                    // and NORMAL BAUD Clock is actually  70 MHz
                                                    // This is done since the SD_Card_SPI_Byte_Transfer module which uses these
                                                    // clocks treats consecutive ticks as a rising and then a falling or vice versa
    )
(
    clk210_p,
    reset_p,
    sd_spi_normal_baud_p,
    sd_spi_init_baud_p
    );
    
    input               clk210_p;
    input               reset_p;
    
    output              sd_spi_init_baud_p;
    output              sd_spi_normal_baud_p;
    
    // Variable declarations
    wire                sd_spi_init_baud_p;
    wire                sd_spi_normal_baud_p;
    
    reg                 sd_spi_init_baud_s      =  1'b0;
    reg                 sd_spi_normal_baud_s    =  1'b0;
    reg         [15:0]  init_baud_count_s       = 16'd0;
    reg         [15:0]  normal_baud_count_s     = 16'd0;
    
    // parameter   INIT_BAUD_CLKDIV_c      = 525;      // specify the clkdiv factor for 400 KHz clock
    // parameter   NORMAL_BAUD_CLK_DIV_c   =   6;
    
    
    // Output Assignments
    assign      sd_spi_init_baud_p      = sd_spi_init_baud_s;
    assign      sd_spi_normal_baud_p    = sd_spi_normal_baud_s;
    
    
    // This block generates the initialization clock rate
    // Note that the clock is essentially a tick valid only for 
    // one 210 MHz clock period.
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            init_baud_count_s   <= 16'd0;
            sd_spi_init_baud_s  <= 1'b0;
            end
        else begin
            if (init_baud_count_s == INIT_BAUD_CLKDIV_c) begin
                sd_spi_init_baud_s  <= 1'b1;
                init_baud_count_s   <= 16'd0;
                end
            else begin
                sd_spi_init_baud_s  <= 1'b0;
                init_baud_count_s   <= init_baud_count_s + 1;
            end
        end
    end
    
    // This block generates the normal operation clock rate
    // Note that the clock is essentially a tick valid only for 
    // one 210 MHz clock period.
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            normal_baud_count_s     <= 16'd0;
            sd_spi_normal_baud_s    <= 1'b0;
            end
        else begin
            if (normal_baud_count_s == NORMAL_BAUD_CLK_DIV_c) begin
                sd_spi_normal_baud_s    <= 1'b1;
                normal_baud_count_s     <= 16'd0;
                end
            else begin
                sd_spi_normal_baud_s    <= 1'b0;
                normal_baud_count_s     <= normal_baud_count_s + 1;
            end
        end
    end
    
    
    
endmodule

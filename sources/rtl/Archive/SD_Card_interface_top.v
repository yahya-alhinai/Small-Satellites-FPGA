`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2017 04:01:49 PM
// Design Name: 
// Module Name: SD_Card_interface_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module is not only a wrapper with the SD SPI controller and the SD
// SPI Byte transfer, but also maintains status and health information of the SD Card 
// interface. Basically, it maintains the memory of the FIFOs in use, and talks to the 
// controller to send some information about what needs to be done next (after initialization)
// and also gets the status of the lower modules.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SD_Card_interface_top(
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
    
    wire                sd_spi_mosi_p;
    wire                sd_spi_miso_p;
    wire                sd_spi_ss_p;
    wire                sd_spi_sck_p;
    
    SD_Card_SPI_master SD_Card_SPI_master_inst(
    .clk210_p               (clk210_p),
    .reset_p                (reset_p),
    .sd_spi_mosi_p          (sd_spi_mosi_p),
    .sd_spi_miso_p          (sd_spi_miso_p),
    .sd_spi_ss_p            (sd_spi_ss_p),
    .sd_spi_sck_p           (sd_spi_sck_p),
    .sd_card_init_error_p   (sd_card_init_error_p),
    .sd_card_initialized_p  (sd_card_initialized_p),
    .sd_card_ccs_bit_p      (sd_card_ccs_bit_p)   
    );
    
    // fifo_sd_card_1 fifo_sd_1_inst(                                                  
    // .clk                        (clk210_p),                                    
    // .rst                        (reset_p),                                     
    // .din                        (fifo_sd_1_din_p),                               
    // .wr_en                      (fifo_sd_1_wr_en_p),                             
    // .rd_en                      (fifo_sd_1_rd_en_s),
    // .dout                       (fifo_sd_1_dout_s),
    // .full                       (fifo_sd_1_full_s),
    // .almost_full                (fifo_sd_1_almost_full_s),
    // .almost_empty               (fifo_sd_1_almost_empty_s),
    // .empty                      (fifo_sd_1_empty_p),
    // .data_count                 (fifo_sd_1_data_count_p)
    // );  
    
    
    
    
    
    
    
endmodule

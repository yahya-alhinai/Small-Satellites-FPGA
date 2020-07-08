`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2017 04:01:49 PM
// Design Name: 
// Module Name: SD_Card_SPI_master
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


module SD_Card_SPI_master(
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
    
    
    SD_Card_SPI_controller SD_Card_SPI_controller_inst(
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
	
 
	
	
endmodule

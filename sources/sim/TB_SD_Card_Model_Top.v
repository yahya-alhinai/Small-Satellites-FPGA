`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2017 02:56:43 PM
// Design Name: 
// Module Name: TB_SD_Card_Model_Top
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


module TB_SD_Card_Model_Top(
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
    
    
    TB_SD_Card_Spi_Slave SD_Card_Slave_inst(
    .clk_p              (clk_p),
    .tb_spi_miso_p      (tb_spi_miso_p),
    .tb_spi_mosi_p      (tb_spi_mosi_p),
    .tb_spi_sck_p       (tb_spi_sck_p),
    .tb_spi_ss_p        (tb_spi_ss_p)
    );
    
    
    
endmodule

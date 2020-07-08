`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/14/2017 08:13:14 PM
// Design Name: 
// Module Name: SD_Card_test_top
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


module SD_Card_test_top(
    clk12_in_p,
    reset_p,
    uart_tx_p,
    uart_rx_p,
    sd_spi_miso_p,
    sd_spi_sck_p,
    sd_spi_mosi_p,
    sd_spi_ss_p,
    sd_card_ccs_bit_p,
    sd_spi_init_done_p,
    sd_spi_transfer_done_p  
    );
    
    input               clk12_in_p;
    input               reset_p;
    input               uart_rx_p;
    input               sd_spi_miso_p;
    
    output              sd_spi_mosi_p;
    output              sd_spi_ss_p;
    output              sd_spi_sck_p;
    output              uart_tx_p;
    output              sd_card_ccs_bit_p;
    output              sd_spi_init_done_p;
    output              sd_spi_transfer_done_p;
    //-----------------------------------------------------------------------//
    // variable declarations
    wire        [63:0]  timekeeper_time_s;
    wire        [15:0]  adc_1_current_data_s;
    wire        [15:0]  fpga_die_temp_s;
    wire        [15:0]  memory_map_uart_adrs_s;
    wire        [15:0]  memory_map_uart_rd_data_s;
    wire        [15:0]  sd_spi_cntrl_status_s;
    
    wire                sd_spi_mosi_p;
    wire                sd_spi_miso_p;
    wire                sd_spi_ss_p;
    wire                sd_spi_sck_p;

    
    // SD_Card_interface_top SD_Card_interface_top_inst(
    // .clk210_p               (clk210_p),
    // .reset_p                (reset_p),
    // .sd_spi_mosi_p          (sd_spi_mosi_p),
    // .sd_spi_miso_p          (sd_spi_miso_p),
    // .sd_spi_ss_p            (sd_spi_ss_p),
    // .sd_spi_sck_p           (sd_spi_sck_p),
    // .sd_card_init_error_p   (sd_card_init_error_p),
    // .sd_card_initialized_p  (sd_card_initialized_p),
    // .sd_card_ccs_bit_p      (sd_card_ccs_bit_p),
    // .key_press_p            (key_press_p)   
    // );
    
    SD_Card_SPI_controller FPGA_SD_Controller_inst(
    .clk210_p               (clk210_p),
    .reset_p                (reset_p),
    .sd_spi_mosi_p          (sd_spi_mosi_p),
    .sd_spi_miso_p          (sd_spi_miso_p),
    .sd_spi_ss_p            (sd_spi_ss_p),
    .sd_spi_sck_p           (sd_spi_sck_p),
    .sd_ccs_bit_p           (sd_card_ccs_bit_p),
    .sd_spi_init_done_p     (sd_spi_init_done_p),
    .sd_spi_transfer_done_p (sd_spi_transfer_done_p),
    .sd_spi_cntrl_status_p  (sd_spi_cntrl_status_s)
    );
    
    
    uart_top UART_debugging_top(
    .clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.tx_p						(uart_tx_p),
	.rx_p						(uart_rx_p),
	.memory_map_adrs_p			(memory_map_uart_adrs_s),
	.memory_map_rd_data_p		(memory_map_uart_rd_data_s)
    );
    
    memory_map Memory_Map_inst(
    .clk210_p					(clk210_p),
	.reset_p					(reset_p),
    .memory_map_uart_adrs_p     (memory_map_uart_adrs_s),
    .memory_map_uart_rd_data_p  (memory_map_uart_rd_data_s),
    .memory_map_spi_addr_p      (memory_map_spi_addr_s),
    .memory_map_spi_wr_data_p   (memory_map_spi_wr_data_s),
    .memory_map_spi_wr_en_p     (memory_map_spi_wr_en_s),
    .memory_map_spi_rd_en_p     (memory_map_spi_wr_en_s),
    .memory_map_spi_rd_data_p   (memory_map_spi_rd_data_s),
    .current_adc_1_data_p       (adc_1_current_data_s),
    .fpga_die_temperature_p     (fpga_die_temp_s),
    .timekeeper_time_p          (timekeeper_time_s),
    .sd_spi_cntrl_status_p      (sd_spi_cntrl_status_s)
    );
    
    clk_mmcm_1 MMCM_inst(           
    .clk_in1			(clk12_in_p),                       // INPUT  -  1 bit  - 12 MHz clock input
	.clk_out1			(clk210_p),                         // OUTPUT -  1 bit  - 10 MHz clock output
	.locked				(locked),                           // OUTPUT -  1 bit  - locked output
	.reset				(reset_p)                           // INPUT  -  1 bit  - global reset
    );        
    
    device_temp XADC_inst(
    .clk210_p                   (clk210_p),                     // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                    (reset_p),                      // INPUT  -  1 bit  - global reset
    .fpga_die_temp_p            (fpga_die_temp_s)               // OUTPUT - 16 bits - FPGA die temperature
    );
    
    
    
endmodule

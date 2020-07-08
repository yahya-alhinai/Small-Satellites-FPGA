`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2017 09:25:05 PM
// Design Name: 
// Module Name: TB_FPGA_Top
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


module TB_FPGA_Top(

    );
    
    // reg                 clk210_p    = 1'b0;
    reg                 clk12_in_p    = 1'b0;
    reg                 reset_p     = 1'b0;
    reg                 clk_p     = 1'b0;
    
    wire                adc_1_cnv_s;
    wire                adc_1_sck_s;
    wire                adc_1_sdo_s;
    
//    wire        [15:0]  adc_data_in_p;
//    wire                timekeeper_ready_s;
//    wire        [ 1:0]  adc_sampling_mode_s;
//    wire        [63:0]  timekeeper_time_s;
//    wire        [15:0]  adc_threshold_s;
//    wire        [15:0]  adc_1_current_data_p;
    
    wire                spi_miso_p;
    wire                spi_sck_p;
    wire                spi_ss_p;
    wire                spi_mosi_p;
    reg          [15:0] memory_map_spi_wr_addr_debug_p = 16'h0;
    reg          [15:0] memory_map_spi_wr_data_debug_p = 16'h0;
    reg                 memory_map_spi_wr_en_debug_p = 1'b0;
    
    //-----------------------------------------------------------------------//
    // Assignments
    //-----------------------------------------------------------------------//
//    assign              adc_sampling_mode_s     = 2'b01;
//    assign              timekeeper_ready_s      = 1'b1;
//    assign              adc_threshold_s         = 16'd500;
    
    // always # 2.3809523 clk210_p <= ~clk210_p; // 210 MHz clock
    always # 0.5       clk_p    <= ~clk_p;  
    always # 41.660    clk12_in_p   <= ~clk12_in_p;
    
	initial
		begin
			reset_p			<= 1'b1;
			#1000
			reset_p			<= 1'b0;
			#1000000
			memory_map_spi_wr_addr_debug_p <= 16'h53;
            memory_map_spi_wr_data_debug_p <= 16'h1;
            memory_map_spi_wr_en_debug_p <= 1'b1;
            #900000
			memory_map_spi_wr_addr_debug_p <= 16'h0;
            memory_map_spi_wr_data_debug_p <= 16'h0;
            memory_map_spi_wr_en_debug_p <= 1'b0;
		end
    
    TB_adc_model ADC_model_inst(
    .reset_p                (reset_p),                  // INPUT  -  1 bit  - reset
    .cnv_p                  (adc_1_cnv_s),              // INPUT  -  1 bit  - cnv for ADC
    .sdo_p                  (adc_1_sdo_s),              // OUTPUT -  1 bit  - data from the ADC model    
    .sck_p                  (adc_1_sck_s)               // INPUT  -  1 bit  - SCK
    );
    
   TB_SD_Card_Model_Top SD_Card_Slave_inst(
   .clk_p              (clk_p),
   .tb_spi_miso_p      (spi_miso_p),
   .tb_spi_mosi_p      (spi_mosi_p),
   .tb_spi_sck_p       (spi_sck_p),
   .tb_spi_ss_p        (spi_ss_p)
   );
    
    FPGA_TOP FPGA_TOP_inst(
    .clk12_in_p             (clk12_in_p),
    .reset_p                (reset_p),
    .uart_tx_p              (uart_tx_p),
    .uart_rx_p              (uart_rx_p),
    .adc_1_cnv_p            (adc_1_cnv_s),
    .adc_1_sck_p            (adc_1_sck_s),
    .adc_1_sdo_p            (adc_1_sdo_s),
    .sd_spi_miso_p          (spi_miso_p),
    .sd_spi_sck_p           (spi_sck_p),
    .sd_spi_mosi_p          (spi_mosi_p),
    .sd_spi_ss_p            (spi_ss_p),
    .sd_spi_init_done_p     (sd_spi_init_done_p),
    .sd_spi_transfer_done_p (sd_spi_transfer_done_p)
    //.memory_map_spi_wr_addr_debug_p (memory_map_spi_wr_addr_debug_p),
    //.memory_map_spi_wr_data_debug_p (memory_map_spi_wr_data_debug_p),
    //.memory_map_spi_wr_en_debug_p (memory_map_spi_wr_en_debug_p)
    );
    
    // SD_Card_SPI_controller FPGA_SD_Controller_inst(
    // .clk210_p               (clk210_p),
    // .reset_p                (reset_p),
    // .sd_spi_mosi_p          (spi_mosi_p),
    // .sd_spi_miso_p          (spi_miso_p),
    // .sd_spi_ss_p            (spi_ss_p),
    // .sd_spi_sck_p           (spi_sck_p)
    // );
    
    // FPGA_TOP FPGA_TOP_inst(
    // .clk12_in_p               (clk12_in_p),
    // .reset_p                (reset_p),
    // .sd_spi_mosi_p          (spi_mosi_p),
    // .sd_spi_miso_p          (spi_miso_p),
    // .sd_spi_ss_p            (spi_ss_p),
    // .sd_spi_sck_p           (spi_sck_p)
    // );
   
    
    
    
endmodule

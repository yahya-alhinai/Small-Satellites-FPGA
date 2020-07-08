`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2017 08:59:17 AM
// Design Name: 
// Module Name: TB_SD_Card_Test
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


module TB_SD_Card_Test(

    );
    
    reg         clk210_p  = 1'b0;
    reg         clk_p     = 1'b0;
    reg         reset_p   = 1'b0;
    
    wire        spi_miso_p;
    wire        spi_mosi_p;
    wire        spi_sck_p;
    wire        spi_ss_p;
    
    SD_Card_interface_top SD_Card_interface_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .sd_spi_mosi_p              (sd_spi_mosi_p),
    .sd_spi_miso_p              (sd_spi_miso_p),
    .sd_spi_ss_p                (sd_spi_ss_p),
    .sd_spi_sck_p               (sd_spi_sck_p),
    .sd_spi_init_done_p         (sd_spi_init_done_p),
    .sd_spi_transfer_done_p     (sd_spi_transfer_done_p),
    .sd_spi_cntrl_status_p      (sd_spi_cntrl_status_s),
    .sd_ccs_bit_p               (sd_card_ccs_bit_p),
    .sd_write_fifo_din_p        (sd_write_fifo_din_s),
    .sd_write_fifo_wr_en_p      (sd_write_fifo_wr_en_s),
    .sd_write_fifo_full_p       (sd_write_fifo_full_s),
    .fc_fifo_tx_din_p           (fc_fifo_tx_din_p),
    .fc_fifo_tx_wr_en_p         (fc_fifo_tx_wr_en_p),
    .fc_sd_read_cmd_p           (fc_sd_read_cmd_p),
    .sd_sectors_written_p       (sd_sectors_written_p)
    // .sd_read_fault_p            (sd_read_fault_p)
    );
    
    Detector_Top Detector_Top_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .adc_1_cnv_p                (adc_1_cnv_p),
    .adc_1_sck_p                (adc_1_sck_p),
    .adc_1_sdo_p                (adc_1_sdo_p),
    .adc_1_current_data_p       (adc_1_current_data_s),
    .timekeeper_time_p          (timekeeper_time_s),
    .timekeeper_ready_p         (timekeeper_ready_s),
    .adc_threshold_p            (adc_threshold_s),
    .adc_sampling_mode_p        (adc_sampling_mode_s),
    .sd_write_fifo_din_p        (sd_write_fifo_din_s),
    .sd_write_fifo_full_p       (sd_write_fifo_full_s),
    .sd_write_fifo_wr_en_p      (sd_write_fifo_wr_en_s)
    );
    
    
    
    TB_SD_Card_Model_Top SD_Card_Slave_inst(
    .clk_p              (clk_p),
    .tb_spi_miso_p      (spi_miso_p),
    .tb_spi_mosi_p      (spi_mosi_p),
    .tb_spi_sck_p       (spi_sck_p),
    .tb_spi_ss_p        (spi_ss_p)
    );
    
    always # 2.3809523 clk210_p <= ~clk210_p;
	always # 0.5       clk_p    <= ~clk_p;    
    
	initial
		begin
			reset_p			<= 1'b1;
			#1000
			reset_p			<= 1'b0;
		end
    
endmodule

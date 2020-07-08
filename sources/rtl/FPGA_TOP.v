`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2017 09:06:56 PM
// Design Name: 
// Module Name: FPGA_TOP
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


module FPGA_TOP(
    clk12_in_p,                 // INPUT  -  1 bit  - 12 MHz clock input
    reset_p,
    uart_tx_p,
    uart_rx_p,
    adc_1_cnv_p,
    adc_1_sck_p,
    adc_1_sdo_p,
    sd_spi_miso_p,
    sd_spi_sck_p,
    sd_spi_mosi_p,
    sd_spi_ss_p,
    sd_spi_init_done_p,
    sd_card_ccs_bit_p,
    sd_spi_transfer_done_p,
    fc_spi_mosi_p,
    fc_spi_miso_p,
    fc_spi_sck_p,
    fc_spi_ss_p,
    sd_format_button_p,
    pps_gps_p,                 // pin 18 on FPGA    sd_card_format_led_1_p,
    sd_card_format_led_2_p
    );
    
    input               clk12_in_p;
    input               reset_p;
    input               uart_rx_p;
    input               adc_1_sdo_p;
    input               sd_spi_miso_p;
    input               fc_spi_mosi_p;
    input               fc_spi_sck_p;
    input               fc_spi_ss_p;
    input               sd_format_button_p;
    input               pps_gps_p;

    output              sd_spi_mosi_p;
    output              sd_spi_ss_p;
    output              sd_spi_sck_p;
    output              sd_spi_init_done_p;
    output              uart_tx_p;
    output              adc_1_cnv_p;
    output              adc_1_sck_p;
    output              sd_card_ccs_bit_p;
    output              sd_spi_transfer_done_p;
    output              fc_spi_miso_p;
    output              sd_card_format_led_1_p;
    output              sd_card_format_led_2_p;
    
    //-----------------------------------------------------------------------//
    // variable declarations
    //-----------------------------------------------------------------------//
    wire        [63:0]  timekeeper_time_s;
    wire        [15:0]  adc_1_current_data_s;
    wire        [15:0]  fpga_die_temp_s;
    wire        [15:0]  memory_map_uart_adrs_s;
    wire        [15:0]  memory_map_uart_rd_data_s;
    wire        [15:0]  memory_map_spi_rd_addr_p;
    wire        [15:0]  memory_map_spi_wr_addr_p;
    wire        [15:0]  memory_map_spi_rd_data_p;
    wire        [15:0]  memory_map_spi_wr_data_p;
    wire                memory_map_spi_wr_en_p;
    wire                memory_map_spi_rd_en_p;    
    //wire        [15:0]  memory_map_spi_wr_addr_debug_p;
    //wire        [15:0]  memory_map_spi_wr_data_debug_p;
    //wire                memory_map_spi_wr_en_debug_p;
    
    wire                timekeeper_ready_s;
    wire        [15:0]  adc_threshold_s;
    wire        [15:0]  adc_sampling_mode_s;
    wire                fc_fifo_tx_ready_p;
    
    wire                sd_spi_mosi_p;
    wire                sd_spi_miso_p;
    wire                sd_spi_ss_p;
    wire                sd_spi_sck_p;
    wire        [ 7:0]  sd_write_fifo_din_s;
    wire                sd_write_fifo_full_s;
    wire                sd_write_fifo_wr_en_s;
    wire        [31:0]  sd_num_sectors_written_p;
    wire        [15:0]  sd_spi_cntrl_status_s;
    
    wire        [15:0]  fc_fifo_tx_din_p;
    wire                fc_fifo_tx_wr_en_p;
    wire                fc_sd_read_cmd_p;
    wire        [15:0]  fc_fifo_num_transfers_p;
    
    wire        [15:0]  FPGA_FC_sync_reg_p;
    wire        [63:0]  FC_GPS_start_time_p;
    wire                FC_SD_card_shutdown_p;
    wire        [ 1:0]  SD_card_shutdown_ready_p;
    
    wire                clk210_p;                               //Should be 105 KHz
    
    Detector_Top Detector_Top_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .adc_1_cnv_p                (adc_1_cnv_p),
    .adc_1_sck_p                (adc_1_sck_p),
    .adc_1_sdo_p                (adc_1_sdo_p),
    .adc_1_current_data_p       (adc_1_current_data_s),
    .timekeeper_time_p          (timekeeper_time_s),
    .timekeeper_ready_p         (1'b1),                         // debugging purposes only
    .adc_threshold_p            (adc_threshold_s),
    .adc_sampling_mode_p        (adc_sampling_mode_s),
    .sd_write_fifo_din_p        (sd_write_fifo_din_s),
    .sd_write_fifo_full_p       (sd_write_fifo_full_s),
    .sd_write_fifo_wr_en_p      (sd_write_fifo_wr_en_s)
    );
    
    
    device_temp XADC_inst(
    .clk210_p                   (clk210_p),                     // INPUT  -  1 bit  - 105 MHz clock
	.reset_p                    (reset_p),                      // INPUT  -  1 bit  - global reset
	.fpga_die_temp_p            (fpga_die_temp_s)               // OUTPUT - 16 bits - FPGA die temperature
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
    
    .memory_map_spi_wr_addr_p   (memory_map_spi_wr_addr_p),
    .memory_map_spi_wr_data_p   (memory_map_spi_wr_data_p),
    .memory_map_spi_wr_en_p     (memory_map_spi_wr_en_p),
    .memory_map_spi_rd_en_p     (memory_map_spi_rd_en_p),
    .memory_map_spi_rd_data_p   (memory_map_spi_rd_data_p),
    .memory_map_spi_rd_addr_p   (memory_map_spi_rd_addr_p),
    
    .current_adc_1_data_p       (adc_1_current_data_s),
    .fpga_die_temperature_p     (fpga_die_temp_s),
    .timekeeper_time_p          (timekeeper_time_s),
    .adc_threshold_p            (adc_threshold_s),
    
    .adc_sampling_mode_p        (adc_sampling_mode_s),
    .sd_spi_cntrl_status_p      (sd_spi_cntrl_status_s),
    .fc_fifo_tx_ready_p         (fc_fifo_tx_ready_p),
    .sd_sectors_written_p       (sd_num_sectors_written_p),
    .fc_fifo_num_transfers_p    (fc_fifo_num_transfers_p),
    
    .FPGA_FC_sync_reg_p         (FPGA_FC_sync_reg_p),
    .FC_GPS_start_time_p        (FC_GPS_start_time_p),
    .FC_SD_card_shutdown_p      (FC_SD_card_shutdown_p),
    .SD_card_shutdown_ready_p   (SD_card_shutdown_ready_p)
    );
    
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
    .sd_sectors_written_p       (sd_num_sectors_written_p),
    .FC_SD_card_shutdown_p      (FC_SD_card_shutdown_p),
    .SD_card_shutdown_ready_p   (SD_card_shutdown_ready_p),
    .sd_format_button_p         (sd_format_button_p),
    .sd_card_format_led_1_p     (sd_card_format_led_1_p),
    .sd_card_format_led_2_p     (sd_card_format_led_2_p)
    // .sd_read_fault_p            (sd_read_fault_p)
    );
    
    FC_interface_top FC_interface_top_inst(
    .clk210_p                   (clk210_p),                     // INPUT  -  1 bit  - 105 MHz clock
    .reset_p                    (reset_p),                      // INPUT  -  1 bit  - reset
    .fc_spi_mosi_p              (fc_spi_mosi_p),                // INPUT  -  1 bit  - MOSI from the FC (FC is the master)
    .fc_spi_miso_p              (fc_spi_miso_p),                // OUTPUT -  1 bit  - MISO to the FC (remember that the FC is the master
    .fc_spi_ss_p                (fc_spi_ss_p),                  // INPUT  -  1 bit  - FC slave select
    .fc_spi_sck_p               (fc_spi_sck_p),                 // INPUT  -  1 bit  - SCK from the FC
    .memory_map_spi_rd_data_p   (memory_map_spi_rd_data_p),     // INPUT  - 16 bits - data from the memory map 
    .memory_map_spi_wr_data_p   (memory_map_spi_wr_data_p),     // OUTPUT - 16 bits - data to the memory map
    .memory_map_spi_wr_addr_p   (memory_map_spi_wr_addr_p),     // OUTPUT - 16 bits - address to which data needs to be written to in the Memory Map    
    .memory_map_spi_rd_addr_p   (memory_map_spi_rd_addr_p),     // OUTPUT - 16 bits - address from which data needs to be obtained from
    .memory_map_spi_wr_en_p     (memory_map_spi_wr_en_p),       // OUTPUT -  1 bit  - write enable to the memory map
    .memory_map_spi_rd_en_p     (memory_map_spi_rd_en_p),       // OUTPUT -  1 bit  - read enable to the memory map
    .fc_fifo_tx_din_p           (fc_fifo_tx_din_p),
    .fc_fifo_tx_wr_en_p         (fc_fifo_tx_wr_en_p),
    .fc_fifo_tx_ready_p         (fc_fifo_tx_ready_p),
    .fc_sd_read_cmd_p           (fc_sd_read_cmd_p),
    .sd_num_sectors_written_p   (sd_num_sectors_written_p),
    .fc_fifo_num_transfers_p    (fc_fifo_num_transfers_p),      // OUTPUT - 16 bits - fifo counter used for indication whether there is an slave select glitch
    .fc_sd_shutdown_cmd_p       (fc_sd_shutdown_cmd_p)
    );
    
    
    Clock_Synchronization_Top Clock_Synchronization_inst(
    .clk210_p               (clk210_p),                     // INPUT  -  1 bit  - 105 MHz clock
	.reset_p                (reset_p),                      // INPUT  -  1 bit  - reset
	.timekeeper_time_p      (timekeeper_time_s),            // OUTPUT - 64 bits - time
	.timekeeper_ready_p     (timekeeper_ready_s),           // OUTPUT -  1 bit  - timekeeper is ready
    .FPGA_FC_sync_reg_p     (FPGA_FC_sync_reg_p),           // INPUT  - 16 bits - flags
    .FC_GPS_start_time_p    (FC_GPS_start_time_p),          // INPUT  - 64 bits - start time
    .pps_gps_p              (pps_gps_p)                     // INPUT  -  1 bit  - pps from gps module
    );
    
    
    clk_mmcm_1 MMCM_inst(           
    .clk_in1			(clk12_in_p),                      // INPUT  -  1 bit  - 100 MHz clock input
	.clk_out1			(clk210_p),                         // OUTPUT -  1 bit  - 210 MHz clock output
	.locked				(locked),                           // OUTPUT -  1 bit  - locked output
	.reset				(reset_p)                           // INPUT  -  1 bit  - global reset
    );          

endmodule

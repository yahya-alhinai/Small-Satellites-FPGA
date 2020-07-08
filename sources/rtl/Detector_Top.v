`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2017 01:25:45 PM
// Design Name: 
// Module Name: Detector_Top
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

// `define SAVE_PREPROCESSING_DATA
`define SAVE_PROCESSED_DATA

module Detector_Top(
    clk210_p,
    reset_p,
    adc_1_cnv_p,
    adc_1_sck_p,
    adc_1_sdo_p,
    adc_1_current_data_p,
    timekeeper_time_p,
    timekeeper_ready_p,
    adc_threshold_p,
    adc_sampling_mode_p,
    sd_write_fifo_din_p,
    sd_write_fifo_full_p,
    sd_write_fifo_wr_en_p
    );
    
    input               clk210_p;
    input               reset_p;
    input               adc_1_sdo_p;
    input               timekeeper_ready_p;
    input               timekeeper_time_p;
    input               adc_threshold_p;
    input               adc_sampling_mode_p;
    input               sd_write_fifo_full_p;
    
    output              adc_1_sck_p;
    output              adc_1_cnv_p;
    output              adc_1_current_data_p;
    output              sd_write_fifo_din_p;
    output              sd_write_fifo_wr_en_p;
    
    // Variable declarations
    wire        [15:0]  adc_1_current_data_p;
    wire        [15:0]  adc_1_current_data_s;
    wire        [63:0]  timekeeper_time_p;    
    wire        [15:0]  adc_threshold_p;
    wire        [ 1:0]  adc_sampling_mode_p;
    
    wire                fifo_adc_1_rd_en_p;
    wire        [ 9:0]  fifo_adc_1_data_count_p;
    wire        [79:0]  fifo_adc_1_dout_p;
    wire                fifo_adc_empty_p;
    
    wire                fifo_processing_1_rd_en_p;
    wire        [107:0] fifo_processing_1_dout_p;
    wire        [11:0]  fifo_processing_1_data_count_p;
    
    wire                sd_write_fifo_full_p;
    wire        [ 7:0]  sd_write_fifo_din_p;
    wire                sd_write_fifo_wr_en_p;
    
    
    // Output Assignments
    assign  adc_1_current_data_p = adc_1_current_data_s;
    
    preprocessing_top preprocessing_adc_1(
    .clk210_p               (clk210_p),               // INPUT  -  1 bit  - 210 MHz clock    
    .reset_p                (reset_p),                // INPUT  -  1 bit  - reset
    .adc_cnv_p              (adc_1_cnv_p),            // OUTPUT -  1 bit  - ADC CNV (conversion) signal
    .adc_sck_p              (adc_1_sck_p),            // OUTPUT -  1 bit  - ADC clock
    .adc_sdo_p              (adc_1_sdo_p),            // INPUT  -  1 bit  - data from the adc
    .adc_current_data_p     (adc_1_current_data_s),   // OUTPUT - 16 bits - current deserialized data from the ADC (will go into the memory map
//    .adc_threshold_p        (adc_threshold_p),        // INPUT  - 16 bits - threshold that is set by the Flight Computer. This comes from the Memory Map.
    .adc_sampling_mode_p    (adc_sampling_mode_p),    // INPUT  -  2 bits - The FC has the option to change the sampling mode. There are 4 options.    
    .timekeeper_ready_p     (timekeeper_ready_p),     // INPUT  -  1 bit  - indication that the timekeeper is ready
    .timekeeper_time_p      (timekeeper_time_p),      // INPUT  - 64 bits - a 64 bit time stamp from the timekeeper module
    .fifo_adc_rd_en_p       (fifo_adc_1_rd_en_p),     // INPUT  -  1 bit  - read enable from the processing to the preprocessed data FIFO
    .fifo_adc_data_count_p  (fifo_adc_1_data_count_p),// OUTPUT - 10 bits - gives a count of the number of elements filled in the FIFO    
    .fifo_adc_dout_p        (fifo_adc_1_dout_p),       // OUTPUT - 80 bits - data out line from the FIFO. (In the form of {time_stamp(64 bits), adc_data(16 bits)})
    .fifo_adc_empty_p       (fifo_adc_empty_p)
    );
    
    
    processing_top processing_adc_1(
    .clk210_p                       (clk210_p),                      // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                        (reset_p),                       // INPUT  -  1 bit  - reset
    .fifo_adc_rd_en_p               (fifo_adc_1_rd_en_p),            // OUTPUT -  1 bit  - read enable to the preprocessing FIFO
    .fifo_adc_data_count_p          (fifo_adc_1_data_count_p),       // INPUT  - 10 bits - data count of the preprocessing FIFO
    .fifo_adc_dout_p                (fifo_adc_1_dout_p),             // INPUT  - 80 bits - data out from the preprocessing FIFO (64 bit time stamp and 16 bit ADC value)
    .adc_threshold_p                (adc_threshold_p),               // INPUT  - 16 bits - threshold that is set by the Flight Computer. This comes from the Memory Map.
    .fifo_processing_rd_en_p        (fifo_processing_1_rd_en_p),     // INPUT  -  1 bit  - read enable for the processing FIFO
    .fifo_processing_dout_p         (fifo_processing_1_dout_p),      // OUTPUT -108 bits - dout from the processing FIFO 
    .fifo_processing_data_count_p   (fifo_processing_1_data_count_p), // OUTPUT - 12 bits - data count of the processing FIFO 
    .fifo_adc_empty_p                (fifo_adc_empty_p)
    );
    
    
   Data_Packetizer Data_Packetizer_inst(
   .clk210_p                        (clk210_p),                      // INPUT  -  1 bit  - 210 MHz clock
   .reset_p                         (reset_p),                       // INPUT  -  1 bit  - reset
   `ifdef SAVE_PREPROCESSING_DATA
   .fifo_adc_1_rd_en_p              (fifo_adc_1_rd_en_p),            // OUTPUT -  1 bit  - read enable to the FIFO
   .fifo_adc_1_data_count_p         (fifo_adc_1_data_count_p),       // INPUT  - 10 bits - FIFO data count    
   .fifo_adc_1_dout_p               (fifo_adc_1_dout_p),             // INPUT  - 80 bits - FIFO data output
   `endif
   `ifdef SAVE_PROCESSED_DATA
   .fifo_processing_1_rd_en_p       (fifo_processing_1_rd_en_p),     // OUTPUT -  1 bit  - read enable for the processing FIFO
   .fifo_processing_1_dout_p        (fifo_processing_1_dout_p),      // INPUT  -108 bits - dout from the processing FIFO   
   .fifo_processing_1_data_count_p  (fifo_processing_1_data_count_p),// INPUT  - 12 bits - data count of the processing FIFO 
   `endif
   .sd_write_fifo_din_p             (sd_write_fifo_din_p),           // OUTPUT -  8 bits - FIFO data in bus for the SD Card    
   .sd_write_fifo_wr_en_p           (sd_write_fifo_wr_en_p),         // OUTPUT -  1 bit  - FIFO write enable
   .sd_write_fifo_full_p            (sd_write_fifo_full_p)           // INPUT  -  1 bit  - Indicates that the FIFO is full
   );
    
    
    
endmodule

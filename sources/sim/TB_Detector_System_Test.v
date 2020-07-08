`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/02/2017 11:52:37 AM
// Design Name: 
// Module Name: TB_Detector_System_Test
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


module TB_Detector_System_Test(

    );
    
    
    reg                 clk210_p    = 1'b0;
    reg                 reset_p     = 1'b0;
    
    wire                adc_cnv_s;
    wire                adc_sck_s;
    wire                adc_sdo_s;
    
    wire        [15:0]  adc_data_in_p;
    wire                timekeeper_ready_s;
    wire        [ 1:0]  adc_sampling_mode_s;
    wire        [63:0]  timekeeper_time_s;
    wire        [15:0]  adc_threshold_s;
    wire        [15:0]  adc_1_current_data_p;
    
    //-----------------------------------------------------------------------//
    // Assignments
    //-----------------------------------------------------------------------//
    assign              adc_sampling_mode_s     = 2'b01;
    assign              timekeeper_ready_s      = 1'b1;
    assign              adc_threshold_s         = 16'd5000;
    
    always # 2.3809523 clk210_p <= ~clk210_p; // 210 MHz clock
    
    
    
	initial
		begin
			reset_p			<= 1'b1;
			#1000
			reset_p			<= 1'b0;
		end
    
    Detector_Top Detector_Top_inst(
    .clk210_p                   (clk210_p),
    .reset_p                    (reset_p),
    .adc_1_cnv_p                (adc_cnv_s),
    .adc_1_sck_p                (adc_sck_s),
    .adc_1_sdo_p                (adc_sdo_s),
    .adc_1_current_data_p       (adc_1_current_data_p),
    .timekeeper_time_p          (timekeeper_time_s),
    .timekeeper_ready_p         (timekeeper_ready_s),
    .adc_threshold_p            (adc_threshold_s),
    .adc_sampling_mode_p        (adc_sampling_mode_s)
    );
    
    
    Clock_Synchronization_Top Clock_Synchronization_inst(
    .clk210_p               (clk210_p),                 // INPUT  -  1 bit  - 210 MHz clock
	.reset_p                (reset_p),                  // INPUT  -  1 bit  - reset
	.timekeeper_time_p      (timekeeper_time_s),        // OUTPUT - 64 bits - time
	.timekeeper_ready_p     (timekeeper_ready_s)        // OUTPUT -  1 bit  - timekeeper is ready
    );
    
    TB_adc_model ADC_model_inst(
    .reset_p                (reset_p),                  // INPUT  -  1 bit  - reset
    .cnv_p                  (adc_cnv_s),                // INPUT  -  1 bit  - cnv for ADC
    .sdo_p                  (adc_sdo_s),                // OUTPUT -  1 bit  - data from the ADC model    
    .sck_p                  (adc_sck_s)                 // INPUT  -  1 bit  - SCK
    );
    
    
    
    
    
endmodule

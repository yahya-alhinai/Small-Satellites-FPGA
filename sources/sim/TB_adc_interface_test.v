`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2017 12:02:27 PM
// Design Name: 
// Module Name: TB_adc_interface_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This code is just to test the adc_interface module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TB_adc_interface_test(

    );
    
    reg             clk210_p    = 1'b0;
    reg             reset_p     = 1'b0;
    
    wire            sck_p;
    reg             sdo_p       = 1'b1;
    wire            cnv_p;
    wire            adc_data_received_p;
    wire    [15:0]  adc_data_in_p;
    
    
    
    always # 2.3809523 clk210_p <= ~clk210_p;
    
    
    adc_interface adc_inst(
    .clk210_p                   (clk210_p),             // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                    (reset_p),              // INPUT  -  1 bit  - reset signal
    .cnv_p                      (cnv_p),                // OUTPUT -  1 bit  - CNV for ADC
    .sck_p                      (sck_p),                // OUTPUT -  1 bit  - SCK for ADC
    .sdo_p                      (sdo_p),                // INPUT  -  1 bit  - SDO from ADC
    .adc_data_received_p        (adc_data_received_p),  // OUTPUT -  1 bit  - indicates that a word has been deserialized
    .adc_data_in_p              (adc_data_in_p)         // OUTPUT - 16 bits - data received from the ADC
    );
    
    
    
    
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/29 10:23:07
// Design Name: 
// Module Name: CF_Test
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


module CF_Test();
    wire fifo_adc_rd_en_p;
    wire [15:0] result_a;
    wire [7:0]  result_c;
    wire [20:0] error;
    reg [9:0]   fifo_adc_data_count_p;
    reg [79:0]  fifo_adc_dout_p;
    
    reg clk210_p = 0;
    reg reset_p  = 0;
    reg [15:0] inputdata [1:16];
    reg [4:0] index = 1;
    processing_top CF_Test(
    .clk210_p                   (clk210_p),                   // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                    (reset_p),                    // INPUT  -  1 bit  - reset
    .fifo_adc_rd_en_p           (fifo_adc_rd_en_p),           // OUTPUT -  1 bit  - read enable to the preprocessing FIFO
    .fifo_adc_data_count_p      (fifo_adc_data_count_p),      // INPUT  - 10 bits - data count of the preprocessing FIFO
    .fifo_adc_dout_p            (fifo_adc_dout_p),            // INPUT  - 80 bits - data out from the preprocessing FIFO (64 bit time stamp and 16 bit ADC value)
    .result_a                   (result_a),
    .result_c                   (result_c),
    .error                      (error)
    );

    
    always
        #1  clk210_p=~clk210_p;
    initial
    begin
        inputdata[1]<=5166;
        inputdata[2]<=5668;
        inputdata[3]<=6142;
        inputdata[4]<=6570;
        inputdata[5]<=6936;
        inputdata[6]<=7224;
        inputdata[7]<=7448;
        inputdata[8]<=7598;
        inputdata[9]<=7686;
        inputdata[10]<=7726;
        inputdata[11]<=7740;
        inputdata[12]<=7684;
        inputdata[13]<=7594;
        inputdata[14]<=7494;
        inputdata[15]<=7354;
        inputdata[16]<=7190;
        #10 reset_p= 1;
        #50 reset_p= 0;
        fifo_adc_data_count_p = 'd18;
    end
    
    always @(posedge clk210_p)
    begin
        if(fifo_adc_rd_en_p & (index < 'd17))
        begin
            fifo_adc_dout_p <= inputdata[index];
            index <= index + 1;
        end
    end
endmodule

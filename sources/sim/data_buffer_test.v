`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/02/17 15:45:06
// Design Name: 
// Module Name: data_buffer_test
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


module data_buffer_test();
//    reg [15:0] testin;
    reg clock=0;
    wire tx;
//    wire [15:0] para;
//    wire [15:0] para2;
    
    data_buffer data_buffer_test(
//    .Datain(testin),
    .clk(clock),
    .uart_out(tx)
//    .para(para)
//    .para2(para2)
    );
    
//    always
//    begin
//    #1.25  clock=~clock;
//    end
    
//    initial
//    begin
//        testin=0;
//        #120
//        testin=5166;
//        #2.5
//        testin=5668;
//        #2.5
//        testin=6142;
//        #2.5
//        testin=6570;
//        #2.5
//        testin=6936;
//        #2.5
//        testin=7224;
//        #2.5
//        testin=7448;
//        #2.5
//        testin=7598;
//        #2.5
//        testin=7686;
//        #2.5
//        testin=7726;
//        #2.5
//        testin=7740;
//        #2.5
//        testin=7684;
//        #2.5
//        testin=7594;
//        #2.5
//        testin=7494;
//        #2.5
//        testin=7354;
//        #2.5
//        testin=7190;
//        #2.5
//        testin=1;       // 17th data
//        #2.5
//        testin=0;
//    end
    
    always
    begin
    #5  clock=~clock;
    end
    
//    initial
//    begin
//        testin=0;
//        #120
//        testin=5166;
//        #20
//        testin=5668;
//        #20
//        testin=6142;
//        #20
//        testin=6570;
//        #20
//        testin=6936;
//        #20
//        testin=7224;
//        #20
//        testin=7448;
//        #20
//        testin=7598;
//        #20
//        testin=7686;
//        #20
//        testin=7726;
//        #20
//        testin=7740;
//        #20
//        testin=7684;
//        #20
//        testin=7594;
//        #20
//        testin=7494;
//        #20
//        testin=7354;
//        #20
//        testin=7190;
//        #20
//        testin=4999;       // 17th data
//        #20
//        testin=0;
//    end
    
endmodule

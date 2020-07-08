`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2017 07:14:27 AM
// Design Name: 
// Module Name: cd_conversion
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
// Turn the next line on to enable debugging mode
//`define DEBUGGING_MODE

module cd_conversion(
sysclk,
rst,
data_out,
clk105,
clk350,
locked,
data_in,
fill_data
`ifdef DEBUGGING_MODE
,
counter,
din1,
dout1,
wr_en1,
rd_en1,
almost_full1,
full1,
empty1,
din2,
dout2,
wr_en2,
rd_en2,
almost_full2,
full2,
empty2,
wr_state,
rd_state,
read_fifo1_105,
//read_sync_1,
read_fifo1_350,
read_fifo2_105,
//read_sync_2,
read_fifo2_350,
d11,
d12,
d21,
d22
`endif
    );
    
input sysclk;
input clk105,clk350;
input rst;
input locked;
input data_in;
input fill_data;

output data_out;

`ifdef DEBUGGING_MODE
output counter;
output din1,dout1;
output wr_en1,rd_en1,almost_full1,full1,empty1;
output din2,dout2;
output wr_en2,rd_en2,almost_full2,full2,empty2;
output rd_state,wr_state;

output read_fifo1_105;
//output read_sync_1;
output read_fifo1_350;
output read_fifo2_105;
//output read_sync_2;
output read_fifo2_350;

output d11,d12,d21,d22;
`endif
//------------------------------//
// variable declaration
wire sysclk;
wire rst;
reg nt1 = 0;
reg nt2 = 0;
reg [15:0] data_out = 16'd0;
wire [15:0] data_in;
wire fill_data;

// PLL
wire clk105;
wire clk350;
wire locked;

// FIFO 1
wire [15:0] din1;
wire [15:0] dout1;
reg wr_en1 = 1'b0;
reg rd_en1 = 1'b0;
wire almost_full1;
wire full1;
wire empty1;

// FIFO 2
wire [15:0] din2;
wire [15:0] dout2;
reg wr_en2 = 1'b0;
reg rd_en2 = 1'b0;
wire almost_full2;
wire full2;
wire empty2;

// test cases
reg [15:0] data = 16'd0;
reg [4:0] counter = 5'd0;
reg [3:0] wr_state = 4'd0;
reg [3:0] rd_state = 4'd0;

//------------------------------//
// PLL
//pll1 pll_inst(
//.clk_in1(sysclk),
//.clk_out1(clk100),
//.clk_out2(clk105),
//.clk_out3(clk350),
//.locked(locked),
//.reset(rst)
//);

//------------------------------//
// FIFO declarations
fifo_1 fifo_inst_1(
.rst(rst),
.wr_clk(clk105),
.rd_clk(clk350),
.din(din1),
.wr_en(wr_en1),
.rd_en(rd_en1),
.dout(dout1),
.full(full1),
.almost_full(almost_full1),
.empty(empty1),
.almost_empty(almost_empty1)
); 
    
fifo_2 fifo_inst_2(
.rst(rst),
.wr_clk(clk105),
.rd_clk(clk350),
.din(din2),
.wr_en(wr_en2),
.rd_en(rd_en2),
.dout(dout2),
.full(full2),
.almost_full(almost_full2),
.empty(empty2),
.almost_empty(almost_empty2)
);

//------------------------------//
// test cases - writing data
assign din1 = data;
assign din2 = data;

always @(posedge clk105)
begin
    if((~rst)&locked==1'b1)
        begin
            case(wr_state)
            4'd0:   // this is simulating the ADC data time intervals which arrives at 5 MHz
                begin
//                    if(counter == 5'd21)
//                        begin
//                            data <= data + 1'b1;
//                            wr_state <= 4'd1;
//                        end
//                    else
//                        wr_state <= 4'd0;
                    if(fill_data)
                        begin
                            data <= data_in;
                            wr_state <= 4'd1;
                        end
                    else
                        wr_state <= 4'd0;
                end
            4'd1:   // here's where data is written to FIFO1
                begin
                    wr_en1 <= 1'b1;
                    wr_state <= 4'd2;
                end
            4'd2:   // end write enable
                begin
                    wr_en1 <= 1'b0;
                    wr_state <= 4'd3;
                end
            4'd3:
                begin
                    if(~full1)
                        wr_state <= 4'd0;
                    else
                        wr_state <= 4'd4;
                end
            4'd4:
                begin
//                    if(counter == 5'd21)
//                        begin
//                            data <= data + 1'b1;
//                            wr_state <= 4'd5;
//                        end
                    if(fill_data)
                        begin
                            data <= data_in;
                            wr_state <= 4'd5;
                        end
                    else
                        wr_state <= 4'd4;
                end                
            4'd5:   // here's where data is written to FIFO2
                begin
                    wr_en2 <= 1'b1;
                    wr_state <= 4'd6;
                end
            4'd6:
                begin
                    wr_en2 <= 1'b0;
                    wr_state <= 4'd7;
                end
            4'd7:
                begin
                    if(~full2)
                        wr_state <= 4'd4;
                    else
                        wr_state <= 4'd0;
                end
            default: wr_state <= 4'd0;
            endcase
        end
    else
        nt1 <= nt1;     
end

//------------------------------//
// Read flags crossing to 350MHz domain from 105MHz domain
// Read flag from FIFO1   

reg d11 = 0;
reg d12 = 0;
reg d13 = 0;
reg d21 = 0;
reg d22 = 0;
reg d23 = 0;

reg read_fifo1_350;
reg read_fifo2_350;

always @(posedge clk105)
begin
    d11 <= full1;
end

always @(posedge clk350)
begin
    d12 <= d11;
    d13 <= d12;
    read_fifo1_350 <= d13;
end

always @(posedge clk105)
begin
    d21 <= full2;
end

always @(posedge clk350)
begin
    d22 <= d21;
    d23 <= d22;
    read_fifo2_350 <= d23;
end

//------------------------------//
// reading data from the FIFOs
always @(posedge clk350)
begin
    if((~rst)&locked==1'b1)
        begin
            case(rd_state)
            4'd0:
                begin
                    if(read_fifo1_350)
                        rd_state <= 4'd1;
                    else
                        rd_state <= 4'd0;
                end
            4'd1:
                begin
                    if(~empty1)
                        begin
                            rd_en1 <= 1'b1;
                            rd_state <= 4'd2;
                        end
                    else
                        rd_state <= 4'd4;
                end
            4'd2:
                begin
                    rd_en1 <= 1'b0;
//                    data_out <= dout1;
                    rd_state <= 4'd3;
                end
            4'd3:
                begin
                    data_out <= dout1;
                    rd_state <= 4'd1;
                end
            4'd4:
                begin
                    if(read_fifo2_350)
                        rd_state <= 4'd5;
                    else
                        rd_state <= 4'd4;
                end
            4'd5:
                begin
                    if(~empty2)
                        begin
                            rd_en2 <= 1'b1;
                            rd_state <= 4'd6;
                        end
                    else
                        rd_state <= 4'd0;
                end
            4'd6:
                begin
                    rd_en2 <= 1'b0;
                    data_out <= dout2;
                    rd_state <= 4'd7;
                end
            4'd7:
                begin
                    data_out <= dout2;
                    rd_state <= 4'd5;
                end
            default: rd_state <= 4'd0;
            endcase
        end
    else
        nt2 <= nt2;
end

//------------------------------//
    
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2017 02:06:24 PM
// Design Name: 
// Module Name: shift_register
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


module shift_register(
clk105,
sdo,
data_out,
data_adc,
reset,
start_recording
//debugging
,
state
    );
    
input clk105;
input sdo;
input reset;
input start_recording;

output data_out;
output data_adc;
//debugging
output state;


//------------------------------//
//parameters
parameter d0 = 5'd0;
parameter d1 = 5'd1;
parameter d2 = 5'd2;
parameter d3 = 5'd3;
parameter d4 = 5'd4;
parameter d5 = 5'd5;
parameter d6 = 5'd6;
parameter d7 = 5'd7;
parameter d8 = 5'd8;
parameter d9 = 5'd9;
parameter d10 = 5'd10;
parameter d11 = 5'd11;
parameter d12 = 5'd12;
parameter d13 = 5'd13;
parameter d14 = 5'd14;
parameter d15 = 5'd15;
parameter idle = 5'd16;
parameter rec = 5'd17;

//------------------------------//
//variable declaration
wire sdo;
wire start_recording;

reg [15:0] data_out = 16'd0;
reg [15:0] data_adc = 16'd0;
reg [4:0] counter;
reg [4:0] state = idle;

//------------------------------//
//state machine
always @(negedge clk105)
begin
    if(~reset)
        begin
            case(state)    
            idle:
                begin
                    if(start_recording)
                        state <= d15;
                    else
                        begin
                            state <= idle;
                            data_out <= 16'd0;
                        end
                end
            d15:
                begin
                    state <= d14;
                    data_out[15] <= sdo;
                end 
            d14:
                begin
                    state <= d13;
                    data_out[14] <= sdo;
                end 
            d13:
                begin
                    state <= d12;
                    data_out[13] <= sdo;
                end 
            d12:
                begin
                    state <= d11;
                    data_out[12] <= sdo;
                end 
            d11:
                begin
                    state <= d10;
                    data_out[11] <= sdo;
                end 
            d10:
                begin
                    state <= d9;
                    data_out[10] <= sdo;
                end 
            d9:
                begin
                    state <= d8;
                    data_out[9] <= sdo;
                end 
            d8:
                begin
                    state <= d7;
                    data_out[8] <= sdo;
                end 
            d7:
                begin
                    state <= d6;
                    data_out[7] <= sdo;
                end 
            d6:
                begin
                    state <= d5;
                    data_out[6] <= sdo;
                end 
            d5:
                begin
                    state <= d4;
                    data_out[5] <= sdo;
                end 
            d4:
                begin
                    state <= d3;
                    data_out[4] <= sdo;
                end 
            d3:
                begin
                    state <= d2;
                    data_out[3] <= sdo;
                end 
            d2:
                begin
                    state <= d1;
                    data_out[2] <= sdo;
                end 
            d1:
                begin
                    state <= d0;
                    data_out[1] <= sdo;
                end  
            d0:
                begin
                    state <= rec;
                    data_out[0] <= sdo;
                end 
            rec:
                begin
                    data_adc <= data_out;
                    state <= idle;
                end
            default:
                state <= state;
            endcase
        end
    else
        state <= idle;
end


    
endmodule

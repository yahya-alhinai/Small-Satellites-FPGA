`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2017 04:06:03 PM
// Design Name: 
// Module Name: baud_generator
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


module baud_generator(
	clk210_p,
	reset_p,
	baud_16_x_p,
	baud_1_x_p
	);
		
	input clk210_p;
	input reset_p;
	
	output baud_16_x_p;
	output baud_1_x_p;
	
	// variable decalarations
	reg	[15:0]	baud_16_x_counter_s			= 16'd0;
	reg 	[15:0]	baud_1_x_counter_s			= 16'd0;
(* mark_debug = "true" *)	reg			baud_16_x_p					= 1'd0;
	reg			baud_1_x_p					= 1'd0;
	
	//parameter declarations
	parameter	[15:0]	BAUD_16_X_COUNT_c	= 16'd57;		// 16 times 115200 for Rx//114 for 210 MHz, 57 for 105
    parameter   [15:0]  BAUD_1_X_COUNT_c    = 16'd912;      // 115200 for Tx // 1823,868//912 for 105MHz
	
	always @(posedge clk210_p)
	begin
		if(reset_p)
			begin
				baud_16_x_counter_s			<= 16'd0;
				baud_1_x_counter_s			<= 16'd0;
			end
		else
			begin
				if(baud_16_x_counter_s == BAUD_16_X_COUNT_c)
					begin
						baud_16_x_p			<= 1'b1;
						baud_16_x_counter_s	<= 16'd0;
					end
				else
					begin
						baud_16_x_p			<= 1'b0;	
						baud_16_x_counter_s	<= baud_16_x_counter_s + 1'b1;
					end
				if(baud_1_x_counter_s == BAUD_1_X_COUNT_c)
					begin
						baud_1_x_p			<= 1'b1;
						baud_1_x_counter_s	<= 16'd0;
					end
				else
					begin
						baud_1_x_p			<= 1'b0;	
						baud_1_x_counter_s	<= baud_1_x_counter_s + 1'b1;
					end
			end
	end

endmodule

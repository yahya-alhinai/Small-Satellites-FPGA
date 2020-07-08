`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/09/2017 08:51:05 PM
// Design Name: 
// Module Name: testbench
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


module testbench(

    );
	
	reg		clk210_p		= 1'd0;
	reg		reset_p			= 1'd0;
	reg		sdo_p			= 1'd1;
	wire	cnv_p;
	wire	sck_p;
	
	
	pulse_generator pulse_gen_inst(
	.clk210_p	(clk210_p),
	.reset_p	(reset_p),
	.cnv_p		(cnv_p),
	.sck_p		(sck_p),
	.sdo_p		(sdo_p)
	);
	
	always #2.38095238095 clk210_p <= ~clk210_p;
	
	initial
	begin
		reset_p				<= 1'b1;
		#100
		reset_p				<= 1'b0;
	end	
	
	
endmodule

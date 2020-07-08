`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2017 06:22:08 PM
// Design Name: 
// Module Name: device_temp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module instantiates the XADC module and provides data on the device_temp
// 				die temperature
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module device_temp(
	clk210_p,
	reset_p,
	fpga_die_temp_p
    );
	
	input			clk210_p;
	input			reset_p;
	
	output			fpga_die_temp_p;
	
	// variable declarations
	wire	[15:0]	fpga_die_temp_p;
	reg		[15:0]	fpga_die_temp_s;	
	
	wire	[ 6:0]	daddr_in_s;				// Address of the DRP bus
	wire	[15:0]	di_in_s;				// Data in
	wire			dwe_in_s;
	wire			busy_out_s;
	wire	[4:0]	channel_out_s;
	wire 	[15:0] 	do_out_s;
	wire			drdy_out_s;
	wire			eoc_out_s;				// End of COnversion
	wire			eos_out_s;
	wire 			alarm_out_s;
	wire			vp_in_s;
	wire			vn_in_s;
	
	// PARAMETER DECLARATIONS
	parameter	[6:0]	TEMP_ADDR_c	= 7'b00_0000;
	
	// ADC Module declaration
	// This is setup in the simplest possible way to capture just the temperature information.
	// Temperature can be found on the ADDRESS at 0x00 as indicated above. EOC(end of conversion) 
	// is used to trigger a read enable from the DRP and the temperature is read when DRDY (ready)
	// signal is raised.
	xadc_wiz_0	xadc_inst
	(
	.daddr_in			(daddr_in_s), 				// address bus for the DRP
	.dclk_in			(clk210_p),					// 210 MHz clock input
	.den_in				(eoc_out_s),				// enable signal for DRP
	.di_in				(di_in_s), 					// input data bus for the DRP
	.dwe_in				(dwe_in_s),					// write enable for the DRP
	.reset_in			(reset_p),					// reset
	.busy_out			(busy_out_s), 				// ADC busy. High during conversion
	.channel_out		(channel_out_s), 			// channel selection output
	.do_out				(do_out_s),					// output data bus for the DRP
	.drdy_out			(drdy_out_s), 				// data ready for the DRP
	.eoc_out			(eoc_out_s), 				// end of conversion signal
	.eos_out			(eos_out_s), 				// end of sequence signal
	.alarm_out			(alarm_out_s), 				// alarms
	.vp_in				(vp_in_s), 					// ext voltage pins (not used)
	.vn_in				(vn_in_s)					// ext voltage pins (not used)
	);
	
	assign 		fpga_die_temp_p	= fpga_die_temp_s;
	assign		daddr_in_s		= TEMP_ADDR_c;
	assign		vp_in_s			= 0;
	assign		vn_in_s			= 0;
	assign 		dwe_in_s		= 0;
	assign		di_in_s			= 0;
	
	always @(posedge clk210_p)
	begin
		if (reset_p) begin
			fpga_die_temp_s		<= 16'd0;
			end
		else begin
			if (drdy_out_s == 1) 									// Conversion is done and the DRP is ready to transfer
				fpga_die_temp_s	<= {4'd0,do_out_s[15:4]};		    // It is a 12 bit ADC...so get rid of the last 4 bits				
			else begin
				fpga_die_temp_s	<= fpga_die_temp_s;
			end
		end
	end
	
endmodule

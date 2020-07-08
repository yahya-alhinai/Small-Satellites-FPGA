`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/11/2017 09:48:30 AM
// Design Name: 
// Module Name: tb_uart_tx_rx
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


module tb_uart_tx_rx(
    );
	
	reg 			clk210_p				= 1'b0;
	reg 			reset_p					= 1'b1;
	
	// variable declaration
	wire 		baud_16_x_p;
	wire		baud_1_x_p;
	wire 		tx_p;
	wire 		rx_p;
	wire 		transmit_done_p;
	
	reg 			transmit_done_ack_p		= 1'b0;
	reg 			transmit_req_p			= 1'b0;
	reg	[7:0]	transmit_data_p			= 8'd0;
	
	wire[7:0]	received_data_p;
	wire		received_data_read_req_p;	
	
	reg			received_data_ack_p		= 1'b0;
	
	// Module Declaration
	uart_tx	tx_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_1_x_p					(baud_1_x_p),
	.tx_p						(tx_p),
	.transmit_data_p			(transmit_data_p),
	.transmit_req_p				(transmit_req_p),
	.transmit_done_p			(transmit_done_p),
	.transmit_done_ack_p		(transmit_done_ack_p)
	);
	
	uart_rx	rx_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.rx_p						(rx_p),
	.received_data_p			(received_data_p),
	.baud_16_x_p				(baud_16_x_p),
	.received_data_read_req_p	(received_data_read_req_p),
	.received_data_ack_p		(received_data_ack_p)
	);
	
	baud_generator	baud_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_16_x_p				(baud_16_x_p),
	.baud_1_x_p					(baud_1_x_p)
	);
	
	always #2.38095238095 clk210_p <= ~clk210_p;
	
	assign rx_p		= tx_p;
	
	initial
		begin
			reset_p				<= 1'b1;
			#200
			reset_p				<= 1'b0;
			#100
			transmit_data_p		<= 8'b11010101;
			#10000
			transmit_req_p		<= 1'b1;
			#1000
			if (transmit_done_p)
				transmit_done_ack_p		<= 1'b1;
			#1000
			transmit_done_ack_p	<= 1'b0;
			#1000
			if(received_data_read_req_p)
				received_data_ack_p	<= 1'b1;
			#1000
				received_data_ack_p		<= 1'b0;	
		end
	
endmodule

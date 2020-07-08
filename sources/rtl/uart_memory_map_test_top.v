`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2017 06:49:44 PM
// Design Name: 
// Module Name: uart_memory_map_test_top
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


module uart_memory_map_test_top(
	clock,
	reset_p,
	tx_p,
	rx_p
    );
	
	input			clock;
	input			reset_p;
	input			rx_p;
	
	output			tx_p;
	
	wire 	[79:0]	memory_map_rd_data_s;
	wire	[15:0]	memory_map_wr_data_s;
	wire	[15:0]	memory_map_adrs_s;
	wire			memory_map_wr_req_s;
	wire			memory_map_rd_ack_s;
	wire			memory_map_wr_ack_s;
	wire			memory_map_er_s;
	wire 			memory_map_rd_req_s;
	wire			memory_map_num_bytes_p;

clk_wiz_0	pll_inst(	
	.clk_in1					(clock),
	.reset						(reset_p),
	.clk_out1					(clk210_p),
	.locked						(locked)
	);	
	
	
uart_top 	uart_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.tx_p						(tx_p),
	.rx_p						(rx_p),
	.memory_map_adrs_p			(memory_map_adrs_s),
	.memory_map_wr_data_p		(memory_map_wr_data_s),
	.memory_map_rd_data_p		(memory_map_rd_data_s),
	.memory_map_wr_req_p		(memory_map_wr_req_s),
	.memory_map_rd_req_p		(memory_map_rd_req_s),
	.memory_map_rd_ack_p		(memory_map_rd_ack_s),	
	.memory_map_wr_ack_p		(memory_map_wr_ack_s),	
	.memory_map_er_p			(memory_map_er_s)	
	);	
	
memory_map	memory_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.memory_map_adrs_p			(memory_map_adrs_s),
	.memory_map_wr_data_p		(memory_map_wr_data_s),
	.memory_map_rd_data_p		(memory_map_rd_data_s),
	.memory_map_rd_data_req_p	(memory_map_rd_data_req_s),
	.memory_map_rd_ack_p		(memory_map_rd_ack_s),
	.memory_map_wr_ack_p		(memory_map_wr_ack_s),
	.memory_map_num_bytes_p		(memory_map_num_bytes_s),
	.memory_map_er_p			(memory_map_er_s)
	);
	
	
endmodule

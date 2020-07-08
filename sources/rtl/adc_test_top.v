`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2017 08:03:38 AM
// Design Name: 
// Module Name: adc_test_top
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


module adc_test_top(
	clk_in_p,
	cnv_p,
	sck_p,
	sdo_p,
	tx_p,
	reset_p
	);
	
	input				clk_in_p;
	input				sdo_p;
	input				reset_p;
	
	output				cnv_p;
	output				sck_p;
	output				tx_p;
	
	// Variables used
	reg			[7:0]	adc_test_state_s		= 8'd0;
	reg			[7:0]	transmit_data_p			= 8'd0;
	reg					transmit_req_p			= 1'd0;
	reg			[31:0]	reset_counter_s			= GLOBAL_RESET_COUNT_c;	// global power up reset for 10ms
	reg			[1:0]	reset_sync_s			= 2'd0;					// metastability synchronization to 
																		// change clock domain for the reset
																		// signal
	reg					transmit_done_ack_p		= 1'b0;
	reg			[79:0]	data_s					= 80'd0;
	wire		[79:0]	data_packet_s;
	wire				clk210_p;
	wire				baud_16_x_p;
	wire				baud_1_x_p;
	wire				reset210_p;
	wire				load_fifo_p;
	wire				reset_s;
	
	wire 		[79:0]	memory_map_rd_data_s;
	wire		[15:0]	memory_map_wr_data_s;
	wire		[15:0]	memory_map_adrs_s;
	wire				memory_map_wr_req_s;
	wire				memory_map_rd_ack_s;
	wire				memory_map_wr_ack_s;
	wire				memory_map_er_s;
	wire 				memory_map_rd_req_s;
	wire				memory_map_num_bytes_p;
	
	// Module declarations
//pulse_generator	pulse_inst(
//	.clk210_p			(clk210_p),
//	.reset_p			(reset210_p),
//	.cnv_p				(cnv_p),
//	.sck_p				(sck_p),
//	.sdo_p				(sdo_p),
//	.data_packet_p		(data_packet_s),
//	.load_fifo_p		(load_fifo_p)						// O		Technically meant for FIFO, but will 
//	);														//			be used here as an indicator to send via UART
	
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
	.memory_map_er_p			(memory_map_er_s),
	.data_packet_p				(data_packet_s)
	);
	
clk_mmcm_1	mmcm_for_210MHz(
	.clk_in1			(clk_in_p),
	.clk_out1			(clk210_p),
	.locked				(locked),
	.reset				(reset_s)
	);
	
	assign reset_s									= reset_p;
	
	// CDC crossing for 210 clock reset
	always @(posedge clk210_p)
	begin
		if(reset_s)
			reset_sync_s[1:0]						<= {reset_sync_s[0],1'b1};
		else
			reset_sync_s[1:0]						<= reset_sync_s[1:0];	
	end
	
	assign 	reset210_p								= reset_sync_s[1];
	
	

	
endmodule

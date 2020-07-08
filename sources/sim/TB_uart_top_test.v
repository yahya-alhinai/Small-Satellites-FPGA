`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2017 10:21:04 AM
// Design Name: 
// Module Name: TB_uart_top_test
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


module TB_uart_top_test(

    );
	
	// Common
	reg					clk210_p					= 1'b0;
	reg					reset_p						= 1'b0;
	
	// UART_TX Model
	wire				tx_p;
	wire				tx_model_tx_p;
	
	// Baud Gen
	wire				baud_1_x_p;
	wire				baud_16_x_p;
	
	// UART_TOP
	reg			[7:0]	tx_model_transmit_data_p	= 8'd0;
	reg					tx_model_transmit_req_p		= 1'b0;
	wire				tx_model_transmit_done_p;
	
	// Testbench 
	reg			[7:0]	uart_top_test_state_s		= 8'd0;
	reg			[7:0]	uart_top_test_return_state_s= 8'd0;
	reg			[7:0]	uart_tx_model_tx_cnt_s		= 8'd0;
	reg			[19:0]	wait_counter_s				= 20'd0;
	
	// Parameters
	parameter	[7:0]	IDLE_c						= 8'd0;
	parameter	[7:0]	START_BYTE_c				= 8'd1;
	parameter	[7:0]	READ_CMD_c					= 8'd2;
	parameter	[7:0]	ADDR_1_c					= 8'd3;
	parameter	[7:0]	ADDR_2_c					= 8'd4;
	parameter	[7:0]	WAIT_FOR_TX_DONE_c			= 8'd5;
	parameter	[7:0]	DONE_c						= 8'd6;
	parameter	[7:0]	WAIT_c						= 8'd7;
	
	parameter	[7:0]	TX_MAX_COUNT_c				= 8'd5;
	parameter	[19:0]	WAIT_TIME_c					= 20'd1042000; // around 5ms wait time.
	// Module declarations
	baud_generator	baud_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_16_x_p				(baud_16_x_p),
	.baud_1_x_p					(baud_1_x_p)
	);
	
	uart_top	uart_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.tx_p						(tx_p),
	.rx_p						(tx_model_tx_p)
	// ,
	// memory_map_adrs_p,
	// memory_map_wr_data_p,
	// memory_map_rd_data_p,
	// memory_map_wr_req_p,
	// memory_map_rd_req_p,
	// memory_map_rd_ack_p,	
	// memory_map_wr_ack_p,	
	// memory_map_er_p	
	);
	
	TB_uart_transmitter	transmitter_model_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_1_x_p					(baud_1_x_p),
	.tx_p						(tx_model_tx_p),
	.transmit_data_p			(tx_model_transmit_data_p),
	.transmit_done_p			(tx_model_transmit_done_p),
	.transmit_req_p				(tx_model_transmit_req_p)
	);
	
	always # 2.3809523 clk210_p <= ~clk210_p;
	
	initial
		begin
			reset_p			<= 1'b1;
			#1000
			reset_p			<= 1'b0;
		end
	
	always @(posedge clk210_p)
	begin
		if (reset_p)
			begin
				uart_top_test_state_s				<= IDLE_c;
				uart_top_test_return_state_s		<= IDLE_c;
				tx_model_transmit_req_p				<= 1'b0;
				uart_tx_model_tx_cnt_s				<= 1'b0;
			end
		else
			case(uart_top_test_state_s)
			
			IDLE_c:
				begin
					uart_top_test_state_s			<= START_BYTE_c;
				end
			
			START_BYTE_c:
				begin
					uart_top_test_return_state_s	<= READ_CMD_c;
					uart_top_test_state_s			<= WAIT_FOR_TX_DONE_c;
					tx_model_transmit_data_p		<= 8'h01;
					tx_model_transmit_req_p			<= 1'b1;
				end
				
			READ_CMD_c:
				begin
					uart_top_test_return_state_s	<= ADDR_1_c;
					uart_top_test_state_s			<= WAIT_FOR_TX_DONE_c;
					tx_model_transmit_data_p		<= 8'h02;
					tx_model_transmit_req_p			<= 1'b1;
				end
				
			ADDR_1_c:
				begin
					uart_top_test_return_state_s	<= ADDR_2_c;
					uart_top_test_state_s			<= WAIT_FOR_TX_DONE_c;
					tx_model_transmit_data_p		<= 8'h00;
					tx_model_transmit_req_p			<= 1'b1;
				end
				
			ADDR_2_c:
				begin
					uart_top_test_return_state_s	<= DONE_c;
					uart_top_test_state_s			<= WAIT_FOR_TX_DONE_c;
					tx_model_transmit_data_p		<= 8'h04;
					tx_model_transmit_req_p			<= 1'b1;
				end
				
			WAIT_FOR_TX_DONE_c:
				begin
					if (tx_model_transmit_done_p == 1'b1) begin
						tx_model_transmit_req_p		<= 1'b0;
						uart_top_test_state_s		<= uart_top_test_return_state_s;
						end
					else begin
						uart_top_test_state_s		<= WAIT_FOR_TX_DONE_c;
					end
				end
				
			DONE_c:
				begin
					uart_top_test_state_s			<= WAIT_c;
				end				
				
			WAIT_c:
				begin
					if(wait_counter_s == WAIT_TIME_c) begin
						wait_counter_s				<= 0;
						uart_top_test_state_s		<= IDLE_c;
						end
					else begin
						wait_counter_s				<= wait_counter_s + 1;
						uart_top_test_state_s		<= WAIT_c;
					end
				end
			default:
				uart_top_test_state_s				<= IDLE_c;			
			endcase
	end	

	
endmodule

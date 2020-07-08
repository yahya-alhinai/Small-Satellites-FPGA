`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2017 06:39:40 PM
// Design Name: 
// Module Name: TB_uart_rx_test
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


module TB_uart_rx_test(
    );
	
	// common variables
	reg					clk210_p				= 1'b0;
	reg					reset_p					= 1'b0;
	
	// UART TX MODEL
	wire				tx_p;
	reg			[7:0]	transmit_data_p			= 8'd0;
	wire 				transmit_done_p;
	reg					transmit_req_p			= 1'b0;

	// BAUD GEN
	wire				baud_1_x_p;
	wire 				baud_16_x_p;
	
	// UART RX
	wire				rx_p;
	wire				received_data_read_req_p;
	wire		[7:0]	fifo_rx_dout_p;
	wire		[4:0]	fifo_rx_data_count_p;
	wire				fifo_rx_empty_p;
	
	reg					fifo_rx_rd_en_p			= 1'b0;
	reg					received_data_ack_p		= 1'b0;
	
	// Testbench 
	reg			[7:0]	uart_rx_testing_state_s	= 8'd0;
	reg			[7:0]	uart_tx_model_tx_cnt_s	= 8'd0;
	
	
	// Parameters
	parameter	[7:0]	IDLE_c					= 8'd0;
	parameter	[7:0]	TRANSMIT_DATA_c			= 8'd1;
	parameter	[7:0]	WAIT_FOR_TX_DONE_c		= 8'd2;
	parameter	[7:0]	READ_OUT_RX_FIFO_c		= 8'd3;
	
	parameter	[7:0]	TX_MAX_COUNT_c			= 8'd5;
	
	// Module declarations
	TB_uart_transmitter	transmitter_model_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_1_x_p					(baud_1_x_p),
	.tx_p						(tx_p),
	.transmit_data_p			(transmit_data_p),
	.transmit_done_p			(transmit_done_p),
	.transmit_req_p				(transmit_req_p)
	);
	
	baud_generator	baud_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_16_x_p				(baud_16_x_p),
	.baud_1_x_p					(baud_1_x_p)
	);
	
	uart_rx	rx_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.rx_p						(rx_p),
	.baud_16_x_p				(baud_16_x_p),
	.received_data_read_req_p	(received_data_read_req_p),
	.received_data_ack_p		(received_data_ack_p),
	.fifo_rx_dout_p				(fifo_rx_dout_p),
	.fifo_rx_rd_en_p			(fifo_rx_rd_en_p),
	.fifo_rx_data_count_p		(fifo_rx_data_count_p),
	.fifo_rx_empty_p			(fifo_rx_empty_p)
	);
	
	assign	rx_p		= tx_p;
	
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
				uart_rx_testing_state_s				<= IDLE_c;
				transmit_req_p						<= 1'b0;
				uart_tx_model_tx_cnt_s				<= 1'b0;
				fifo_rx_rd_en_p						<= 1'b0;
			end
		else
			case(uart_rx_testing_state_s)
			IDLE_c:
				begin
					if(uart_tx_model_tx_cnt_s == TX_MAX_COUNT_c)
						begin
							uart_rx_testing_state_s	<= READ_OUT_RX_FIFO_c;
							fifo_rx_rd_en_p			<= 1'b1;
							uart_tx_model_tx_cnt_s	<= 0;
						end
					else	
						begin
							uart_rx_testing_state_s	<= TRANSMIT_DATA_c;
							uart_tx_model_tx_cnt_s	<= uart_tx_model_tx_cnt_s + 1;
							transmit_data_p			<= 8'hA0 + uart_tx_model_tx_cnt_s;
						end
				end
				
			TRANSMIT_DATA_c:
				begin
					transmit_req_p					<= 1'b1;
					uart_rx_testing_state_s			<= WAIT_FOR_TX_DONE_c;
				end
			
			WAIT_FOR_TX_DONE_c:
				begin
					if(transmit_done_p)
						begin
							uart_rx_testing_state_s	<= IDLE_c;
							transmit_req_p			<= 1'b0;
						end
					else
						uart_rx_testing_state_s		<= WAIT_FOR_TX_DONE_c;
				end
			
			READ_OUT_RX_FIFO_c:
				begin
					if(~fifo_rx_empty_p)
						begin
							fifo_rx_rd_en_p			<= 1'b1;
							uart_rx_testing_state_s	<= READ_OUT_RX_FIFO_c;
						end
					else
						begin
							fifo_rx_rd_en_p			<= 1'b0;
							uart_rx_testing_state_s	<= IDLE_c;
						end
				end
			
			default:
				uart_rx_testing_state_s				<= IDLE_c;			
			endcase
	end	
	
endmodule

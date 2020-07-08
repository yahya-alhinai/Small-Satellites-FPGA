`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2017 06:39:40 PM
// Design Name: 
// Module Name: TB_uart_tx_test
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


module TB_uart_tx_test(

    );
	
	reg					clk210_p				= 1'b0;
	reg					reset_p					= 1'b0;
	
	wire 				baud_16_x_p;
	wire				baud_1_x_p;
	
	wire				tx_p;
	reg			[7:0]	fifo_tx_din_p			= 8'd0;
	reg					transmit_req_p			= 1'b0;
	wire				transmit_done_p;
	wire		[4:0]	fifo_tx_data_count_p;
	reg					fifo_tx_wr_en_p			= 1'b0;
	
	reg			[7:0]	uart_tx_testing_state_s 	= 8'd0;
	reg			[7:0]	fifo_fill_counter_s		= 8'd0;
	reg					start					= 1'b0;
	
	parameter	[7:0]	IDLE_c					= 8'd0;
	parameter	[7:0]	PULL_UP_FIFO_WE_c		= 8'd1;
	parameter	[7:0]	LOAD_FIFO_c				= 8'd2;
	parameter	[7:0]	TRANSMIT_DATA_c			= 8'd3;
	parameter	[7:0]	DONE_c					= 8'd4;
	
	parameter	[7:0]	DATA_START_c			= 8'h20;
	parameter	[7:0]	NUMBER_OF_BYTES_c		= 8'd10;
	
	
	baud_generator	baud_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_16_x_p				(baud_16_x_p),
	.baud_1_x_p					(baud_1_x_p)
	);
	
	uart_tx	tx_inst(
	.clk210_p					(clk210_p),
	.reset_p					(reset_p),
	.baud_1_x_p					(baud_1_x_p),
	.tx_p						(tx_p),
	// .transmit_data_p			(transmit_data_p),
	.transmit_req_p				(transmit_req_p),
	.transmit_done_p			(transmit_done_p),
	.transmit_done_ack_p		(transmit_done_ack_p),
	.fifo_tx_din_p				(fifo_tx_din_p),
	.fifo_tx_wr_en_p			(fifo_tx_wr_en_p),
	.fifo_tx_data_count_p		(fifo_tx_data_count_p),
	.fifo_tx_empty_p			(fifo_tx_empty_p)
	);
	
	// Current not using a receiver.
	// TB_uart_receiver	receiver_inst(
	// );
	
	
	initial
		begin
			reset_p			<= 1'b1;
			#500
			reset_p			<= 1'b0;
			#1000
			start			<= 1'b1;
		end

	always # 2.3809523 clk210_p	<= ~clk210_p;	
	
	always @(posedge clk210_p)
	begin
		if(reset_p)
			begin
				fifo_tx_din_p				<= 8'd0;
				fifo_tx_wr_en_p				<= 1'b0;
				uart_tx_testing_state_s		<= 8'd0;
			end
		else
			begin
			if(start == 1) begin			// only a sim. so this is fine.
				case(uart_tx_testing_state_s)
				IDLE_c:
					begin
						uart_tx_testing_state_s		<= PULL_UP_FIFO_WE_c;
						fifo_tx_din_p				<= 8'd0;
						fifo_fill_counter_s			<= 8'd0;
					end
					
				PULL_UP_FIFO_WE_c:
					begin
						if(fifo_fill_counter_s	== NUMBER_OF_BYTES_c)
							begin
								uart_tx_testing_state_s		<= TRANSMIT_DATA_c;
								fifo_fill_counter_s			<= 0;
							end
						else
							begin
								fifo_tx_wr_en_p				<= 1'b1;
								uart_tx_testing_state_s		<= LOAD_FIFO_c;
								fifo_fill_counter_s			<= fifo_fill_counter_s + 1'b1;
								fifo_tx_din_p				<= DATA_START_c + fifo_fill_counter_s;
							end
					end
					
				LOAD_FIFO_c:
					begin
						fifo_tx_wr_en_p						<= 1'b0;
						uart_tx_testing_state_s				<= PULL_UP_FIFO_WE_c;
					end
					
				TRANSMIT_DATA_c:
					begin
						transmit_req_p						<= 1'b1;
						uart_tx_testing_state_s				<= DONE_c;
					end
				
				DONE_c:
					begin
						if(transmit_done_p == 1)
							begin
								transmit_req_p				<= 1'b0;
								uart_tx_testing_state_s		<= DONE_c;
							end
						else
							uart_tx_testing_state_s			<= DONE_c;
					end
					
				default:
					uart_tx_testing_state_s					<= IDLE_c;
				endcase
			end
		end
	end	
	
endmodule

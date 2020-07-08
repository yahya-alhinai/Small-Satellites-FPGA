`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2017 06:39:40 PM
// Design Name: 
// Module Name: TB_uart_transmitter
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


module TB_uart_transmitter(
	clk210_p,
	reset_p,
	baud_1_x_p,
	tx_p,
	transmit_data_p,
	transmit_done_p,
	transmit_req_p
    );
	
	input				clk210_p;
	input				reset_p;
	input				transmit_req_p;
	input				transmit_data_p;
	input				baud_1_x_p;
	
	output				tx_p;
	output				transmit_done_p;
	
	wire		[7:0]	transmit_data_p;
	
	reg			[7:0]	uart_tx_state_s		= 8'd0;
	reg			[7:0]	uart_tx_bit_count_s	= 8'd0;
	reg					transmit_done_p		= 1'd0;
	reg			[7:0]	data_tx_s			= 8'd0;
	reg					tx_p				= 1'b1;
	reg					uart_tx_last_op_s	= 1'b0;
	
	parameter	[7:0]	TX_IDLE_c			= 8'd0;
	parameter	[7:0] 	TX_START_BIT_c		= 8'd1;
	parameter	[7:0]	TX_TRANSMIT_BYTE_c	= 8'd2;
	parameter	[7:0]	TX_STOP_BIT_c		= 8'd3;
	parameter	[7:0]	TX_DONE_c			= 8'd4;
	parameter	[7:0]	INITIATE_TX_c		= 8'd5;
	
	
	always @(posedge clk210_p)
	begin
		if(reset_p)	
			begin
				uart_tx_state_s				<= TX_IDLE_c;
				uart_tx_bit_count_s			<= 8'd0;
				transmit_done_p				<= 1'd0;
				tx_p						<= 1'b1;
				data_tx_s					<= 8'd0;
			end
		else
			begin
				case(uart_tx_state_s)
				TX_IDLE_c:
					begin
						if(transmit_req_p)
							begin
								uart_tx_state_s		<= TX_START_BIT_c;
								data_tx_s			<= transmit_data_p;
								tx_p				<= 1'b1;
								uart_tx_bit_count_s	<= 8'd0;
								transmit_done_p		<= 1'b0;
							end
						else
							begin
								uart_tx_state_s		<= TX_IDLE_c;
								uart_tx_bit_count_s	<= 8'd0;
								transmit_done_p		<= 1'b0;	
								tx_p				<= 1'b1;
							end
					end
				
				TX_START_BIT_c:
					begin
						if(baud_1_x_p)
							begin
								tx_p				<= 1'b0;
								uart_tx_state_s		<= TX_TRANSMIT_BYTE_c;
							end
						else
							begin
								tx_p				<= 1'b1;
								uart_tx_state_s		<= TX_START_BIT_c;
							end
					end
				
				TX_TRANSMIT_BYTE_c:
					begin
						if(uart_tx_bit_count_s != 8'd8)
							begin
								if(baud_1_x_p)
									begin
										tx_p				<= data_tx_s[uart_tx_bit_count_s];
										uart_tx_bit_count_s	<= uart_tx_bit_count_s + 1;
									end
								else
									tx_p					<= tx_p;
							end
						else
							begin
								uart_tx_bit_count_s			<= 8'd0;
								uart_tx_state_s				<= TX_STOP_BIT_c;
							end
					end
					
				TX_STOP_BIT_c:
					begin
						if(baud_1_x_p)
							begin
								tx_p				<= 1'b1;
								uart_tx_state_s		<= TX_DONE_c;
								transmit_done_p		<= 1'b1;
							end
						else
							tx_p					<= tx_p;
					end
				
				TX_DONE_c:
					begin
						if(~transmit_req_p)
							begin
								uart_tx_state_s		<= TX_IDLE_c;
								transmit_done_p		<= 1'b0;
							end
						else
							uart_tx_state_s			<= TX_DONE_c;
					end
					
				default:
					uart_tx_state_s					<= TX_IDLE_c;
				endcase
			end
	end	
	
	
	
endmodule

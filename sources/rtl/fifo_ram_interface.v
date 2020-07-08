`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2017 10:55:04 AM
// Design Name: 
// Module Name: fifo_ram_interface
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


module fifo_ram_interface(
	clk210_p,
	clk350_p,
	reset_p,
	data_packet_p,
	load_fifo_p
	);
	
	input clk210_p;
	input clk350_p;
	input reset_p;
	input data_packet_p;
	input load_fifo_p;
	
	// variable declarations
	
	wire[79:0]	data_packet_p;
	reg	[7:0]	fifo_write_state_s 	= 8'h00;
	
	reg	[15:0]	fifo_1_data_count_s	= 16'h0000;
	wire [79:0]	fifo_1_din_s;
	wire		fifo_1_almost_empty_s;
	wire		fifo_1_almost_full_s;
	wire		fifo_1_empty_s;
	wire		fifo_1_full_s;	
	reg			fifo_1_rd_en_s;	
	reg			fifo_1_wr_en_s;		
	
	reg	[15:0]	fifo_2_data_count_s	= 16'h0000;
	wire [79:0]	fifo_2_din_s;
	wire		fifo_2_almost_empty_s;
	wire		fifo_2_almost_full_s;
	wire		fifo_2_empty_s;
	wire		fifo_2_full_s;	
	reg			fifo_2_rd_en_s;	
	reg			fifo_2_wr_en_s;	
	
	// 
	
	
	// parameters for FIFO write state machine
	parameter	[7:0]	idle_c				= 8'd0;	
	parameter	[7:0]	enable_write_c		= 8'd1;
	parameter	[7:0]	disable_write_c		= 8'd2;		
	parameter	[7:0]	check_full_flag_c	= 8'd3;		
	parameter	[7:0]	wait_for_read_c     = 8'd4;		
	
	// FIFO Modules declarations
	
	fifo_1 fifo_inst_1(
		.rst							(reset_p),
		.wr_clk							(clk210_p),
		.rd_clk							(clk350_p),
		.din							(fifo_1_din_s),
		.wr_en							(fifo_1_wr_en_s),
		.rd_en							(fifo_1_rd_en_s),
		.dout							(fifo_1_dout_s),
		.full							(fifo_1_full_s),
		.almost_full					(fifo_1_almost_full_s),
		.empty							(fifo_1_empty_s),
		.almost_empty					(fifo_1_almost_empty_s)
	); 
		
	fifo_2 fifo_inst_2(
		.rst							(reset_p),
		.wr_clk							(clk220_p),
		.rd_clk							(clk350_p),
		.din							(fifo_2_din_s),
		.wr_en							(fifo_2_wr_en_s),
		.rd_en							(fifo_2_rd_en_s),
		.dout							(fifo_2_dout_s),
		.full							(fifo_2_full_s),
		.almost_full					(fifo_2_almost_full_s),
		.empty							(fifo_2_empty_s),
		.almost_empty					(fifo_2_almost_empty_s)
	); 
	
	// DDR3 RAM Interface declaration
	  mig_7series_0 u_mig_1(
	// Memory interface ports
		.ddr3_addr                      				(ddr3_addr),				// output [14:0]
		.ddr3_ba                       				(ddr3_ba),					// output [2:0]
		.ddr3_cas_n                				(ddr3_cas_n),				// output
		.ddr3_ck_n                      				(ddr3_ck_n),				// output
		.ddr3_ck_p                      				(ddr3_ck_p),				// output
		.ddr3_cke                       				(ddr3_cke),					// output
		.ddr3_ras_n                				(ddr3_ras_n),				// output
		.ddr3_we_n                      				(ddr3_we_n),				// output	
		.ddr3_dq                        				(ddr3_dq),					// inout [15:0]
		.ddr3_dqs_n                     				(ddr3_dqs_n),				// inout [1:0]
		.ddr3_dqs_p                     				(ddr3_dqs_p),				// inout [1:0]
		.ddr3_reset_n                   			(ddr3_reset_n),				// output
		.init_calib_complete     			(init_calib_complete),		// output
		  
		   
		.ddr3_dm                        				(ddr3_dm),					// output [1:0]
		.ddr3_odt                       				(ddr3_odt),					// output
	// Application interface ports
		.app_addr                       				(app_addr),					// input [28:0]
		.app_cmd                        				(app_cmd),					// input [2:0]
		.app_en                         				(app_en),					// input
		.app_wdf_data                   			(app_wdf_data),				// input [127:0]
		.app_wdf_end                    			(app_wdf_end),				// input
		.app_wdf_wren                   			(app_wdf_wren),				// input
		.app_rd_data                    			(app_rd_data),				// output [127:0]
		.app_rd_data_end                			(app_rd_data_end),			// output
		.app_rd_data_valid          			(app_rd_data_valid),		// output
		.app_rdy                        				(app_rdy),					// output
		.app_wdf_rdy                    			(app_wdf_rdy),				// output
		.app_sr_req                     				(1'b0),						// input
		.app_ref_req                    			(1'b0),						// input
		.app_zq_req                     				(1'b0),						// input
		.app_sr_active                  			(app_sr_active),			// output
		.app_ref_ack                    			(app_ref_ack),				// output
		.app_zq_ack                     				(app_zq_ack),				// output
		.ui_clk                         				(clk),						// output
		.ui_clk_sync_rst                			(rst),						// output
	  
		.app_wdf_mask                   			(app_wdf_mask),				// input [15:0]
	  
		   
	// System Clock Ports
		.sys_clk_i                       				(sys_clk_i),				// input
		   
	// Reference Clock Ports
		.clk_ref_i                	      			(clk_ref_i),				// input
		.device_temp            				(device_temp),				// output
		.device_temp_i					(device_temp_i),			// input
	  
	// Debug Signals
		.ddr3_ila_wrpath				(ddr3_ila_wrpath),
		.ddr3_ila_rdpath				(ddr3_ila_rdpath),
		.ddr3_ila_basic					(ddr3_ila_basic),
		.ddr3_vio_sync_out				(ddr3_vio_sync_out),
		.dbg_byte_sel					(dbg_byte_sel),
		.dbg_sel_pi_incdec				(dbg_sel_pi_f_incdec),
		.dbg_pi_f_inc					(dbg_pi_f_inc),
		.dbg_pi_f_dec					(dbg_pi_f_dec),
		.dbg_sel_po_incdec				(dbg_sel_po_incdec),
		.dbg_po_f_inc					(dbg_po_f_inc),
		.dbg_po_f_dec					(dbg_po_f_dec),
		.dbg_po_f_stg23_sel				(dbg_po_f_stg23_sel),
		.dbg_pi_counter_read_val		(dbg_pi_counter_read_val),	
		.dbg_po_counter_read_val		(dbg_po_counter_read_val),
		.dbg_prbs_final_dqs_tap_cnt_r	(dbg_prbs_final_dqs_tap_cnt_r),
		.dbg_prbs_first_edge_taps		(dbg_prbs_first_edge_taps),
		.dbg_prbs_second_edge_taps		(dbg_prbs_second_edge_taps),
		  
		   .sys_rst                        				(sys_rst)
       );
	
	
	// state machine to load data into the FIFO
	
	always @(posedge clk210_p)
	begin
		if(reset_p)
			begin
				fifo_write_state_s	<= idle_c;
				fifo_1_wr_en_s		<= 1'b0;
			end
		else
			begin
				case(fifo_write_state_s)
				idle_c:
					begin
						if(load_fifo_p == 1'b1)
							fifo_write_state_s	<= enable_write_c;
						else
							fifo_write_state_s	<= enable_write_c;
					end
					
				enable_write_c:
					begin
						fifo_1_data_count_s		<= fifo_1_data_count_s + 1'b1;
						fifo_1_wr_en_s			<= 1'b1;
						fifo_write_state_s		<= disable_write_c;
					end
					
				disable_write_c:
					begin
						fifo_1_wr_en_s			<= 1'b0;
						fifo_write_state_s		<= check_full_flag_c;
					end
					
				check_full_flag_c:
					begin
						if(fifo_1_full_s)
							fifo_write_state_s	<= wait_for_read_c;
						else
							fifo_write_state_s	<= idle_c;
					end
					
				wait_for_read_c:
					begin
							
					end
                    
				default:
					fifo_write_state_s          <= idle_c;
				endcase
		end
	end
	
	
	
endmodule

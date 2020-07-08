`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2017 01:25:45 PM
// Design Name: 
// Module Name: Clock_Synchronization_Top
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


module Clock_Synchronization_Top(
    clk210_p,
	reset_p,
	timekeeper_time_p,
	timekeeper_ready_p,
    FPGA_FC_sync_reg_p,
    FC_GPS_start_time_p,
    pps_gps_p
    );
    
    input               clk210_p;
    input               reset_p;
    input       [15:0]  FPGA_FC_sync_reg_p;
    input       [63:0]  FC_GPS_start_time_p;
    input               pps_gps_p;
    
    output              timekeeper_time_p;
    output              timekeeper_ready_p;    
    
    wire        [63:0]  timekeeper_time_p;
    wire        [63:0]  timekeeper_time_s;
    
    assign  timekeeper_time_p         = timekeeper_time_s;
    assign  FC_GPS_lock_ready_p       = FPGA_FC_sync_reg_p[0];
    assign  FC_GPS_PPS_look_p         = FPGA_FC_sync_reg_p[1];
    assign  FC_GPS_start_time_ready_p = FPGA_FC_sync_reg_p[2];
    
    timekeeper Time_Keeper_inst(
    .clk210_p                   (clk210_p),                 // INPUT  -  1 bit  - 105 MHz clock
	.reset_p                    (reset_p),                  // INPUT  -  1 bit  - reset
	.timekeeper_time_p          (timekeeper_time_s),        // OUTPUT - 64 bits - current time
	.timekeeper_ready_p         (timekeeper_ready_p),       // OUTPUT -  1 bit  - timekeeper is ready
    .FC_GPS_lock_ready_p        (FC_GPS_lock_ready_p),      // INPUT  -  1 bit  - FC tells us that GPS is locked
    .FC_GPS_PPS_look_p          (FC_GPS_PPS_look_p),        // INPUT  -  1 bit  - FC tells us to look for the next PPS signal
    .FC_GPS_start_time_ready_p  (FC_GPS_start_time_ready_p),// INPUT  -  1 bit  - FC tells us that GPS start time has been loaded into our register
    .FC_GPS_start_time_p        (FC_GPS_start_time_p),      // INPUT  - 64 bits - FC sets this start time in our memory map register
    .pps_gps_p                  (pps_gps_p)                 // INPUT  -  1 bit  - This is the PPS signal from the GPS    
    );
    
    
    
endmodule

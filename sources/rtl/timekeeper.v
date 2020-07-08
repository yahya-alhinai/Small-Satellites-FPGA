`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2017 09:08:23 AM
// Design Name: 
// Module Name: timekeeper
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

//`define DEBUGGING_MODE            //Be sure to comment out the one not in use
 `define REAL_OPERATION

module timekeeper(
    clk210_p,
    reset_p,
    timekeeper_time_p,
    timekeeper_ready_p,
    FC_GPS_lock_ready_p,
    FC_GPS_PPS_look_p,
    FC_GPS_start_time_ready_p,
    FC_GPS_start_time_p,
    pps_gps_p
    );
    
    input               clk210_p;
    input               reset_p;
    input               FC_GPS_lock_ready_p;
    input               FC_GPS_PPS_look_p;
    input               pps_gps_p;    
    input               FC_GPS_start_time_p;
    input               FC_GPS_start_time_ready_p;
    
    output              timekeeper_ready_p;
    output              timekeeper_time_p;
    
    // variable declarations
    reg                 timekeeper_ready_p      =  1'd0;        // not much use for now. But will be useful later 
                                                                // when GPS is connected.
                                                                // use in SM with SPI talking to Flight Comp
    wire        [63:0]  FC_GPS_start_time_p;
    wire        [63:0]  timekeeper_time_p;            
    reg         [63:0]  timekeeper_time_s       = 64'd0;  
    reg         [ 1:0]  pps_samples_s           =  2'd0;
    reg         [ 7:0]  timekeeper_cntrl_state_s=  8'd0;
    reg         [ 7:0]  timekeeper_state_s      =  8'd0;
    reg         [63:0]  time_counter_s          = 64'd0;
    reg                 start_pps_counter_s     =  1'b0;
    reg         [ 7:0]  microsec_counter_s      =  8'd0;
    reg         [ 7:0]  timekeeper_counter_s    =  8'd0;
    
    // parameters
    parameter   [ 7:0]  microsec0M5_count_c     = 8'd21;        // helps count up every 0.2 microseconds
                                                                // 42 when using 210 MHz clock - make sure to determine which is latest version!
                                                                // 21 when using 105 MHz clock
    
    //-----------------------------------------------------------------------//
    // output assignments
    //-----------------------------------------------------------------------//
    assign timekeeper_time_p       = timekeeper_time_s;
    
    //-----------------------------------------------------------------------//
    // States for the control state machine.
    //-----------------------------------------------------------------------//
    parameter   [ 7:0]  WAIT_FOR_GPS_LOCK_st        = 8'd0;
    parameter   [ 7:0]  WAIT_FOR_FC_PPS_LOOK_st     = 8'd1;
    parameter   [ 7:0]  WAIT_FOR_PPS_RISING_st      = 8'd2;
    parameter   [ 7:0]  WAIT_FOR_FC_START_TIME_st   = 8'd3;
    
    `ifdef DEBUGGING_MODE
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            timekeeper_counter_s    <= 8'd0;
            timekeeper_time_s       <= 64'd0;
            timekeeper_ready_p      <= 1'b0;
            end
        else begin
            timekeeper_ready_p      <= 1'b1;
            if (timekeeper_counter_s == microsec0M5_count_c)
                begin
                    timekeeper_time_s   <= timekeeper_time_s + 1'b1;
                    timekeeper_counter_s<= 8'd0;
                end
            else
                timekeeper_counter_s    <= timekeeper_counter_s + 1'b1;
        end
    end 
    `endif
    
    `ifdef REAL_OPERATION
    //-----------------------------------------------------------------------//
    // PPS Sampler. This block samples the PPS signal into a two bit shift register.
    // This will be later used to determine rising edges.
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            pps_samples_s           <= 2'd0;
            end
        else begin
            pps_samples_s[0]        <= pps_gps_p;
            pps_samples_s[1]        <= pps_samples_s[0];
        end
    end
    
    //-----------------------------------------------------------------------//
    // Time Between PPS pulses counter. This block keeps a count in number of 0.2 microseconds
    // between two consecutive PPS pulses.
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            time_counter_s      <= 64'd0;
            microsec_counter_s  <=  8'd0;
        end
        else begin
            if (start_pps_counter_s == 1'b1) begin
                if (microsec_counter_s == microsec0M5_count_c) begin
                    time_counter_s      <= time_counter_s + 1;
                    timekeeper_time_s   <= FC_GPS_start_time_p + time_counter_s;
                    microsec_counter_s  <= 8'd0;
                end
                else begin
                    microsec_counter_s  <= microsec_counter_s + 1;
                end
            end
            else begin
                time_counter_s  <= 64'd0;
            end            
        end
    end
    
    //-----------------------------------------------------------------------//
    // This block below implements a state machine that locks time with the FC. 
    // First, we wait for the FC to tell us that GPS is locked. Then the FC tells
    // us to look for the next PPS rising edge. From the point the rising edge of 
    // the PPS is seen on the FPGA, there is a counter (time_counter_s) that counts up every 0.2 us.
    // At the same rising edge of the PPS, the FC grabs a "start time" from the GPS.
    // This is then sent to the FPGA and a start time ready flag is also set.
    // Upon sensing that this flag is set, the FPGA adds the "start time" to the time_counter_s.
    // This resultant sum is then the the real time and all the ADC samples are based on this time.
    //                ___    (1 second)       ___
    //  PPS:  _______/   \___________________/   \__________________
    //                      |-> FC says look for next PPS
    //                                       |-> Counter on FPGA (time_counter_s begins)
    //                                               |-> FC gets start time from GPS and gives it to FPGA
    //                                                  |-> FPGA adds start time with time_counter_s at that instant
    //                                                      Resultant number is the current time in microseconds.                    
    //-----------------------------------------------------------------------//    
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            start_pps_counter_s     <= 1'b0;
            end
        else begin
            case(timekeeper_cntrl_state_s)
            
            // Wait for the Flight Computer to tell us that the GPS is locked.
            WAIT_FOR_GPS_LOCK_st: begin
                    if (FC_GPS_lock_ready_p == 1'b1) begin
                        timekeeper_cntrl_state_s    <= WAIT_FOR_FC_PPS_LOOK_st;
                        end
                    else begin
                        timekeeper_cntrl_state_s    <= WAIT_FOR_GPS_LOCK_st;
                    end
                end
            
            // Wait for the Flight Computer to tell us to look for the next rising PPS Signal
            WAIT_FOR_FC_PPS_LOOK_st: begin
                    if (FC_GPS_PPS_look_p == 1'b1) begin
                        timekeeper_cntrl_state_s    <= WAIT_FOR_PPS_RISING_st;
                        end
                    else begin
                        timekeeper_cntrl_state_s    <= WAIT_FOR_FC_PPS_LOOK_st;
                    end
                end
                
            // Wait for the rising edge of the PPS signal. 
            WAIT_FOR_PPS_RISING_st: begin
                    if (pps_samples_s[0] == 1 && pps_samples_s[1] == 0) begin
                        timekeeper_cntrl_state_s    <= WAIT_FOR_FC_START_TIME_st;
                        start_pps_counter_s         <= 1'b1; 
                        end
                    else begin
                        timekeeper_cntrl_state_s    <= WAIT_FOR_PPS_RISING_st;
                    end
                end
            
            // Wait for the FC to give us the start time.
            WAIT_FOR_FC_START_TIME_st: begin
                    if (FC_GPS_start_time_ready_p == 1'b1) begin
                        timekeeper_ready_p          <= 1'b1;
                        end
                    else begin
                        timekeeper_ready_p          <= 1'b0;
                    end
                end
            
            default:
                timekeeper_cntrl_state_s    <= WAIT_FOR_GPS_LOCK_st;
            endcase
            
        end 
        
    end
    
    `endif
    
    
    
endmodule

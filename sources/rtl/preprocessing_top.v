`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2017 02:06:24 PM
// Design Name: 
// Module Name: preprocessing_top
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


module preprocessing_top(
	clk210_p,               // INPUT  -  1 bit  - 210 MHz clock    
    reset_p,                // INPUT  -  1 bit  - reset
    adc_cnv_p,              // OUTPUT -  1 bit  - ADC CNV (conversion) signal
    adc_sck_p,              // OUTPUT -  1 bit  - ADC clock
    adc_sdo_p,              // INPUT  -  1 bit  - data from the adc
    adc_current_data_p,     // OUTPUT - 16 bits - current deserialized data from the ADC (will go into the memory map
//    adc_threshold_p,        // INPUT  - 16 bits - threshold that is set by the Flight Computer. This comes from the Memory Map.
    adc_sampling_mode_p,    // INPUT  -  2 bits - The FC has the option to change the sampling mode. There are 4 options.    
    timekeeper_time_p,      // INPUT  -  1 bit  - indication that the timekeeper is ready
    timekeeper_ready_p,     // INPUT  - 64 bits - a 64 bit time stamp from the timekeeper module
    fifo_adc_rd_en_p,       // INPUT  -  1 bit  - read enable from the processing to the preprocessed data FIFO
    fifo_adc_data_count_p,  // OUTPUT - 10 bits - gives a count of the number of elements filled in the FIFO    
    fifo_adc_dout_p,         // OUTPUT - 80 bits - data out line from the FIFO. (In the form of {time_stamp(64 bits), adc_data(16 bits)})
	fifo_adc_empty_p         // OUTPUT - 1bit - empty flag
	);	

    input               clk210_p;
    input               reset_p;
    input               adc_sdo_p;
//    input               adc_threshold_p;
    input               adc_sampling_mode_p;
    input               timekeeper_time_p;
    input               timekeeper_ready_p;
    input               fifo_adc_rd_en_p;
    
    output              fifo_adc_data_count_p;
    output              fifo_adc_dout_p;
    output              adc_sck_p;
    output              adc_cnv_p;
    output              adc_current_data_p;
    output              fifo_adc_empty_p;
    
    // Variable declarations
    wire        [15:0]  adc_current_data_p;
    wire        [15:0]  adc_data_in_p;
//    wire        [15:0]  adc_threshold_p;
    wire        [ 1:0]  adc_sampling_mode_p;
    wire        [63:0]  timekeeper_time_p;
    wire                timekeeper_ready_p;
    
    wire                adc_data_received_p;
    
    reg         [79:0]  fifo_adc_din_s      = 80'd0;
    reg                 fifo_adc_wr_en_s    = 1'b0;
    wire                fifo_adc_rd_en_p;
    wire        [79:0]  fifo_adc_dout_p;
    wire                fifo_adc_full_s;
    wire                fifo_adc_almost_full_s;
    wire                fifo_adc_almost_empty_s;
    wire                fifo_adc_empty_s;
    wire        [10:0]  fifo_adc_data_count_p;
    reg         [10:0]  fifo_adc_data_count_s = 11'd0;
    wire                fifo_adc_empty_p;
    reg         [ 7:0]  buffer_cntrl_state_s = 8'd0;
    reg         [15:0]  adc_current_data_s   = 16'd0;
    
    
    // Output assignments
    assign  adc_current_data_p      = adc_current_data_s;
    assign  fifo_adc_data_count_p   = fifo_adc_data_count_s; 
    assign  fifo_adc_empty_p        = fifo_adc_empty_s;
    
    // Parameters
    parameter   [ 7:0]  WAIT_FOR_DATA_RECV_PULSE_st     = 8'd0;
    parameter   [ 7:0]  CHECK_THRESHOLD_st              = 8'd1;
    parameter   [ 7:0]  PULSE_WR_EN_st                  = 8'd2;
    parameter   [ 7:0]  END_PULSE_WR_EN_st              = 8'd3;
    
    //-----------------------------------------------------------------------//
    // Here, all the ADC interfaces are instantiated.
    //-----------------------------------------------------------------------//
    
    adc_interface adc_interface_inst(   
    .clk210_p               (clk210_p),                 // INPUT  -  1 bit  - 210 MHz clock
    .reset_p                (reset_p),                  // INPUT  -  1 bit  - reset signal
    .cnv_p                  (adc_cnv_p),                // OUTPUT -  1 bit  - CNV for ADC
    .sck_p                  (adc_sck_p),                // OUTPUT -  1 bit  - SCK for ADC
    .sdo_p                  (adc_sdo_p),                // INPUT  -  1 bit  - SDO from ADC
    .adc_data_received_p    (adc_data_received_p),      // OUTPUT -  1 bit  - indicates that a word has been deserialized
    .adc_data_in_p          (adc_data_in_p),            // OUTPUT - 16 bits - data received from the ADC
    .adc_sampling_mode_p    (adc_sampling_mode_p[1:0]), // INPUT  -  2 bits - decides the sampling mode of the ADC
    .timekeeper_ready_p     (timekeeper_ready_p)        // INPUT  -  1 bit  - indicates that the timekeeper is ready and that the ADC interface can receive data
    );
    
    
    //-----------------------------------------------------------------------//
    // Here all the FIFOs (one for each ADC interface) are instantiated.
    // This module is responsible for buffering all the data from the ADC interface.
    //-----------------------------------------------------------------------//
    fifo_preprocessing fifo_preprocessing_inst(
    .clk                    (clk210_p),                 // INPUT  -  1 bit  - 210 MHz clock
    .rst                    (reset_p),                  // INPUT  -  1 bit  - reset
    .din                    (fifo_adc_din_s),           // INPUT  - 80 bits - data input bus to the fifo
    .wr_en                  (fifo_adc_wr_en_s),         // INPUT  -  1 bit  - Write enable to the fifo
    .rd_en                  (fifo_adc_rd_en_p),         // INPUT  -  1 bit  - read enable to the fifo
    .dout                   (fifo_adc_dout_p),          // OUTPUT - 80 bits - data output bus from the fifo
    .full                   (fifo_adc_full_s),          // OUTPUT -  1 bit  - Full flag from the FIFO
    // .almost_full            (fifo_adc_almost_full_s),   // OUTPUT -  1 bit  - Almost full flag (triggers 1 byte before full)
    // .almost_empty           (fifo_adc_almost_empty_s),  // OUTPUT -  1 bit  - Almost empty flag (triggers with only 1 byte in the fifo)
    .prog_empty              (fifo_adc_empty_s)
    //.empty                  (fifo_adc_empty_s)         // OUTPUT -  1 bit  - Empty flag 
    // .data_count             (fifo_adc_data_count_p)     // OUTPUT - 10 bits - Number of bytes in the fifo
    );
    
    //-----------------------------------------------------------------------//
    // This block maintains the data count in the preprocessing fifo
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin  
            fifo_adc_data_count_s       <= 10'd0;
            end
        else begin
            if (fifo_adc_wr_en_s == 1'b1) begin
                fifo_adc_data_count_s <= fifo_adc_data_count_s + 1'b1;
                end
            else begin if (fifo_adc_rd_en_p == 1'b1) begin
                fifo_adc_data_count_s   <= fifo_adc_data_count_s - 1'b1;
                end
            end
        end
    end



    
    //-----------------------------------------------------------------------//
    // This block controls the writes to the FIFO. When adc_data_received_p goes
    // high, this block receives the ADC data, gets the corresponding and stores it into the FIFO.
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            fifo_adc_wr_en_s        <= 1'b0;
            
            end
        else begin
            case(buffer_cntrl_state_s)
            
            // Wait for the adc_data_received_p pulse. This indicates that a data DWORD
            // has been deserialized and can be pushed into the FIFO.
            WAIT_FOR_DATA_RECV_PULSE_st: begin
                    if (adc_data_received_p == 1'b1) begin
                        buffer_cntrl_state_s    <= CHECK_THRESHOLD_st;
                        adc_current_data_s      <= adc_data_in_p;
                        end
                    else begin
                        buffer_cntrl_state_s    <= WAIT_FOR_DATA_RECV_PULSE_st;
                    end
                end
                
            CHECK_THRESHOLD_st: begin
//                    if (adc_data_in_p > adc_threshold_p) begin
                        fifo_adc_din_s          <= {timekeeper_time_p, adc_data_in_p};
                        buffer_cntrl_state_s    <= PULSE_WR_EN_st;
//                        end
//                    else begin
//                        buffer_cntrl_state_s    <= WAIT_FOR_DATA_RECV_PULSE_st;    
//                    end
                end
                
            // Pulse a write enable to the FIFO. This allows the data to be written in.
            PULSE_WR_EN_st: begin
                    if (~fifo_adc_full_s) begin
                        fifo_adc_wr_en_s        <= 1'b1;
                        buffer_cntrl_state_s    <= END_PULSE_WR_EN_st;
                        end
                    else begin
                        buffer_cntrl_state_s    <= PULSE_WR_EN_st;
                    end
                end
            
            // End the pulse for write enable
            END_PULSE_WR_EN_st: begin
                    fifo_adc_wr_en_s        <= 1'b0;
                    buffer_cntrl_state_s    <= WAIT_FOR_DATA_RECV_PULSE_st;
                end
                
            // default
            default: begin
                fifo_adc_wr_en_s        <= 1'b0;
                buffer_cntrl_state_s    <= WAIT_FOR_DATA_RECV_PULSE_st;
                end
            endcase
            
        end
    end   
	 
endmodule

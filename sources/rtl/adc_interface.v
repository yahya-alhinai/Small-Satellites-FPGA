`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2017 02:06:24 PM
// Design Name: 
// Module Name: adc_interface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is the heart of the interface to the ADC. It coordinates all
//  the activities to the ADC including getting data from the ADC, assigning a 
//  time stamp to each of the data packets and finally sending this data packet to
//  the fifo_ram module where it the data is stored into the RAM.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adc_interface(
    clk210_p,
    reset_p,
    cnv_p,
    sck_p,
    sdo_p,
    adc_data_received_p,
    adc_data_in_p,
    adc_sampling_mode_p,
    timekeeper_ready_p
    );

    input               clk210_p;                               // the module runs at 105MHz
    input               reset_p;
    input               sdo_p;
    input               adc_sampling_mode_p;    
    input               timekeeper_ready_p;
    
    output              adc_data_in_p;
    output              cnv_p;                                  // convert signal to ADC
    output              sck_p;                                  // clock to ADC
    output              adc_data_received_p;
    
    // port declarations
    wire                cnv_p;
    wire                sck_p;
                                                       
    // register declaration                            
    reg                 pulse_5MHz_s                =  1'd0;    // pulses every (PULSE_5MHZ_COUNT_param/210) microseconds
    reg         [31:0]  pulse_5MHz_counter_s        = 32'd0;
    reg         [ 7:0]  cnv_counter_s               =  8'd0;
    reg         [ 7:0]  sck_counter_s               =  8'd0;
    reg         [ 7:0]  sck_start_counter_s         =  8'd0;
    reg                 cnv_s                       =  1'b0;
    reg                 sck_s                       =  1'b1;
    reg                 adc_data_received_s         =  1'b0;
    wire        [ 1:0]  adc_sampling_mode_p;
    wire                timekeeper_ready_p;
    
    reg         [ 7:0]  adc_intfc_state_s           =  8'd0;
    wire        [15:0]  adc_data_in_p;
    reg         [15:0]  adc_data_in_s               = 16'd0;
    wire                adc_data_received_p;
    reg         [ 7:0]  DOWNSAMPLE_RATE_paramntr_s  =  8'd0;
        
    reg         [ 7:0]  CNV_MAX_COUNT_param         =  8'd5;
    reg         [ 7:0]  SCK_COUNT_MAX_param         =  8'd16;
    reg         [ 7:0]  DOWNSAMPLE_RATE_param       =  8'd0;
    reg         [31:0]  PULSE_5MHZ_COUNT_param      = 32'd42;
        
    // Output Declarations
    assign  adc_data_in_p       = adc_data_in_s;
    assign  sck_p               = sck_s;
    assign  cnv_p               = cnv_s;
    assign  adc_data_received_p = adc_data_received_s;
    
    // parameters for state machine
    parameter   [ 7:0]  IDLE_st                 = 8'd0;         // Waits for the 0.2us 'sync' 
    parameter   [ 7:0]  GENERATE_CNV_st         = 8'd1;         // generates the CNV signal
    parameter   [ 7:0]  ONE_CLOCK_DELAY_st      = 8'd2;         // a clock delay for the 9.5 ns delay from the time CNV falls
    parameter   [ 7:0]  GENERATE_SCK_LOW_st     = 8'd3;         // SCK falls
    parameter   [ 7:0]  GENERATE_SCK_HIGH_st    = 8'd4;         // SCK rises
    
    // parameter   [31:0]  PULSE_5MHZ_COUNT_param      = 32'd100000;      // set to 42 to sample at 5MHz. Increase the number to decrease sampling rate
                                                                // 2100_000 gives a 10ms sampling rate.
    // parameter   [ 7:0]  CNV_MAX_COUNT_param         = 8'd500;        // 5 for max 
    // parameter   [ 7:0]  SCK_COUNT_MAX_param         = 8'd16;
    // parameter   [ 7:0]  DOWNSAMPLE_RATE_param       = 8'd500;
 
    parameter   [ 1:0]  MODE1_c         = 2'b00;
    parameter   [ 1:0]  MODE2_c         = 2'b01;
    parameter   [ 1:0]  MODE3_c         = 2'b10;
    parameter   [ 1:0]  MODE4_c         = 2'b11;
    
    //-----------------------------------------------------------------------//
    // Here, the Flight computer has the option to change the sampling rates
    // of the ADCs and it can do so in 4 different modes
    // MODE      BITs         
    // MODE 1 -> 00
    // MODE 2 -> 01
    // MODE 3 -> 10
    // MODE 4 -> 11
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            CNV_MAX_COUNT_param         <=  8'd5; 
            SCK_COUNT_MAX_param         <=  8'd16;
            DOWNSAMPLE_RATE_param       <=  8'd0;
            PULSE_5MHZ_COUNT_param      <= 32'd42;
            end
        else begin
            if (adc_data_received_s) begin
                case(adc_sampling_mode_p) 
                MODE1_c: begin
                    CNV_MAX_COUNT_param         <=  8'd5; 
                    SCK_COUNT_MAX_param         <=  8'd16;
                    DOWNSAMPLE_RATE_param       <=  8'd0; 
                    PULSE_5MHZ_COUNT_param      <= 32'd42;
                    end
                MODE2_c: begin
                    CNV_MAX_COUNT_param         <=  8'd32; 
                    SCK_COUNT_MAX_param         <=  8'd16;
                    DOWNSAMPLE_RATE_param       <=  8'd32;
                    PULSE_5MHZ_COUNT_param      <= 32'd2000;
                    end
                MODE3_c: begin
                    CNV_MAX_COUNT_param         <=  8'd5; 
                    SCK_COUNT_MAX_param         <=  8'd16;
                    DOWNSAMPLE_RATE_param       <=  8'd0;
                    PULSE_5MHZ_COUNT_param      <= 32'd42;
                    end
                MODE4_c: begin
                    CNV_MAX_COUNT_param         <=  8'd5; 
                    SCK_COUNT_MAX_param         <=  8'd16;
                    DOWNSAMPLE_RATE_param       <=  8'd0;
                    PULSE_5MHZ_COUNT_param      <= 32'd42;
                    end
                default: begin
                    CNV_MAX_COUNT_param         <=  8'd255; 
                    SCK_COUNT_MAX_param         <=  8'd16;
                    DOWNSAMPLE_RATE_param       <=  8'd255;
                    PULSE_5MHZ_COUNT_param      <= 32'd100000;
                    end
                endcase
            end
        end
    end
    //-----------------------------------------------------------------------//
    // generates pulses every 21 cycles - lasts for 1 210 MHz clock cycle
    // These pulses synchronize the state machine that will be used to collect
    // data from the ADC
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if(reset_p) begin   
            pulse_5MHz_s <=  1'b0;
            end
        else begin
            if (timekeeper_ready_p == 1'b1) begin
                if(pulse_5MHz_counter_s == PULSE_5MHZ_COUNT_param) begin
                    pulse_5MHz_s            <= 1'd1;
                    pulse_5MHz_counter_s    <= 32'd0; 
                    end
                else begin   
                    pulse_5MHz_s            <= 1'd0;
                    pulse_5MHz_counter_s    <= pulse_5MHz_counter_s + 1'd1;
                end
                end
            else begin
                pulse_5MHz_s            <= 1'd0;
            end
        end
    end
    
    
    //-----------------------------------------------------------------------//
    // STATE MACHINE: Data collection
    // This state machine will collect data from the ADC every 0.2 us. 
    // After collecting a sample, it sends a data_received signal to the higher
    // module which then grabs it and takes it from there.
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            adc_intfc_state_s       <= IDLE_st;
            cnv_counter_s           <= 8'd0;
            cnv_s                   <= 1'b0;  
            sck_s                   <= 1'b1;
            adc_data_received_s     <= 1'b0;
            sck_counter_s           <= 8'd0;
            DOWNSAMPLE_RATE_paramntr_s  <= 8'd0;
            end
        else begin
            case (adc_intfc_state_s)
            
            // IDLE state is where the SM waits for a pulse from the pulse_5MHz_counter_s
            // to indicate that a new conversion cycle needs to start
            IDLE_st: begin
                    if (pulse_5MHz_s == 1'b1) begin
                        adc_intfc_state_s   <= GENERATE_CNV_st;
                        cnv_s               <= 1'b1;                    // start the CNV signal.
                        adc_data_received_s <= 1'b0;
                        end
                    else begin
                        cnv_s               <= 1'b0;
                        sck_s               <= 1'b1;
                        adc_data_received_s <= 1'b0;
                    end
                end
                
            // This state generates the CNV pulse. The CNV pulse is used on the ADC to 
            // sample the analog signal. Once, CNV is pulled low, the ADC starts converting the
            // analog sample to a 16 bit digital number
            // CNV will be raised up for 28.57 ns. The minimum time it needs to be high is 25 ns
            GENERATE_CNV_st: begin
                    if (cnv_counter_s == CNV_MAX_COUNT_param) begin
                        cnv_s               <= 1'b0;
                        cnv_counter_s       <= 8'd0;
                        adc_intfc_state_s   <= ONE_CLOCK_DELAY_st;
                        end
                    else begin
                        cnv_counter_s       <= cnv_counter_s + 1;
                    end
                end
                
            // This state is just an intermediary between the CNV state and the SCK state. 
            // It gives a one clock delay and this helps to acheive the minimum of 9.5 ns 
            // delay that is needed from the the time CNV falls to the time SCK is started
            ONE_CLOCK_DELAY_st: begin
                    adc_intfc_state_s       <= GENERATE_SCK_LOW_st;
                end
                
            // This state will generate the SCK clock. Data from the ADC is shifted out on the falling edge
            // and it needs to be grabbed in on the rising edge of SCK (i.e, in the GENERATE_SCK_HIGH_st)
            GENERATE_SCK_LOW_st: begin
                    if (DOWNSAMPLE_RATE_paramntr_s == DOWNSAMPLE_RATE_param) begin
                        DOWNSAMPLE_RATE_paramntr_s  <= 8'd0;
                        sck_s                   <= 1'b0;
                        sck_counter_s           <= sck_counter_s + 1;
                        adc_intfc_state_s       <= GENERATE_SCK_HIGH_st;
                        end
                    else begin
                        DOWNSAMPLE_RATE_paramntr_s  <= DOWNSAMPLE_RATE_paramntr_s + 1;
                    end                   
                end
                
            // This is the state where the SCK is pulled high. Once, it reaches 16 counts, it is left high and 
            // the state machine moves back to the IDLE state. Also, when it reaches 16 counts, it raises a 
            // data_received signal to indicate to the higher module that a data sample was received.
            GENERATE_SCK_HIGH_st: begin
                    if (DOWNSAMPLE_RATE_paramntr_s == DOWNSAMPLE_RATE_param) begin
                        DOWNSAMPLE_RATE_paramntr_s  <= 8'd0;
                        if (sck_counter_s == SCK_COUNT_MAX_param) begin
                            sck_s               <= 1'b1;
                            sck_counter_s       <= 8'd0;
                            adc_data_in_s       <= {adc_data_in_s[14:0], sdo_p}; 
                            adc_data_received_s <= 1'b1;                            // pulsed for one clock cycle.
                            adc_intfc_state_s   <= IDLE_st;
                            end
                        else begin
                            sck_s               <= 1'b1;
                            adc_data_in_s       <= {adc_data_in_s[14:0], sdo_p};    // shift the SDO bit into the LSB and then shift 
                                                                                    // the adc_data register by one bit. 
                                                                                    // The ADC puts out the MSB first. 
                            adc_intfc_state_s   <= GENERATE_SCK_LOW_st;                        
                            end
                        end
                    else begin
                        DOWNSAMPLE_RATE_paramntr_s  <= DOWNSAMPLE_RATE_paramntr_s + 1;
                    end
                end
    
            default: begin
                    adc_intfc_state_s       <= IDLE_st;
                end
            endcase
        end
    end
  
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2017 01:25:45 PM
// Design Name: 
// Module Name: processing_top
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


module processing_top(
    clk210_p,                   // INPUT  -  1 bit  - 210 MHz clock
    reset_p,                    // INPUT  -  1 bit  - reset
    fifo_adc_rd_en_p,           // OUTPUT -  1 bit  - read enable to the preprocessing FIFO
    fifo_adc_data_count_p,      // INPUT  - 10 bits - data count of the preprocessing FIFO
    fifo_adc_dout_p,            // INPUT  - 80 bits - data out from the preprocessing FIFO (64 bit time stamp and 16 bit ADC value)
    fifo_processing_rd_en_p,    // INPUT  -  1 bit  - read enable for the processing FIFO
    fifo_processing_dout_p,     // OUTPUT -    bits - dout from the processing FIFO 
    fifo_processing_data_count_p,// OUTPUT -    bits - data count of the processing FIFO 
    adc_threshold_p,             // INPUT  - 16 bits - threshold that is set by the Flight Computer. This comes from the Memory Map.
    fifo_adc_empty_p
    );
    
    input               clk210_p;
    input               reset_p;
    input               fifo_adc_data_count_p;
    input               fifo_adc_dout_p;
    input               fifo_processing_rd_en_p;
    input               adc_threshold_p;
    input               fifo_adc_empty_p;
    
    output              fifo_adc_rd_en_p;
    output              fifo_processing_data_count_p;
    output              fifo_processing_dout_p;

    //-----------------------------------------------------------------------//
    // Parameter list for the State Machine
    //-----------------------------------------------------------------------//
    parameter   [ 7:0]  IDLE_st             = 8'd0;
    parameter   [ 7:0]  FILL_UP_BUFFER_st   = 8'd0;
    parameter   [ 7:0]  PULL_DWN_RD_EN_st   = 8'd1;
    parameter   [ 7:0]  WRITE_TO_BUFFER_st  = 8'd2;
    parameter   [ 7:0]  GET_DATA_st         = 8'd3;
    parameter   [ 7:0]  PASS_TAIL_LOOP_1_st   = 8'd4;
    parameter   [ 7:0]  PASS_TAIL_LOOP_2_st   = 8'd5;
    parameter   [ 7:0]  COMPUTE_PARAMETERS_st   =8'd6;
    parameter   [ 7:0]  DELAY_1_CLOCK_st       =8'd7;
    parameter   [ 7:0]  DELAY_2_CLOCK_st       =8'd8;
    // parameters for some constants
    parameter   [ 7:0]  BUFFER_LENGTH_c     = 8'd17;        // If the state machine see that the preprocessing
                                                            // FIFOs have data greater than this amount, the 
    parameter   [ 7:0]  BUFFER_INNER_LENGTH_c   = 8'd15;    
    parameter   [ 7:0]  TAIL_LENGTH         =8'd25;
    
    //-----------------------------------------------------------------------//
    // Variable Declarations
    //-----------------------------------------------------------------------//    
    
    // normal variables used in the module
    reg         [ 7:0]  processing_state_s  = 8'd0;
    reg         [79:0]  buffer_s [0:BUFFER_LENGTH_c];
    reg         [ 7:0]  buffer_index_s      = 8'd1;
    reg         [ 7:0]  loop_counter        = 8'b1;
    // preprocessing fifo
    reg                 fifo_adc_rd_en_s    = 1'b0;
    wire        [ 9:0]  fifo_adc_data_count_p;
    wire        [79:0]  fifo_adc_dout_p;
    wire        [15:0]  adc_threshold_p;
    reg         [79:0]  data_from_fifo_s    = 80'd0;
    wire                fifo_adc_empty_p;
    // variables used for the fifo
    // note that the FIFO's width hasn't been decided yet; this will depend on the parameter
    // bit widths
    reg         [107:0] fifo_processing_din_s   = 108'd0;  
    reg                 fifo_processing_wr_en_s =  1'b0;
    wire                fifo_processing_rd_en_p;    
    wire        [107:0] fifo_processing_dout_p;
    wire                fifo_processing_full_s;
    wire                fifo_processing_empty_s;
    reg         [11:0]  fifo_processing_data_count_s   = 12'd0;
    wire        [11:0]  fifo_processing_data_count_p;    
    
    //  iteration variables - data buffer, parameter A, C, LUT, error
    reg         [15:0]  Databuff    [1:16];
    reg         [13:0]  pa;
    reg         [6:0]   pc          [1:16];
    reg         [9:0]   lut         [1:61];
    reg         [18:0]  err         [1:16];
    reg         [19:0]  suma        [1:8];
    reg         [20:0]  sumb        [1:4];
    reg         [21:0]  sumc        [1:2];
    reg         [23:0]  error_sum;
    reg         [23:0]  pre_error;    
    reg         [25:0]  cfvalue     [1:16];
    reg         [9:0]   cflut       [1:16];
    reg         [18:0]  cfint       [1:16];
    reg         [5:0]   cf_state;
    reg                 cf_flag;
    reg         [15:0]  re_a;
    reg         [7:0]   re_c;
    reg         [63:0]  start_time;
    reg                 done;
    // initial values for parameters
    initial
    begin
        // initial state
        cf_state<=0;
        cf_flag<=0;
        done<=0;
        re_a<=0;
        re_c<=0;
        start_time<=0;
        // lut 3bit integer + 7bit decimal
        lut[1] <= 0;
        lut[2] <= 0;
        lut[3] <= 0;
        lut[4] <= 0;
        lut[5] <= 0;
        lut[6] <= 0;
        lut[7] <= 0;
        lut[8] <= 0;
        lut[9] <= 0;
        lut[10] <= 35;
        lut[11] <= 47;
        lut[12] <= 61;
        lut[13] <= 77;
        lut[14] <= 94;
        lut[15] <= 113;
        lut[16] <= 134;
        lut[17] <= 156;
        lut[18] <= 179;
        lut[19] <= 203;
        lut[20] <= 227;
        lut[21] <= 252;
        lut[22] <= 277;
        lut[23] <= 302;
        lut[24] <= 327;
        lut[25] <= 352;
        lut[26] <= 376;
        lut[27] <= 399;
        lut[28] <= 421;
        lut[29] <= 443;
        lut[30] <= 463;
        lut[31] <= 482;
        lut[32] <= 500;
        lut[33] <= 516;
        lut[34] <= 531;
        lut[35] <= 545;
        lut[36] <= 557;
        lut[37] <= 567;
        lut[38] <= 576;
        lut[39] <= 584;
        lut[40] <= 590;
        lut[41] <= 594;
        lut[42] <= 598;
        lut[43] <= 600;
        lut[44] <= 600;
        lut[45] <= 600;
        lut[46] <= 598;
        lut[47] <= 595;
        lut[48] <= 591;
        lut[49] <= 586;
        lut[50] <= 580;
        lut[51] <= 573;
        lut[52] <= 566;
        lut[53] <= 557;
        lut[54] <= 549;
        lut[55] <= 539;
        lut[56] <= 529;
        lut[57] <= 518;
        lut[58] <= 507;
        lut[59] <= 496;
        lut[60] <= 485;
        lut[61] <= 473;

        // initial sum of errors
        suma[1]<=0;
        suma[2]<=0;
        suma[3]<=0;
        suma[4]<=0;
        suma[5]<=0;
        suma[6]<=0;
        suma[7]<=0;
        suma[8]<=0;
        sumb[1]<=0;
        sumb[2]<=0;
        sumb[3]<=0;
        sumb[4]<=0;
        sumc[1]<=0;
        sumc[2]<=0;
        // initial errors
        error_sum<=0;
        pre_error<=30000;
        err[1]<=0;
        err[2]<=0;
        err[3]<=0;
        err[4]<=0;
        err[5]<=0;
        err[6]<=0;
        err[7]<=0;
        err[8]<=0;
        err[9]<=0;
        err[10]<=0;
        err[11]<=0;
        err[12]<=0;
        err[13]<=0;
        err[14]<=0;
        err[15]<=0;
        err[16]<=0;
        // initial parameters
        pa<=0;
        pc[1]<=10;
        pc[2]<=12;
        pc[3]<=14;
        pc[4]<=16;
        pc[5]<=18;
        pc[6]<=20;
        pc[7]<=22;
        pc[8]<=24;
        pc[9]<=26;
        pc[10]<=28;
        pc[11]<=30;
        pc[12]<=32;
        pc[13]<=34;
        pc[14]<=36;
        pc[15]<=38;
        pc[16]<=40;
        // initial cf values
        cfvalue[1]<=0;
        cfvalue[2]<=0;
        cfvalue[3]<=0;
        cfvalue[4]<=0;
        cfvalue[5]<=0;
        cfvalue[6]<=0;
        cfvalue[7]<=0;
        cfvalue[8]<=0;
        cfvalue[9]<=0;
        cfvalue[10]<=0;
        cfvalue[11]<=0;
        cfvalue[12]<=0;
        cfvalue[13]<=0;
        cfvalue[14]<=0;
        cfvalue[15]<=0;
        cfvalue[16]<=0;
        
        // cflut
        cflut[1]<=0;
        cflut[2]<=0;
        cflut[3]<=0;
        cflut[4]<=0;
        cflut[5]<=0;
        cflut[6]<=0;
        cflut[7]<=0;
        cflut[8]<=0;
        cflut[9]<=0;
        cflut[10]<=0;
        cflut[11]<=0;
        cflut[12]<=0;
        cflut[13]<=0;
        cflut[14]<=0;
        cflut[15]<=0;
        cflut[16]<=0;
        
        // cfint
        cfint[1]<=0;
        cfint[2]<=0;
        cfint[3]<=0;
        cfint[4]<=0;
        cfint[5]<=0;
        cfint[6]<=0;
        cfint[7]<=0;
        cfint[8]<=0;
        cfint[9]<=0;
        cfint[10]<=0;
        cfint[11]<=0;
        cfint[12]<=0;
        cfint[13]<=0;
        cfint[14]<=0;
        cfint[15]<=0;
        cfint[16]<=0;
        
    end
    //-----------------------------------------------------------------------//
    // Output Assignments
    //-----------------------------------------------------------------------//
    assign  fifo_processing_data_count_p     = fifo_processing_data_count_s;
    assign  fifo_adc_rd_en_p                 = fifo_adc_rd_en_s;

    //-----------------------------------------------------------------------//
    // FIFO Module Declaration
    //-----------------------------------------------------------------------//
    fifo_processing fifo_processing_inst(
    .clk                    (clk210_p),                 // INPUT  -  1 bit  - 210 MHz clock
    .rst                    (reset_p),                  // INPUT  -  1 bit  - reset
    .din                    (fifo_processing_din_s),    // INPUT  -  bits - data input bus to the fifo
    .wr_en                  (fifo_processing_wr_en_s),  // INPUT  -  1 bit  - Write enable to the fifo
    .rd_en                  (fifo_processing_rd_en_p),  // INPUT  -  1 bit  - read enable to the fifo
    .dout                   (fifo_processing_dout_p),   // OUTPUT -  bits - data output bus from the fifo
    .full                   (fifo_processing_full_s),   // OUTPUT -  1 bit  - Full flag from the FIFO
    .empty                  (fifo_processing_empty_s)   // OUTPUT -  1 bit  - Empty flag 
    );
    
    //-----------------------------------------------------------------------//
    // FIFO Data Count Tracker -
    // Care needs to be taken that a write enable or a read enable shouldn't be issued
    // when the FIFO is either full or empty else the data count will be false.
    // This should be fixed later
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            fifo_processing_data_count_s    <= 0;
            end
        else begin
            if (fifo_processing_wr_en_s == 1'b1) begin          // counts up if there was a write enable
                fifo_processing_data_count_s    <= fifo_processing_data_count_s + 1'b1;
                end
            else if (fifo_processing_rd_en_p == 1'b1) begin     // counts down if there was a read enable
                fifo_processing_data_count_s    <= fifo_processing_data_count_s - 1'b1;
                end
            else begin
                fifo_processing_data_count_s    <= fifo_processing_data_count_s;
            end
        end
    end
    
    //-----------------------------------------------------------------------//
    // State Machine for the Curve Fitting Alogorithm
    // Description: This is where the curve fitting algorithm is implemented
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            processing_state_s      <= IDLE_st;
            fifo_adc_rd_en_s        <= 1'b0;
            end
        else begin
            
            case (processing_state_s)
            
            // This is an idle state. Wait for the data count in the preprocessing FIFOs to 
            // exceed a certain amount.
            IDLE_st: begin
                    if (fifo_adc_data_count_p > BUFFER_LENGTH_c) begin
                        processing_state_s  <= GET_DATA_st;
                        end
                    else begin
                        processing_state_s  <= IDLE_st;
                    end
                end
            
            // Here is where the data will be stored into a 2D array
            GET_DATA_st: begin
                    if (fifo_adc_empty_p) begin
                        processing_state_s  <= IDLE_st;
                    end
                    else if (buffer_index_s < BUFFER_LENGTH_c) begin
                        processing_state_s  <= PULL_DWN_RD_EN_st;
                        fifo_adc_rd_en_s    <= 1'b1;    
                        end
                    else begin  // curve fitting begin
                        processing_state_s  <= COMPUTE_PARAMETERS_st;
                        buffer_index_s      <= 1;
                        cf_flag             <= 1;
                        // start_time          <= fifo_adc_dout_p[79:16] - BUFFER_INNER_LENGTH_c;
                        start_time          <= buffer_s[1][79:16];
                    end
                end
            //----------------------------------------------------------------------//
            //  Need a loop to pass the tail part of the pulse after curve fitting  //
            //----------------------------------------------------------------------//
            COMPUTE_PARAMETERS_st: begin
                cf_flag <= 1'b0;
                if(done)
                begin
                    processing_state_s  <= PASS_TAIL_LOOP_1_st;

                end
                else
                begin
                    processing_state_s  <= COMPUTE_PARAMETERS_st;
                end
            end    
            // Pull down read enable of the preprocessing fifo. It is pulled
            // up for only 1 clock cycle
            PULL_DWN_RD_EN_st: begin
                    fifo_adc_rd_en_s        <= 1'b0;
                    processing_state_s      <= DELAY_1_CLOCK_st;
                end
                
            DELAY_1_CLOCK_st: begin
                    data_from_fifo_s        <= fifo_adc_dout_p;
                    processing_state_s      <= WRITE_TO_BUFFER_st;
                end
                
            // DELAY_2_CLOCK_st: begin
                    // processing_state_s      <= WRITE_TO_BUFFER_st;
                // end
                
            // Write the data obtained to the data buffer
            // Threshold
            WRITE_TO_BUFFER_st: begin
                    if ((data_from_fifo_s[14:0] > adc_threshold_p[14:0]) && (data_from_fifo_s[15] != 1'b1)) begin
                        // buffer_s[buffer_index_s]<= data_from_fifo_s;
                        // buffer_s[buffer_index_s]<= fifo_adc_dout_p;
                        // Databuff[buffer_index_s]<=fifo_adc_dout_p[15:0];    // data for curve fitting
                        // buffer_index_s          <= buffer_index_s + 1;
                        processing_state_s      <= 8'd10;
                        // processing_state_s      <= GET_DATA_st;
                    end
                    else begin
                        buffer_index_s <= 1;
                        processing_state_s      <= GET_DATA_st;
                    end
                end
                
            10: begin
                buffer_s[buffer_index_s]<= data_from_fifo_s;
                buffer_index_s          <= buffer_index_s + 1;
                processing_state_s      <= GET_DATA_st;
                end
            // Since we only use first part of a pulse, we need to skip the tail part of teh pulse.
            PASS_TAIL_LOOP_1_st: begin
                if (loop_counter < TAIL_LENGTH) begin
                    fifo_adc_rd_en_s    <= 1'b1;
                    loop_counter <= loop_counter + 'b1;
                    processing_state_s <= PASS_TAIL_LOOP_2_st;
                    end
                else begin
                    loop_counter <= 0;
                    processing_state_s <= IDLE_st;
                    end
                end
            PASS_TAIL_LOOP_2_st: begin
                processing_state_s <= PASS_TAIL_LOOP_1_st;
                fifo_adc_rd_en_s        <= 1'b0;
                end
        endcase
    end
    end
            // Start curve fitting algorithm on the buffered data here.
    //-------------------------------------------------------------------------//
    //  Curve Fitting Algorithm
    //  One Pulse Solution
    //  Simple iteration
    //-------------------------------------------------------------------------//
    
    
    always @(posedge clk210_p)
    begin
        case(cf_state)
        // idle state
        0:
        begin
            done <= 0;
            if(cf_flag==1'b0)
            begin
                cf_state<=0;
            end
            else
            begin
                // reset result
                pre_error <= 'd30000;
                re_a <= 'd0;
                re_c <= 'd10;
                cf_state<=1;
            end
         end
        // parameter a & c generator
        1:
        begin
            if (pc[1]==30)     // after c reach 30, increase pa by 240
            begin
                pc[1]<=10;
                pc[2]<=12;
                pc[3]<=14;
                pc[4]<=16;
                pc[5]<=18;
                pc[6]<=20;
                pc[7]<=22;
                pc[8]<=24;
                pc[9]<=26;
                pc[10]<=28;
                pc[11]<=30;
                pc[12]<=32;
                pc[13]<=34;
                pc[14]<=36;
                pc[15]<=38;
                pc[16]<=40;
                pa <= pa + 'd60;
                cf_state <= 2;
            end
            else if (pa>8000)     // after pa reach 14000, end irritation
            begin
                cf_state <= 10;
            end
            else            // in  normal case, increase c by 1
            begin
                pc[1]<=pc[2];
                pc[2]<=pc[3];
                pc[3]<=pc[4];
                pc[4]<=pc[5];
                pc[5]<=pc[6];
                pc[6]<=pc[7];
                pc[7]<=pc[8];
                pc[8]<=pc[9];
                pc[9]<=pc[10];
                pc[10]<=pc[11];
                pc[11]<=pc[12];
                pc[12]<=pc[13];
                pc[13]<=pc[14];
                pc[14]<=pc[15];
                pc[15]<=pc[16];
                pc[16]<=pc[16]+2;
                cf_state <= 2;
            end
        end
        // curve value calculation
        2:
        begin
            cflut[1] <= lut[pc[1]];
            cflut[2] <= lut[pc[2]];
            cflut[3] <= lut[pc[3]];
            cflut[4] <= lut[pc[4]];
            cflut[5] <= lut[pc[5]];
            cflut[6] <= lut[pc[6]];
            cflut[7] <= lut[pc[7]];
            cflut[8] <= lut[pc[8]];
            cflut[9] <= lut[pc[9]];
            cflut[10] <= lut[pc[10]];
            cflut[11] <= lut[pc[11]];
            cflut[12] <= lut[pc[12]];
            cflut[13] <= lut[pc[13]];
            cflut[14] <= lut[pc[14]];
            cflut[15] <= lut[pc[15]];
            cflut[16] <= lut[pc[16]];
            cf_state <= 13;
        end
        13:
        begin
            cfvalue[1] <= pa * cflut[1];
            cfvalue[2] <= pa * cflut[2];
            cfvalue[3] <= pa * cflut[3];
            cfvalue[4] <= pa * cflut[4];
            cfvalue[5] <= pa * cflut[5];
            cfvalue[6] <= pa * cflut[6];
            cfvalue[7] <= pa * cflut[7];
            cfvalue[8] <= pa * cflut[8];
            cfvalue[9] <= pa * cflut[9];
            cfvalue[10] <= pa * cflut[10];
            cfvalue[11] <= pa * cflut[11];
            cfvalue[12] <= pa * cflut[12];
            cfvalue[13] <= pa * cflut[13];
            cfvalue[14] <= pa * cflut[14];
            cfvalue[15] <= pa * cflut[15];
            cfvalue[16] <= pa * cflut[16];
            cf_state <= 14;
        end
        // error calculation
        14:
        begin
            cfint[ 1] <= cfvalue[1][25:7];
            cfint[ 2] <= cfvalue[2][25:7];
            cfint[ 3] <= cfvalue[3][25:7];
            cfint[ 4] <= cfvalue[4][25:7];
            cfint[ 5] <= cfvalue[5][25:7];
            cfint[ 6] <= cfvalue[6][25:7];
            cfint[ 7] <= cfvalue[7][25:7];
            cfint[ 8] <= cfvalue[8][25:7];
            cfint[ 9] <= cfvalue[9][25:7];
            cfint[10] <= cfvalue[10][25:7];
            cfint[11] <= cfvalue[11][25:7];
            cfint[12] <= cfvalue[12][25:7];
            cfint[13] <= cfvalue[13][25:7];
            cfint[14] <= cfvalue[14][25:7];
            cfint[15] <= cfvalue[15][25:7];
            cfint[16] <= cfvalue[16][25:7];
            cf_state <= 3;
        end
        3:
        begin
            err[ 1] <= cfint[1] - { 3'b000 , buffer_s[ 1][15:0]};
            err[ 2] <= cfint[2] - { 3'b000 , buffer_s[ 2][15:0]};
            err[ 3] <= cfint[3] - { 3'b000 , buffer_s[ 3][15:0]};
            err[ 4] <= cfint[4] - { 3'b000 , buffer_s[ 4][15:0]};
            err[ 5] <= cfint[5] - { 3'b000 , buffer_s[ 5][15:0]};
            err[ 6] <= cfint[6] - { 3'b000 , buffer_s[ 6][15:0]};
            err[ 7] <= cfint[7] - { 3'b000 , buffer_s[ 7][15:0]};
            err[ 8] <= cfint[8] - { 3'b000 , buffer_s[ 8][15:0]};
            err[ 9] <= cfint[9] - { 3'b000 , buffer_s[ 9][15:0]};
            err[10] <= cfint[10] - { 3'b000 , buffer_s[10][15:0]};
            err[11] <= cfint[11] - { 3'b000 , buffer_s[11][15:0]};
            err[12] <= cfint[12] - { 3'b000 , buffer_s[12][15:0]};
            err[13] <= cfint[13] - { 3'b000 , buffer_s[13][15:0]};
            err[14] <= cfint[14] - { 3'b000 , buffer_s[14][15:0]};                                          
            err[15] <= cfint[15] - { 3'b000 , buffer_s[15][15:0]};
            err[16] <= cfint[16] - { 3'b000 , buffer_s[16][15:0]};
            cf_state <= 4;
        end
        
//        3:
//        begin
//            err[ 1] <= buffer_s[ 1][15:0] - cfvalue[1][25:10];
//            err[ 2] <= buffer_s[ 2][15:0] - cfvalue[2][25:10];
//            err[ 3] <= buffer_s[ 3][15:0] - cfvalue[3][25:10];
//            err[ 4] <= buffer_s[ 4][15:0] - cfvalue[4][25:10];
//            err[ 5] <= buffer_s[ 5][15:0] - cfvalue[5][25:10];
//            err[ 6] <= buffer_s[ 6][15:0] - cfvalue[6][25:10];
//            err[ 7] <= buffer_s[ 7][15:0] - cfvalue[7][25:10];
//            err[ 8] <= buffer_s[ 8][15:0] - cfvalue[8][25:10];
//            err[ 9] <= buffer_s[ 9][15:0] - cfvalue[9][25:10];
//            err[10] <= buffer_s[10][15:0] - cfvalue[10][25:10];
//            err[11] <= buffer_s[11][15:0] - cfvalue[11][25:10];
//            err[12] <= buffer_s[12][15:0] - cfvalue[12][25:10];
//            err[13] <= buffer_s[13][15:0] - cfvalue[13][25:10];
//            err[14] <= buffer_s[14][15:0] - cfvalue[14][25:10];                                          
//            err[15] <= buffer_s[15][15:0] - cfvalue[15][25:10];
//            err[16] <= buffer_s[16][15:0] - cfvalue[16][25:10];
//            cf_state <= 4;
//        end
        
        // positive value
        4:
        begin
            if (err[1][18])
                err[1] <= 0-err[1];
            if (err[2][18])
                err[2] <= 0-err[2];
            if (err[3][18])
                err[3] <= 0-err[3];
            if (err[4][18])
                err[4] <= 0-err[4];
            if (err[5][18])
                err[5] <= 0-err[5];
            if (err[6][18])
                err[6] <= 0-err[6];
            if (err[7][18])
                err[7] <= 0-err[7];
            if (err[8][18])
                err[8] <= 0-err[8];
            if (err[9][18])
                err[9] <= 0-err[9];
            if (err[10][18])
                err[10] <= 0-err[10];
            if (err[11][18])
                err[11] <= 0-err[11];
            if (err[12][18])
                err[12] <= 0-err[12];
            if (err[13][18])
                err[13] <= 0-err[13];
            if (err[14][18])
                err[14] <= 0-err[14];
            if (err[15][18])
                err[15] <= 0-err[15];
            if (err[16][18])
                err[16] <= 0-err[16];
            cf_state <= 5;
        end
        // sum of errors
        5:
        begin
            suma[1] <= err[1] + err[2];
            suma[2] <= err[3] + err[4];
            suma[3] <= err[5] + err[6];
            suma[4] <= err[7] + err[8];
            suma[5] <= err[9] + err[10];
            suma[6] <= err[11] + err[12];
            suma[7] <= err[13] + err[14];
            suma[8] <= err[15] + err[16];
            cf_state <= 6;
        end
        6:
        begin
            sumb[1] <= suma[1] + suma[2];
            sumb[2] <= suma[3] + suma[4];
            sumb[3] <= suma[5] + suma[6];
            sumb[4] <= suma[7] + suma[8];
            cf_state <= 7;
        end
        7:
        begin
            sumc[1] <= sumb[1] + sumb[2];
            sumc[2] <= sumb[3] + sumb[4];
            cf_state <= 8;
        end
        8:
        begin
            error_sum <= sumc[1] + sumc[2];
            cf_state <= 9;
        end
        // compare and update error
        9:
        begin
            if(error_sum < pre_error)
            begin
                pre_error <= error_sum;
                re_a <= pa;
                re_c <= pc[1];
            end
            error_sum <= 0;
            cf_state <= 1;
        end
        //reset
        10:
        begin
            if (fifo_processing_full_s == 1'b0) begin
                fifo_processing_din_s <= {re_a,re_c,pre_error[19:0],start_time};
                cf_state <= 15;
                end
            else begin
                cf_state    <= 10;
            end
        end
        15: begin
            cf_state    <= 11;
            end
        
        11: begin
                fifo_processing_wr_en_s <= 1;
                cf_state                <= 12;
            end
        12:
        begin
            fifo_processing_wr_en_s <= 0;
            pa <= 0;
            cf_state <= 0;
            done <= 1;
        end
        
        endcase
    end

endmodule

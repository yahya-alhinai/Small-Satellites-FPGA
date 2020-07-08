`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2017 09:37:26 PM
// Design Name: 
// Module Name: TB_adc_model
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This code emulates an ADC. It gets the data that it needs to send from a text file
//              and sends the data out based on the SCK.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TB_adc_model(
    reset_p,
    cnv_p,
    sdo_p,
    sck_p
    );
    
    input               reset_p;
    input               cnv_p;
    input               sck_p;
    
    output              sdo_p;
    
    //-----------------------------------------------------------------------//
    // Variable Declarations
    //-----------------------------------------------------------------------//
    reg         [15:0]  data_out_s;
    reg                 sdo_s                       = 1'b0;    
    
    reg         [ 7:0]  tb_adc_model_state_s        = 8'd0;
    reg         [ 7:0]  tb_sck_counts_s             = 8'd0;
    
    integer             data_file;
    integer             scan_file;
    reg         [15:0]  captured_data;
    //-----------------------------------------------------------------------//
    // Parameters
    //-----------------------------------------------------------------------//
    parameter   [ 7:0]  WAIT_FOR_CNV_HIGH_st    = 8'd0;
    parameter   [ 7:0]  WAIT_FOR_SCK_LOW_st     = 8'd1;
    parameter   [ 7:0]  WAIT_FOR_SCK_HIGH_st    = 8'd2;
    
    //-----------------------------------------------------------------------//
    // Output Assignments
    //-----------------------------------------------------------------------//
    assign              sdo_p       = sdo_s;       
    
    //-----------------------------------------------------------------------//
    // Initialize a file which has the ADC Data
    //-----------------------------------------------------------------------//
    initial begin
        data_file       = $fopen("C:/Code/SD_Card_Branch/FPGA-Code-CMOD-A7/sources/sim/DAT_adc_tb_data.txt","r");
        if (data_file == 0) begin
            $display("data_file handle was NULL");
            $finish;
        end
    end
    
    //-----------------------------------------------------------------------//
    // State machine to transfer the data out. 
    // 
    //-----------------------------------------------------------------------//
    always @(*)
    begin
        if (reset_p == 1'b1) begin
            tb_adc_model_state_s        = WAIT_FOR_CNV_HIGH_st;    
            end
        else begin
            case (tb_adc_model_state_s)
            
            // This is just a redundant state that looks for the CNV pulse.
            // Here is where a DWORD from the higher module is received to transfer out.
            WAIT_FOR_CNV_HIGH_st: begin
                    if (cnv_p == 1'b1) begin
                        scan_file = $fscanf(data_file, "%d\n", captured_data); 
                        if (!$feof(data_file)) begin
                            data_out_s              = captured_data;
                            tb_sck_counts_s         = 8'd0;
                            tb_adc_model_state_s    = WAIT_FOR_SCK_LOW_st;
                            end
                        else begin
                            $display("End of Data File");
                            // $finish;
                            tb_adc_model_state_s    = WAIT_FOR_CNV_HIGH_st;
                            end
                        end
                    else begin
                        tb_adc_model_state_s        = WAIT_FOR_CNV_HIGH_st;
                    end
                end
                
            // Wait for SCK to go low. Transfer the MSB out. 
            WAIT_FOR_SCK_LOW_st: begin
                    if (sck_p == 1'b0) begin
                        sdo_s                   = data_out_s[15];
                        data_out_s              = {data_out_s[14:0], 1'b1};
                        tb_sck_counts_s         = tb_sck_counts_s + 1;
                        tb_adc_model_state_s    = WAIT_FOR_SCK_HIGH_st;
                        end
                    else begin
                        tb_adc_model_state_s    = WAIT_FOR_SCK_LOW_st;
                    end
                end
    
            // Wait for SCK to go high.
            WAIT_FOR_SCK_HIGH_st: begin
                    if (sck_p == 1'b1) begin
                        if (tb_sck_counts_s == 8'd16) begin
                            tb_sck_counts_s         = 8'd0;
                            tb_adc_model_state_s    = WAIT_FOR_CNV_HIGH_st;
                            end
                        else begin
                            tb_adc_model_state_s    = WAIT_FOR_SCK_LOW_st;
                            end
                        end
                    else begin
                        tb_adc_model_state_s = WAIT_FOR_SCK_HIGH_st;
                    end
                end
                
            default: begin
                    tb_adc_model_state_s    = WAIT_FOR_CNV_HIGH_st;
                end
                
            endcase
            
        end
    
    end
            
            
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2017 02:56:43 PM
// Design Name: 
// Module Name: TB_SD_Card_Byte_Transfer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a testbench for byte transfers for the SD Card interface
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TB_SD_Card_Byte_Transfer(
    clk_p,
    tb_spi_sck_p,
    tb_spi_miso_p,
    tb_spi_mosi_p,
    tb_data_to_transfer_p,
    tb_init_transfer_p,
    tb_transfer_done_p,
    tb_spi_data_in_p
    );
    
    input               clk_p;
    input               tb_spi_sck_p;
    input               tb_data_to_transfer_p;
    input               tb_init_transfer_p;
    input               tb_spi_mosi_p;
    
    output              tb_spi_miso_p;
    output              tb_transfer_done_p;
    output              tb_spi_data_in_p;
    
    // Variables
    reg         [7:0]   spi_data_s          = 8'd0;
    reg         [7:0]   spi_state_s         = 8'd0;
    reg         [1:0]   sck_samples_s       = 2'd0;
    reg         [7:0]   sck_counts_s        = 8'd0;
    reg                 tb_transfer_done_s  = 1'b0;
    wire        [7:0]   tb_spi_data_in_p;
    reg         [7:0]   spi_data_in_s       = 8'd0;
    wire        [7:0]   tb_data_to_transfer_p;
    reg                 tb_spi_miso_s       = 1'b1;
    
    // Parameters
    parameter   [7:0]   IDLE_st             = 8'd0;    
    parameter   [7:0]   WAIT_FOR_RISING_st  = 8'd1;    
    parameter   [7:0]   WAIT_FOR_FALLING_st = 8'd2;
    parameter   [7:0]   CHECK_COUNT_st      = 8'd3;
    parameter   [7:0]   DONE_st             = 8'd4;
    
    // output assignments
    // assign      tb_spi_miso_p       = spi_data_s[7];
    assign      tb_spi_miso_p       = tb_spi_miso_s;
    assign      tb_transfer_done_p  = tb_transfer_done_s;
    assign      tb_spi_data_in_p    = spi_data_in_s;
    
    // Sample SCK Signal
    always @(posedge clk_p)
    begin
        sck_samples_s[0]    <= tb_spi_sck_p;
        sck_samples_s[1]    <= sck_samples_s[0];
    end
       
    
    always @(posedge clk_p)
    begin
        case(spi_state_s)
        
        IDLE_st: begin
                if (tb_init_transfer_p == 1'b1) begin
                    tb_spi_miso_s       <= tb_data_to_transfer_p[7];
                    spi_state_s         <= WAIT_FOR_RISING_st;
                    spi_data_s          <= {tb_data_to_transfer_p[6:0],1'b0};
                    sck_counts_s        <= 8'd0;
                    spi_data_in_s       <= 8'd0;
                    tb_transfer_done_s  <= 1'b0;
                    end
            end
            
        WAIT_FOR_RISING_st: begin
                if (sck_samples_s[1] == 0 && sck_samples_s[0] == 1) begin
                    spi_data_in_s[7:0]  <= {spi_data_in_s[6:0],tb_spi_mosi_p};
                    spi_state_s         <= WAIT_FOR_FALLING_st;
                    end
                else begin
                    spi_state_s         <= WAIT_FOR_RISING_st;
                end
            end
                
        WAIT_FOR_FALLING_st: begin  
                if (sck_samples_s[1] == 1 && sck_samples_s[0] == 0) begin
                    if (sck_counts_s == 8'd7) begin
                        sck_counts_s        <= 8'd0;
                        tb_spi_miso_s       <= 1'b1;
                        spi_state_s         <= DONE_st;
                        tb_transfer_done_s  <= 1'b1;
                        end
                    else begin
                        spi_data_s          <= {spi_data_s[6:0],1'b0};
                        tb_spi_miso_s       <= spi_data_s[7];
                        sck_counts_s        <= sck_counts_s + 1;
                        spi_state_s         <= WAIT_FOR_RISING_st;
                        end
                    end
                else begin
                    spi_state_s     <= WAIT_FOR_FALLING_st;
                end
            end
            
        DONE_st: begin
                if (tb_init_transfer_p == 1'b0) begin
                    tb_transfer_done_s  <= 1'b0;
                    spi_state_s         <= IDLE_st;
                    tb_spi_miso_s       <= 1'b1;
                    end
                else begin
                    spi_state_s         <= DONE_st;
                    tb_spi_miso_s       <= 1'b1;
                end
            end
        endcase
        
    end
                        
        
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2017 04:32:01 PM
// Design Name: 
// Module Name: TB_fifo_test
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


module TB_fifo_test(

    );
    
    reg                 clk210_p    = 1'b0;
    reg                 reset_p     = 1'b1;
    reg         [7:0]   data_in_s;
    
    reg         [7:0]   sd_write_fifo_din_p     = 8'd0;
    reg                 sd_write_fifo_wr_en_p   = 1'b0;
    wire        [7:0]   fifo_write_dout_s;
    reg         [7:0]   state_s = 8'd0;
    reg         [7:0]   count_s = 0;
    wire                fifo_write_empty_s;
    reg                 fifo_write_rd_en_s = 1'b0;
    reg                 wait_done_s = 1'b0;
    fifo_sd_card_write fifo_sd_card_write_inst
    (
        .clk                 (clk210_p),                        // INPUT  -  1 bit  - 210 MHz clock
        .rst                 (reset_p),                         // INPUT  -  1 bit  - reset
        .din                 (sd_write_fifo_din_p),             // INPUT  -  8 bits - data input bus to the fifo
        .wr_en               (sd_write_fifo_wr_en_p),           // INPUT  -  1 bit  - Write enable to the fifo
        .rd_en               (fifo_write_rd_en_s),              // INPUT  -  1 bit  - read enable to the fifo
        .dout                (fifo_write_dout_s),               // OUTPUT -  8 bits - data output bus from the fifo
        .full                (sd_write_fifo_full_p),            // OUTPUT -  1 bit  - Full flag from the FIFO
        // .almost_full         (fifo_write_almost_full_s),           // OUTPUT -  1 bit  - Almost full flag (triggers 1 byte before full)
        // .almost_empty        (fifo_write_almost_empty_s),          // OUTPUT -  1 bit  - Almost empty flag (triggers with only 1 byte in the fifo)
        .empty               (fifo_write_empty_s)               // OUTPUT -  1 bit  - Empty flag 
        // .data_count          (fifo_write_data_count_s)             // OUTPUT - 13 bits - Number of bytes in the fifo
        );
    
    always # 5 clk210_p <= ~clk210_p;
    
    initial
        begin
        
        #1000
        reset_p <= 1'b0;
        #100 
        wait_done_s <= 1'b1;
        end
        
     
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            state_s     <= 8'd10;
            end
        else begin
            case(state_s)
            10: begin
                if (wait_done_s)
                    state_s <= 0;
                else
                    state_s <= 10;
                end
            0: begin
                    if (count_s < 15) begin
                        sd_write_fifo_din_p <= sd_write_fifo_din_p + 1'b1;
                        state_s <= 1;
                        count_s <= count_s + 1;
                        end
                    else begin
                        state_s <= 3;
                        count_s <= 0;
                    end
                end
            1: begin
                    sd_write_fifo_wr_en_p <= 1'b1;
                    state_s <= 2;
                end
            2: begin
                    sd_write_fifo_wr_en_p <= 1'b0;
                    
                    state_s <= 0;
                end
            3: begin
                    if (count_s < 15) begin
                        fifo_write_rd_en_s  <= 1'b1;
                        state_s <= 4;
                        count_s <= count_s + 1;
                        end
                    else begin
                        state_s <= 5;
                        count_s <= 0;
                    end
                end
            4: begin
                    fifo_write_rd_en_s  <= 1'b0;
                    
                    state_s <= 11;
                    
                end
            11: begin
                data_in_s   <= fifo_write_dout_s;
                state_s     <= 3;
                end
            
            5: begin
                state_s <= 5;
                end
            endcase
            
        end
    end
    
    
    
    
    
    
    
    
    
    
    
endmodule

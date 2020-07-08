`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2017 02:18:10 PM
// Design Name: 
// Module Name: FC_intfc_SPI_Word_Transfer
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


module FC_intfc_SPI_Word_Transfer(
    clk210_p,
    reset_p,
    spi_mosi_p,
    spi_miso_p,
    spi_ss_p,
    spi_sck_p,
    spi_ltransfer_in_p,
    spi_ltransfer_out_p,
    spi_init_trans_p,
    spi_word_done_p
    );
    
    input               clk210_p;
    input               reset_p;
    input               spi_mosi_p;
    input               spi_ss_p;
    input               spi_sck_p;
    input               spi_ltransfer_out_p;
    input               spi_init_trans_p;                       // signal from higher module to initiate a transfer
    
    output              spi_miso_p;
    output              spi_ltransfer_in_p;
    output              spi_word_done_p;
    
    // variable declaration
    wire        [15:0]  spi_ltransfer_out_p;                    // SPI data that is to be transfered out. 
    wire        [15:0]  spi_ltransfer_in_p;                     // SPI data that is transfered in.
                                                                // "l" here indicates that these signals are
                                                                // used in the lower level module. "h" is used in
                                                                // the higher level module to indicate that they are
                                                                // used in the high level module
    wire                spi_word_done_p;                        // signal to indicate that a transfer has completed
    reg                 spi_word_done_s         = 1'b0;
    
    reg                 spi_miso_s              = 1'b0;         // MISO
    
    reg         [ 1:0]  spi_sck_samples_s       = 2'd0;         // SCK samples that are sampled in the 210 MHz clock
    reg         [15:0]  spi_ltransfer_out_s     = 16'd0;        // data that will be transfered out
    reg         [15:0]  spi_ltransfer_in_s      = 16'd0;        // data that will be transfered in 
    reg         [ 7:0]  spi_word_state_s        = 8'd0;         // current state of the state machine
    reg         [ 7:0]  spi_num_bit_transfers_s = 8'd0;         // number of bits transfered
    
    // output assignments
    assign  spi_miso_p          = spi_miso_s;
    assign  spi_ltransfer_in_p  = spi_ltransfer_in_s;
    assign  spi_word_done_p     = spi_word_done_s;
    
    // Parameters
    parameter   [7:0]   IDLE_st                 = 8'd0;
    parameter   [7:0]   SET_MISO_st             = 8'd1;    
    parameter   [7:0]   WAIT_FOR_RISING_SCK_st  = 8'd2;
    parameter   [7:0]   WAIT_FOR_FALLING_SCK_st = 8'd3;
    parameter   [7:0]   DONE_st                 = 8'd4;
    
    //-----------------------------------------------------------------------//
    // Clock recovery:
    // This block samples SCK and these samples will be used to determine these
    // the rising and falling edge of the clock
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1) begin
            spi_sck_samples_s       <= 16'd0;
            end
        else begin
            spi_sck_samples_s[0]    <= spi_sck_p;
            spi_sck_samples_s[1]    <= spi_sck_samples_s[0];
        end
    end
    
    //-----------------------------------------------------------------------//
    // Data Recovery:
    // This block implements a basic shift register that collects data from
    // the FC and sends it to the command decoder to decode the command.
    // Simulateously, it sends back relavant data.
    // SCK rising  edge --> MOSI data   (FROM FC) 
    // SCK falling edge --> MISO data   (  TO FC)
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1) begin
            spi_word_state_s                <= IDLE_st;
            spi_num_bit_transfers_s         <= 8'd0;
            end
        else begin
        
            if (spi_ss_p == 1'b0) begin
            
                case (spi_word_state_s)
                
                // Wait for the spi_init_trans_p to go high. Then, move to the 
                // state where SCK's rising edge is looked for.
                // This is an indication by the higher level module that a transaction 
                // is starting. This can be the first word transaction or be just 
                // any other word transaction.
                IDLE_st: begin
                        if (spi_init_trans_p == 1'b1) begin
                            spi_word_state_s        <= SET_MISO_st;
                            spi_ltransfer_out_s     <= spi_ltransfer_out_p;
                            spi_num_bit_transfers_s <= 8'd0;
                            end
                        else begin
                            spi_word_state_s        <= IDLE_st;
                            spi_num_bit_transfers_s <= 8'd0;
                        end
                    end
                
                // This is where the MISO is preset.
                SET_MISO_st: begin
                        spi_miso_s              <= spi_ltransfer_out_s[15];
                        spi_ltransfer_out_s     <= {spi_ltransfer_out_s[14:0], 1'b0};
                        spi_word_state_s        <= WAIT_FOR_RISING_SCK_st;
                    end
                
                // This is the state where the rising edge of SCK is looked for.
                // When the rising edge is detected, data is shifted in.
                WAIT_FOR_RISING_SCK_st: begin
                        if (spi_sck_samples_s[0] == 1 && spi_sck_samples_s[1] == 0) begin       // Rising edge of SCK
                            spi_ltransfer_in_s  <= {spi_ltransfer_in_s[14:0], spi_mosi_p};
                            spi_word_state_s    <= WAIT_FOR_FALLING_SCK_st;
                            end
                        else begin
                            spi_word_state_s    <= WAIT_FOR_RISING_SCK_st;
                        end
                    end
                
                // This is the state where the falling edge of SCK is looked for.
                // When the falling edge is detected, data is shifted out.
                WAIT_FOR_FALLING_SCK_st: begin
                        if (spi_sck_samples_s[0] == 0 && spi_sck_samples_s[1] == 1) begin       // Falling edge of SCK
                            spi_miso_s              <= spi_ltransfer_out_s[15];
                            spi_ltransfer_out_s     <= {spi_ltransfer_out_s[14:0], 1'b0};
                            if (spi_num_bit_transfers_s == 15) begin
                                spi_word_state_s        <= DONE_st;
                                spi_word_done_s         <= 1'b1;
                                spi_num_bit_transfers_s <= 8'd0;
                                end
                            else begin
                                spi_num_bit_transfers_s <= spi_num_bit_transfers_s + 1;
                                spi_word_state_s        <= WAIT_FOR_RISING_SCK_st;
                                end
                            end
                        else begin
                            spi_word_state_s        <= WAIT_FOR_FALLING_SCK_st;
                        end
                    end
                    
                // A word has been tranfered. Now, wait for the higher level module to acknowledge
                // that the transfer is done. Only after the scknowledgement, move to the IDLE_st.
                // An acknowledgment is basically pulling down spi_init_trans_s. This has to be 
                // done by the higher module.
                DONE_st: begin
                        if (spi_init_trans_p == 1'b0) begin
                            spi_word_done_s         <= 1'b0;
                            spi_word_state_s        <= IDLE_st;
                            end
                        else begin
                            spi_word_state_s        <= DONE_st;
                        end
                    end
                    
                default: begin
                        spi_word_state_s        <= IDLE_st;
                    end
                        
                endcase
                end
            else begin
                spi_word_state_s                <= IDLE_st;
                spi_num_bit_transfers_s         <= 8'd0;
                spi_word_done_s                 <= 1'b0;
            end
        end
    end
    
endmodule

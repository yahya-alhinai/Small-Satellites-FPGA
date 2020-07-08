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


module TB_BBB_SPI_Word_Transfer(
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
    output               spi_mosi_p;
    input               spi_ss_p;                               // controlled by higher module
    output               spi_sck_p;
    input               spi_ltransfer_out_p;                    // Datat through MOSI
    input               spi_init_trans_p;                       // signal from higher module to initiate a transfer
    
    input              spi_miso_p;
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
    
    reg                 spi_mosi_s              = 1'b0;         // MOSI
    
    reg         [15:0]  spi_ltransfer_out_s     = 16'd0;        // data that will be transfered out
    reg         [15:0]  spi_ltransfer_in_s      = 16'd0;        // data that will be transfered in 
    reg         [ 7:0]  spi_word_state_s        = 8'd0;         // current state of the state machine
    reg         [ 7:0]  spi_num_bit_transfers_s = 8'd0;         // number of bits transfered
    reg         [ 7:0]  spi_sck_counter_s       = 8'd0;
    reg                 spi_sck_s               = 1'b0;
    reg         [ 1:0]  spi_sck_samples_s       = 2'd0;
    reg                 spi_sck_en_s            = 1'b0;
    reg                 spi_ris_en              = 1'b0;
    reg                 spi_fall_en             = 1'b0;
    
    // output assignments
    assign  spi_mosi_p          = spi_mosi_s;
    assign  spi_ltransfer_in_p  = spi_ltransfer_in_s;
    assign  spi_word_done_p     = spi_word_done_s;
    assign  spi_sck_p           = spi_sck_s;
    
    // Parameters
    parameter   [7:0]   IDLE_st                 = 8'd0;
    parameter   [7:0]   SET_MOSI_st             = 8'd1;    
    parameter   [7:0]   WAIT_FOR_RISING_SCK_st  = 8'd2;
    parameter   [7:0]   WAIT_FOR_FALLING_SCK_st = 8'd3;
    parameter   [7:0]   DONE_st                 = 8'd4;
    
    //-----------------------------------------------------------------------//
    // Clock generator:)
    // This block samples SCK and these samples will be used to generate
    // spi clock. This will down speed from 210Mhz to 2.1Mhz
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p && spi_sck_en_s == 1'b1)
    begin
        spi_sck_counter_s = spi_sck_counter_s + 1;
        
        if(spi_sck_counter_s >= 8'd10) begin
            spi_sck_counter_s <= 8'd0;
            spi_sck_s         <= ~spi_sck_s;
        end
        
        if (reset_p == 1) begin
            spi_sck_samples_s       <= 16'd0;
            end
        else begin
            spi_sck_samples_s[0]    <= spi_sck_s;
            spi_sck_samples_s[1]    <= spi_sck_samples_s[0];
        end
    end
    
    //-----------------------------------------------------------------------//
    // Data :
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
            case (spi_word_state_s)
            
            // Wait for the spi_init_trans_p to go high. Then, move to the 
            // state where SCK's rising edge is looked for.
            // This is an indication by the higher level module that a transaction 
            // is starting. This can be the first word transaction or be just 
            // any other word transaction.
            IDLE_st: begin
                    if (spi_init_trans_p == 1'b1) begin
                        spi_word_state_s        <= SET_MOSI_st;
                        spi_ltransfer_out_s     <= spi_ltransfer_out_p;
                        spi_num_bit_transfers_s <= 8'd0;
                        spi_sck_en_s = 1'b1;
                        end
                    else begin
                        spi_word_state_s        <= IDLE_st;
                        spi_num_bit_transfers_s <= 8'd0;
                    end
                end
            
            SET_MOSI_st: begin
                    spi_mosi_s              <= spi_ltransfer_out_s[15];
                    spi_ltransfer_out_s     <= {spi_ltransfer_out_s[14:0], 1'b0};
                    spi_word_state_s        <= WAIT_FOR_RISING_SCK_st;
                end

            WAIT_FOR_RISING_SCK_st: begin
                if (spi_sck_samples_s[0] == 1 && spi_sck_samples_s[1] == 0) begin       // Rising edge of SCK
                    spi_ltransfer_in_s          <= {spi_ltransfer_in_s[14:0], spi_miso_p};
                    spi_num_bit_transfers_s     <= spi_num_bit_transfers_s + 1;
                    spi_word_state_s            <= WAIT_FOR_FALLING_SCK_st;
                end
                else begin
                    spi_word_state_s            <= WAIT_FOR_RISING_SCK_st;
                end
            end
            // This is the state where the rising edge of SCK is looked for.
            // When the rising edge is detected, data is shifted in.
            WAIT_FOR_FALLING_SCK_st: begin
                    if (spi_sck_samples_s[0] == 0 && spi_sck_samples_s[1] == 1) begin       // Falling edge of SCK
                        spi_mosi_s              <= spi_ltransfer_out_s[15];
                        spi_ltransfer_out_s     <= {spi_ltransfer_out_s[14:0], 1'b0};
                        if (spi_num_bit_transfers_s == 16) begin
                            spi_word_state_s    <= DONE_st;
                            spi_word_done_s         <= 1'b1;
                            spi_num_bit_transfers_s <= 8'd0;
                            spi_sck_en_s            <= 1'b0;
                            spi_sck_s               <= 1'b0;
                        end
                        else begin
                            spi_word_state_s    <= WAIT_FOR_RISING_SCK_st;
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
    end
    
endmodule

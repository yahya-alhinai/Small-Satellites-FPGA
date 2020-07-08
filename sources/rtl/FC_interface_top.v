`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2017 10:02:13 PM
// Design Name: 
// Module Name: FC_interface_top
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


module FC_interface_top(
    clk210_p,                   // INPUT  -  1 bit  - 105 MHz clock
    reset_p,                    // INPUT  -  1 bit  - reset
    fc_spi_mosi_p,              // INPUT  -  1 bit  - MOSI from the FC (FC is the master)
    fc_spi_miso_p,              // OUTPUT -  1 bit  - MISO to the FC (remember that the FC is the master
    fc_spi_ss_p,                // INPUT  -  1 bit  - FC slave select
    fc_spi_sck_p,               // INPUT  -  1 bit  - SCK from the FC
    memory_map_spi_rd_data_p,   // INPUT  - 16 bits - data from the memory map 
    memory_map_spi_wr_data_p,   // OUTPUT - 16 bits - data to the memory map
    memory_map_spi_wr_addr_p,   // OUTPUT - 16 bits - address to which data needs to be written to in the Memory Map    
    memory_map_spi_rd_addr_p,   // OUTPUT - 16 bits - address from which data needs to be obtained from
    memory_map_spi_wr_en_p,     // OUTPUT -  1 bit  - write enable to the memory map
    memory_map_spi_rd_en_p,     // OUTPUT -  1 bit  - read enable to the memory map
    fc_fifo_tx_din_p,           // INPUT  - 16 bits - FIFO write data
    fc_fifo_tx_wr_en_p,         // INPUT  -  1 bit  - FIFO write enable
    fc_fifo_tx_ready_p,         // OUTPUT -  1 bit  - indicates that the FC FIFO is full and ready
    fc_sd_read_cmd_p,           // OUTPUT -  1 bit  - indicates to the SD Card interface module that data can be read from the SD Card into the FC FIFO
    fc_sd_shutdown_cmd_p,
    sd_num_sectors_written_p,
    fc_fifo_num_transfers_p     // OUTPUT - 16 bits - fifo counter used for indication whether there is an slave select glitch
    );
    
    input               clk210_p;
    input               reset_p;
    input               fc_spi_mosi_p;
    input               memory_map_spi_rd_data_p;    
    input               fc_spi_ss_p;
    input               fc_spi_sck_p;
    input               fc_fifo_tx_din_p;
    input               fc_fifo_tx_wr_en_p;
    input               sd_num_sectors_written_p;
    
    output              fc_spi_miso_p;
    output              memory_map_spi_rd_addr_p;
    output              memory_map_spi_wr_addr_p;
    output              memory_map_spi_wr_data_p;
    output              memory_map_spi_wr_en_p;
    output              memory_map_spi_rd_en_p;
    output              fc_fifo_tx_ready_p;
    output              fc_sd_read_cmd_p;
    output              fc_sd_shutdown_cmd_p;
    output              fc_fifo_num_transfers_p;
    
    //-----------------------------------------------------------------------//
    // Variable Assignments
    //-----------------------------------------------------------------------//
    // SPI related
    wire                fc_spi_miso_p;
    wire                fc_spi_mosi_p;
    wire                fc_spi_sck_p;
    wire                fc_spi_ss_p;
    
    wire                fc_spi_mosi_glitchfree_p;
    wire                fc_spi_sck_glitchfree_p;
    wire                fc_spi_ss_glitchfree_p;
    
    reg                 fc_spi_mosi_s       = 1'b1;
    reg                 fc_spi_sck_s        = 1'b1;
    reg                 fc_spi_ss_s         = 1'b1;
    
    reg         [ 7:0]  glitch_counter_1    = 8'd0;   
    reg         [ 7:0]  glitch_counter_2    = 8'd0;   
    reg         [ 7:0]  glitch_counter_3    = 8'd0;   
    
    // memory map related
    wire        [15:0]  memory_map_spi_rd_addr_p;
    wire        [15:0]  memory_map_spi_wr_addr_p;
    wire        [15:0]  memory_map_spi_rd_data_p;
    wire        [15:0]  memory_map_spi_wr_data_p;
    wire                memory_map_spi_rd_en_p;
    wire                memory_map_spi_wr_en_p;
    
    // FIFO related
    wire        [15:0]  fc_fifo_tx_din_p;
    wire                fc_fifo_tx_wr_en_p;
    wire                fc_fifo_tx_rd_en_p;
    wire        [15:0]  fc_fifo_tx_dout_p;
    wire                fc_fifo_tx_full_p;
    wire                fc_fifo_tx_empty_p;
    wire        [15:0]  fc_fifo_num_transfers_p;
    
    reg         [15:0]  fc_fifo_tx_data_count_s     = 16'd0;
    wire        [15:0]  fc_fifo_tx_data_count_p;
    
    // SD Card related
    wire        [31:0]  sd_num_sectors_written_p;
    wire                fc_fifo_tx_ready_p;
    reg                 fc_fifo_tx_ready_s          = 1'b0;
    reg                 fc_sd_read_cmd_s            = 1'b0;
    wire                fc_sd_read_cmd_p;
    
    // general module related
    reg         [ 7:0]  fc_fifo_controller_state_s  = 8'd0;
    
    //-----------------------------------------------------------------------//
    // Output Assignments
    //-----------------------------------------------------------------------//
    assign              fc_fifo_tx_ready_p  = fc_fifo_tx_ready_s;
    assign              fc_sd_read_cmd_p    = fc_sd_read_cmd_s;
    
    //-----------------------------------------------------------------------//
    // Parameter Assignments
    // These parameters are for the FIFO controller state machine
    //-----------------------------------------------------------------------//
    parameter   [ 7:0]  WAIT_FOR_DATA_IN_SD_st          = 8'd0;
    parameter   [ 7:0]  WAIT_FOR_FC_FIFO_TO_FILL_UP_st  = 8'd1;
    parameter   [ 7:0]  WAIT_FOR_FC_TO_READ_FIFO_st     = 8'd2;
    
    //-----------------------------------------------------------------------//
    // assignments
    //-----------------------------------------------------------------------//
    assign      fc_spi_sck_glitchfree_p    = fc_spi_sck_s;
    assign      fc_spi_ss_glitchfree_p     = fc_spi_ss_s;
    assign      fc_spi_mosi_glitchfree_p   = fc_spi_mosi_s;
    
    //-----------------------------------------------------------------------//
    // Parameters - constants
    //-----------------------------------------------------------------------//
    parameter   [31:0]  SD_NUM_SECTORS_THRESHOLD_c      = 32'd10;           // This is used to determine when the FC FIFO
                                                                            // can be loaded with data from the SD Card.
                                                                            // This number is also dictated by the FC team as
                                                                            // they should be capable of reading all the data
                                                                            // from the FPGA's FC FIFO in one transaction.
    parameter   [15:0]  FC_FIFO_THRESHOLD_c             = 16'd1024;
    
    //-----------------------------------------------------------------------//
    // FC FIFO Declaration
    //-----------------------------------------------------------------------//
    fc_fifo_tx fc_fifo_tx_inst(
    .clk                    (clk210_p),                 // INPUT  -  1 bit  - 105 MHz clock
    .rst                    (reset_p),                  // INPUT  -  1 bit  - reset
    .din                    (fc_fifo_tx_din_p),         // INPUT  - 16 bits - data input bus to the fifo
    .wr_en                  (fc_fifo_tx_wr_en_p),       // INPUT  -  1 bit  - Write enable to the fifo
    .rd_en                  (fc_fifo_tx_rd_en_p),       // INPUT  -  1 bit  - read enable to the fifo
    .dout                   (fc_fifo_tx_dout_p),        // OUTPUT - 16 bits - data output bus from the fifo
    .full                   (fc_fifo_tx_full_p),        // OUTPUT -  1 bit  - Full flag from the FIFO
    .empty                  (fc_fifo_tx_empty_p)        // OUTPUT -  1 bit  - Empty flag 
    );
    
    //-----------------------------------------------------------------------//
    // FC Controller Module Declaration
    //-----------------------------------------------------------------------//
    FC_intfc_SPI_controller FC_intfc_SPI_controller_inst(
    .clk210_p                   (clk210_p),                     // INPUT  -  1 bit  - 105 MHz clock
    .reset_p                    (reset_p),                      // INPUT  -  1 bit  - reset
    .spi_mosi_p                 (fc_spi_mosi_glitchfree_p),     // INPUT  -  1 bit  - MOSI from the FC (FC is the master)
    .spi_miso_p                 (fc_spi_miso_p),                // OUTPUT -  1 bit  - MISO to the FC (remember that the FC is the master
    .spi_ss_p                   (fc_spi_ss_glitchfree_p),       // INPUT  -  1 bit  - FC slave select
    .spi_sck_p                  (fc_spi_sck_glitchfree_p),      // INPUT  -  1 bit  - SCK from the FC
    .memory_map_spi_rd_data_p   (memory_map_spi_rd_data_p),     // INPUT  - 16 bits - data from the memory map 
    .memory_map_spi_wr_data_p   (memory_map_spi_wr_data_p),     // OUTPUT - 16 bits - data to the memory map
    .memory_map_spi_wr_addr_p   (memory_map_spi_wr_addr_p),     // OUTPUT - 16 bits - address to which data needs to be written to in the Memory Map    
    .memory_map_spi_rd_addr_p   (memory_map_spi_rd_addr_p),     // OUTPUT - 16 bits - address from which data needs to be obtained from
    .memory_map_spi_wr_en_p     (memory_map_spi_wr_en_p),       // OUTPUT -  1 bit  - write enable to the memory map
    .memory_map_spi_rd_en_p     (memory_map_spi_rd_en_p),       // OUTPUT -  1 bit  - read enable to the memory map
    .fc_fifo_tx_ready_p         (fc_fifo_tx_ready_s),           // INPUT  -  1 bit  - indicates that the FC FIFO is full (at the limit that FC wants which is why the full flag is not used instead)
    .fc_fifo_tx_rd_en_p         (fc_fifo_tx_rd_en_p),           // OUTPUT -  1 bit  - read enable to the fifo
    .fc_fifo_tx_dout_p          (fc_fifo_tx_dout_p),            // INPUT  - 16 bits - data output bus from the fifo
    .fc_fifo_tx_empty_p         (fc_fifo_tx_empty_p),           // INPUT  -  1 bit  - empty flag from the fifo
    .fc_fifo_num_transfers_p    (fc_fifo_num_transfers_p),      // OUTPUT - 16 bits - data counter which indicates there is an slave select glitch
    .fc_sd_shutdown_cmd_p       (fc_sd_shutdown_cmd_p)          // OUTPUT -  1 bit  - sent to SD card intf when saving data to shut down
    );
    
    
    //-----------------------------------------------------------------------//
    // FC FIFO Data Count
    // This register maintains a count of the number of elements in the FIFO
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin  
            fc_fifo_tx_data_count_s       <= 10'd0;
            end
        else begin
            if (fc_fifo_tx_wr_en_p == 1'b1) begin
                fc_fifo_tx_data_count_s <= fc_fifo_tx_data_count_s + 1'b1;
                end
            else begin if (fc_fifo_tx_rd_en_p == 1'b1) begin
                fc_fifo_tx_data_count_s   <= fc_fifo_tx_data_count_s - 1'b1;
                end
            end
        end
    end
    
    //-----------------------------------------------------------------------//
    // Glitch reduction for MOSI
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            glitch_counter_1    <= 8'd0;
            end
        else begin
            if ((fc_spi_mosi_p == 1'b0)&&(glitch_counter_1 < 4)) begin
                glitch_counter_1    <= glitch_counter_1 + 1;
                end
            else if ((fc_spi_mosi_p == 1'b1)&&(glitch_counter_1 >0)) begin
                glitch_counter_1    <= glitch_counter_1 - 1;
            end
        end
    end
    
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            fc_spi_mosi_s   <= 1'b1;
            end
        else begin
            if (glitch_counter_1 == 8'd0) begin
                fc_spi_mosi_s   <= 1'b1;
                end
            else if (glitch_counter_1 == 8'd4) begin
                fc_spi_mosi_s   <= 1'b0;
            end
        end
    end
    
    //-----------------------------------------------------------------------//
    // Glitch reduction for SS
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            glitch_counter_2    <= 8'd0;
            end
        else begin
            if ((fc_spi_ss_p == 1'b0)&&(glitch_counter_2 < 5)) begin
                glitch_counter_2    <= glitch_counter_2 + 1;
                end
            else if ((fc_spi_ss_p == 1'b1)&&(glitch_counter_2 >0)) begin
                glitch_counter_2    <= glitch_counter_2 - 1;
            end
        end
    end
    
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            fc_spi_ss_s   <= 1'b1;
            end
        else begin
            if (glitch_counter_2 == 8'd0) begin
                fc_spi_ss_s   <= 1'b1;
                end
            else if (glitch_counter_2 == 8'd5) begin
                fc_spi_ss_s   <= 1'b0;
            end
        end
    end
    
    //-----------------------------------------------------------------------//
    // Glitch reduction for SCK
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            glitch_counter_3    <= 8'd0;
            end
        else begin
            if ((fc_spi_sck_p == 1'b0)&&(glitch_counter_3 < 4)) begin
                glitch_counter_3    <= glitch_counter_3 + 1;
                end
            else if ((fc_spi_sck_p == 1'b1)&&(glitch_counter_3 >0)) begin
                glitch_counter_3    <= glitch_counter_3 - 1;
            end
        end
    end
    
    always @(posedge clk210_p)
    begin
        if (reset_p == 1'b1) begin
            fc_spi_sck_s   <= 1'b1;
            end
        else begin
            if (glitch_counter_3 == 8'd0) begin
                fc_spi_sck_s   <= 1'b1;
                end
            else if (glitch_counter_3 == 8'd4) begin
                fc_spi_sck_s   <= 1'b0;
            end
        end
    end
    
    //-----------------------------------------------------------------------//
    // Logic that controls the Flight Computer's FIFO operation
    // The Flight Computer's FIFO keeps getting fed with data from the SD Card.
    // This is controlled by a signal called the FC_sd_read_cmd_s
    // Whenever, this signal is asserted ('1'), the SD Card interface gets data
    // from the SD Card and stores it into the FC interface's FIFO. 
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            fc_sd_read_cmd_s        <= 1'b0;
            fc_fifo_tx_ready_s         <= 1'b0;
            end
        else begin
            case (fc_fifo_controller_state_s)
            
            // wait for the data in the SD Card to fill up to a considerable amount. 
            WAIT_FOR_DATA_IN_SD_st: begin
                    if (sd_num_sectors_written_p > SD_NUM_SECTORS_THRESHOLD_c) begin
                        fc_sd_read_cmd_s            <= 1'b1;                                // initiate the transactions with the SD Card interface
                        fc_fifo_controller_state_s  <= WAIT_FOR_FC_FIFO_TO_FILL_UP_st;
                        end
                    else begin
                        fc_sd_read_cmd_s            <= 1'b0;
                        fc_fifo_controller_state_s  <= WAIT_FOR_DATA_IN_SD_st;
                    end
                end
            
            // Wait for the FC FIFO to fill up
            WAIT_FOR_FC_FIFO_TO_FILL_UP_st: begin
                    if (fc_fifo_tx_data_count_s > FC_FIFO_THRESHOLD_c) begin
                        fc_sd_read_cmd_s            <= 1'b0;
                        fc_fifo_tx_ready_s          <= 1'b1;
                        fc_fifo_controller_state_s  <= WAIT_FOR_FC_TO_READ_FIFO_st;
                        end
                    else begin
                        fc_sd_read_cmd_s            <= 1'b1;
                        fc_fifo_controller_state_s  <= WAIT_FOR_FC_FIFO_TO_FILL_UP_st;
                    end
                end
                
            // Wait for the FC to read out our FIFO.
            WAIT_FOR_FC_TO_READ_FIFO_st: begin
                    if (fc_fifo_tx_empty_p == 1'b1) begin
                        fc_fifo_tx_ready_s             <= 1'b0;
                        fc_fifo_controller_state_s  <= WAIT_FOR_DATA_IN_SD_st;
                        end
                    else begin
                        fc_sd_read_cmd_s            <= 1'b0;
                        fc_fifo_controller_state_s  <= WAIT_FOR_FC_TO_READ_FIFO_st;
                    end
                end
            
            default: begin
                    fc_sd_read_cmd_s            <= 1'b0;
                    fc_fifo_tx_ready_s             <= 1'b0;
                    fc_fifo_controller_state_s  <= WAIT_FOR_DATA_IN_SD_st;
                end
                
            endcase
        end
    end
    
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/11/2017 08:38:01 AM
// Design Name: 
// Module Name: memory_map
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

// `define DEBUGGING_MODE         // test FC stuff
`define NORMAL_MODE            // 

module memory_map(
    clk210_p,
    reset_p,
    
    memory_map_uart_adrs_p,
    memory_map_uart_rd_data_p,
    
    memory_map_spi_wr_addr_p,
    memory_map_spi_rd_addr_p,
    memory_map_spi_wr_data_p,
    memory_map_spi_wr_en_p,
    memory_map_spi_rd_en_p,
    memory_map_spi_rd_data_p,
    
    current_adc_1_data_p,
    fpga_die_temperature_p,
    timekeeper_time_p,
    adc_threshold_p,
    
    adc_sampling_mode_p,
    sd_spi_cntrl_status_p,
    fc_fifo_tx_ready_p,
    sd_sectors_written_p,
    fc_fifo_num_transfers_p,
    
    FPGA_FC_sync_reg_p,
    FC_GPS_start_time_p,
    FC_SD_card_shutdown_p,
    SD_card_shutdown_ready_p
    );
    
    input           clk210_p;
    input           reset_p;
    input           memory_map_uart_adrs_p;                     // data will be read or written to this address
    
    input           memory_map_spi_wr_data_p;
    input           memory_map_spi_wr_addr_p;
    input           memory_map_spi_rd_addr_p;
    input           memory_map_spi_wr_en_p;
    input           memory_map_spi_rd_en_p;
    
    input           current_adc_1_data_p;
    input           fpga_die_temperature_p;
    input           timekeeper_time_p;
    input           sd_spi_cntrl_status_p;
    input           fc_fifo_tx_ready_p;
    input           sd_sectors_written_p;
    input           fc_fifo_num_transfers_p;
    input           SD_card_shutdown_ready_p;
    
    output          memory_map_uart_rd_data_p;
    output          memory_map_spi_rd_data_p;
    output          adc_threshold_p;
    output          adc_sampling_mode_p;
    output          FPGA_FC_sync_reg_p;
    output          FC_GPS_start_time_p;
    output          FC_SD_card_shutdown_p;
    
    // port declarations
    wire    [15:0]  memory_map_uart_rd_data_p;
    wire    [15:0]  memory_map_uart_adrs_p;
    
    wire    [15:0]  memory_map_spi_wr_data_p;    
    wire    [15:0]  memory_map_spi_rd_data_p;  
    wire    [15:0]  memory_map_spi_wr_addr_p;  
    wire    [15:0]  memory_map_spi_rd_addr_p;  
    wire            memory_map_spi_wr_en_p;  
    wire            memory_map_spi_rd_en_p;  
    
    wire    [15:0]  current_adc_1_data_p;
    wire    [15:0]  fpga_die_temperature_p;    
    wire    [63:0]  timekeeper_time_p;
    wire    [15:0]  adc_threshold_p;
    wire    [15:0]  adc_sampling_mode_p;
    wire    [31:0]  sd_sectors_written_p;
    wire    [15:0]  fc_fifo_num_transfers_p;
    wire    [15:0]  FPGA_FC_sync_reg_p;
    wire    [15:0]  sd_spi_cntrl_status_p;
    wire    [63:0]  FC_GPS_start_time_p;
    wire            FC_SD_card_shutdown_p;
    wire    [ 1:0]  SD_card_shutdown_ready_p;
    
    parameter   [15:0]  DEFAULT_THRESHOLD_c     = 16'd2000;
    
    // variable declarations
    reg     [15:0]  memory_map_uart_rd_data_s   = 16'd0;
    reg     [ 7:0]  memory_map_state_s          = 8'd0;
    reg     [15:0]  memory_map_spi_rd_data_s    = 16'd0;
    
    //-----------------------------------------------------------------------//
    // SPI FPGA REGISTERS (all bits are active high)
    // FPGA_FC_sync_reg_s:  bits 15 to 3 -> reserved                  
    //                      bit 0        -> FC says that GPS is locked
    //                      bit 1        -> FC asks the FPGA to look for the next PPS 
    //                      bit 2        -> FC says that it has given us the start time
    // adc_sampling_mode_reg_s: 4 different modes (00, 01, 10, 11)
    //                      bits 15:14   -> ADC Channel 8
    //                      bits 13:11   -> ADC Channel 7
    //                      bits 11:10   -> ADC Channel 6
    //                      bits  9:8    -> ADC Channel 5
    //                      bits  7:6    -> ADC Channel 4
    //                      bits  5:4    -> ADC Channel 3
    //                      bits  3:2    -> ADC Channel 2
    //                      bits  1:0    -> ADC Channel 1
    // adc_threshold_reg_s: threshold from 0 to 32767
    // FPGA_reg_4_s       : bit 0        -> FC ask SD card controller to prepare shutdown
    //-----------------------------------------------------------------------//
    reg     [15:0]  FPGA_FC_sync_reg_s          = 16'h0000;     // Bit 0,1 and 2 are set by the FC 
    reg     [15:0]  adc_sampling_mode_reg_s     = 16'h0000;     // ADC sampling modes
    reg     [15:0]  adc_threshold_reg_s         = DEFAULT_THRESHOLD_c;     // This is the threshold that is set for the ADC channels    
    reg     [15:0]  FPGA_reg_4_s                = 16'h0000;
    reg     [15:0]  FPGA_reg_5_s                = 16'h0000;
    reg     [63:0]  FC_GPS_start_time_s         = 64'h0000;
    
    //-----------------------------------------------------------------------//
    // output assignments
    //-----------------------------------------------------------------------//
    assign  memory_map_uart_rd_data_p   = memory_map_uart_rd_data_s;
    assign  memory_map_spi_rd_data_p    = memory_map_spi_rd_data_s;
    assign  adc_threshold_p             = adc_threshold_reg_s;
    assign  adc_sampling_mode_p         = adc_sampling_mode_reg_s;
    assign  FPGA_FC_sync_reg_p          = FPGA_FC_sync_reg_s;
    assign  FC_GPS_start_time_p         = FC_GPS_start_time_s;
    assign  FC_SD_card_shutdown_p       = FPGA_reg_4_s[0];
    //-----------------------------------------------------------------------//
    // UART Memory map addressed
    //-----------------------------------------------------------------------//
    parameter   [15:0]  ADC_DATA_ADDR_c         = 16'h1;
    parameter   [15:0]  FPGA_TEMP_ADDR_c        = 16'h2;
    parameter   [15:0]  TIME_KEEPER_W1_ADDR_c   = 16'h3;
    parameter   [15:0]  TIME_KEEPER_W2_ADDR_c   = 16'h4;
    parameter   [15:0]  TIME_KEEPER_W3_ADDR_c   = 16'h5;
    parameter   [15:0]  TIME_KEEPER_W4_ADDR_c   = 16'h6;
    parameter   [15:0]  RNDM_RD_DATA_TST_ADDR_c = 16'h7;
    parameter   [15:0]  SD_CARD_STATUS_ADDR_c   = 16'h8;
    parameter   [15:0]  SD_CARD_SECTORS_COUNT_1_c = 16'd9;
    parameter   [15:0]  SD_CARD_SECTORS_COUNT_2_c = 16'd10;
    
    
    //-----------------------------------------------------------------------//
    // SPI FC Memory map addresses
    //-----------------------------------------------------------------------//
    parameter   [15:0]  FPGA_FC_SYNC_ADDR_c     = 16'h50;
    parameter   [15:0]  FPGA_data_addr_2_c      = 16'h51;
    parameter   [15:0]  FPGA_data_addr_3_c      = 16'h52;
    parameter   [15:0]  FPGA_data_addr_4_c      = 16'h53;
    parameter   [15:0]  FPGA_data_addr_5_c      = 16'h54;
    parameter   [15:0]  FC_SD_CARD_STATUS_ADDR_c= 16'h20;
    parameter   [15:0]  FIFO_COUNTER_ADDR_c     = 16'h11;
    parameter   [15:0]  FC_GPS_st_time_W1_ADDR_c= 16'h12;
    parameter   [15:0]  FC_GPS_st_time_W2_ADDR_c= 16'h13;
    parameter   [15:0]  FC_GPS_st_time_W3_ADDR_c= 16'h14;
    parameter   [15:0]  FC_GPS_st_time_W4_ADDR_c= 16'h15;
    //-----------------------------------------------------------------------//
    // UART MEMORY MAP: This map is a map to registers for the UART debugging
    // interface.
    //-----------------------------------------------------------------------//
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            memory_map_uart_rd_data_s        <= 16'd0;
            end
        else begin
            case(memory_map_uart_adrs_p)
            
            // Current ADC data
            ADC_DATA_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= current_adc_1_data_p;
                end
                
            // FPGA die temperature
            FPGA_TEMP_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= fpga_die_temperature_p;
                end
            
            // Current time M.S Word
            TIME_KEEPER_W1_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= timekeeper_time_p[63:48];
                end
                
            // Current time [47:32]    
            TIME_KEEPER_W2_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= timekeeper_time_p[47:32];
                end
                
            // Current time [31:16]
            TIME_KEEPER_W3_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= timekeeper_time_p[31:16];
                end
            
            // Current time L.S Word
            TIME_KEEPER_W4_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= timekeeper_time_p[15:0];
                end
            
            // SD Card Status
            SD_CARD_STATUS_ADDR_c: begin
                    memory_map_uart_rd_data_s   <= {13'd0,SD_card_shutdown_ready_p,1'd0,fc_fifo_tx_ready_p};
                end
            
            SD_CARD_SECTORS_COUNT_1_c: begin
                    memory_map_uart_rd_data_s   <= sd_sectors_written_p[31:16];
                end
            
            SD_CARD_SECTORS_COUNT_2_c: begin
                    memory_map_uart_rd_data_s   <= sd_sectors_written_p[15:0];
                end
            
            default:
                memory_map_uart_rd_data_s       <= 16'h1234;
            endcase;
        end
    end
    
    
    // Reading registers via SPI
    always @(posedge clk210_p)
    begin
        if (reset_p) begin
            memory_map_spi_rd_data_s    <= 16'd0;
            end
        else begin
            if (memory_map_spi_rd_en_p == 1'b1) begin
                case(memory_map_spi_rd_addr_p)
                
                // Current ADC data
                ADC_DATA_ADDR_c: begin
                        memory_map_spi_rd_data_s    <= current_adc_1_data_p;
                    end                            
                                                   
                // FPGA die temperature            
                FPGA_TEMP_ADDR_c: begin            
                        memory_map_spi_rd_data_s    <= fpga_die_temperature_p;
                    end                            
                                                   
                // Current time M.S Word           
                TIME_KEEPER_W1_ADDR_c: begin       
                        memory_map_spi_rd_data_s    <= timekeeper_time_p[63:48];
                    end                            
                                                   
                // Current time [47:32]            
                TIME_KEEPER_W2_ADDR_c: begin       
                        memory_map_spi_rd_data_s    <= timekeeper_time_p[47:32];
                    end                            
                                                   
                // Current time [31:16]            
                TIME_KEEPER_W3_ADDR_c: begin       
                        memory_map_spi_rd_data_s    <= timekeeper_time_p[31:16];
                    end                            
                                                   
                // Current time L.S Word           
                TIME_KEEPER_W4_ADDR_c: begin       
                        memory_map_spi_rd_data_s    <= timekeeper_time_p[15:0];
                    end
                
                FPGA_FC_SYNC_ADDR_c: begin
                        memory_map_spi_rd_data_s    <= FPGA_FC_sync_reg_p;
                    end
                    
                FPGA_data_addr_2_c: begin
                        memory_map_spi_rd_data_s    <= adc_sampling_mode_reg_s;
                    end
                    
                FPGA_data_addr_3_c: begin
                        memory_map_spi_rd_data_s    <= adc_threshold_reg_s;
                    end

                FC_SD_CARD_STATUS_ADDR_c: begin
                        `ifdef NORMAL_MODE
                        memory_map_spi_rd_data_s    <= {13'd0,SD_card_shutdown_ready_p,1'd0,fc_fifo_tx_ready_p};
                        `endif
                        `ifdef DEBUGGING_MODE
                            memory_map_spi_rd_data_s    <= {13'd0,1'd1,1'd0,1'd1};
                        `endif
                    end
                    
                FPGA_data_addr_5_c: begin
                        memory_map_spi_rd_data_s    <= FPGA_reg_5_s;
                    end
                
                //fifo counter for slave select glitch check
                FIFO_COUNTER_ADDR_c: begin
                        memory_map_spi_rd_data_s    <= fc_fifo_num_transfers_p[15:0];
                    end
                
                default: begin
                        memory_map_spi_rd_data_s    <= 16'd123;
                    end
                    
                endcase
                end
            else begin
                memory_map_spi_rd_data_s            <= 16'd244;
            end
        end
    end             
    
    // Writing registers via SPI
    always @(posedge clk210_p)
    begin
        if(reset_p == 1'b1) begin
            FPGA_FC_sync_reg_s          <= 16'd0;
            adc_sampling_mode_reg_s     <= 16'd0;
            adc_threshold_reg_s         <= DEFAULT_THRESHOLD_c;
            FPGA_reg_4_s                <= 16'd0;
            FPGA_reg_5_s                <= 16'd0;
            FC_GPS_start_time_s         <= 64'h0000;
            end
        else  begin
            if (memory_map_spi_wr_en_p == 1'b1) begin
                case(memory_map_spi_wr_addr_p)
                FPGA_FC_SYNC_ADDR_c: begin
                        FPGA_FC_sync_reg_s      <= memory_map_spi_wr_data_p;
                    end
                    
                FPGA_data_addr_2_c: begin
                        adc_sampling_mode_reg_s <= memory_map_spi_wr_data_p;
                    end
                    
                FPGA_data_addr_3_c: begin
                        adc_threshold_reg_s     <= memory_map_spi_wr_data_p;
                    end
                    
                FPGA_data_addr_4_c: begin
                        FPGA_reg_4_s            <= memory_map_spi_wr_data_p;
                    end
                    
                FPGA_data_addr_5_c: begin
                        FPGA_reg_5_s            <= memory_map_spi_wr_data_p;
                    end
                
                // Start time M.S Word
                FC_GPS_st_time_W1_ADDR_c: begin
                        FC_GPS_start_time_s[63:48] <= memory_map_spi_wr_data_p;
                    end
                
                // Start time [47:32]
                FC_GPS_st_time_W2_ADDR_c: begin
                        FC_GPS_start_time_s[47:32] <= memory_map_spi_wr_data_p;
                    end
                
                // Start time [31:16]
                FC_GPS_st_time_W3_ADDR_c: begin
                        FC_GPS_start_time_s[31:16] <= memory_map_spi_wr_data_p;
                    end
                
                // Start time L.S Word
                FC_GPS_st_time_W4_ADDR_c: begin
                        FC_GPS_start_time_s[15:0 ] <= memory_map_spi_wr_data_p;
                    end
                    
                default:
                    FPGA_FC_sync_reg_s    <= FPGA_FC_sync_reg_s;
                endcase
                end
            else begin
                FPGA_FC_sync_reg_s    <= FPGA_FC_sync_reg_s;
            end
        end
    end
    
endmodule

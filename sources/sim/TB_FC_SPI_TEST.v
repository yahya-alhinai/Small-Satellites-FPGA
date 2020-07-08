`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2017 04:28:17 PM
// Design Name: 
// Module Name: TB_FC_SPI_TEST
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


module TB_FC_SPI_TEST(
    );

    reg             clk210_s  = 1'b0;
    reg             reset_s   = 1'b0;
    reg             spi_initial_s = 1'b0;
    reg     [15:0]  spi_wr_data_s = 16'b0;
    reg     [15:0]  spi_wr_addr_s = 16'b0;
    reg     [15:0]  spi_rd_addr_s = 16'b0;
    reg     [15:0]  spi_command_s = 16'b0;
    reg     [ 3:0]  counter       = 16'b0;
    reg     [15:0]  spi_test_ad_s [0:15] = {16'h1,16'h2,16'h3,16'h4,16'h5,16'h6,16'h50,16'h51,16'h52,16'h20,16'h54,16'h30,0,0,0,0};
    reg     [15:0]  spi_test_da_s [0:15];
    wire    [ 7:0]  spi_state_p;

    wire            spi_miso_p;
    wire            spi_mosi_p;
    wire            spi_sck_p;
    wire            spi_ss_p;
    wire    [15:0]  spi_rd_data_p;
    
    wire            sd_spi_sck_p;
    wire            sd_spi_mosi_p;
    wire            sd_spi_miso_p;
    wire            sd_spi_ss_p;
    
    wire            uart_tx_p;
    wire            uart_rx_p;
    
    wire            adc_1_cnv_p;
    wire            adc_1_sck_p;
    wire            adc_1_sdo_p;
     
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
       
    BBB_SPI_model BBB_spi_module(
        .clk210_p                   (clk210_s),
        .reset_p                    (reset_s),
        .spi_mosi_p                 (spi_mosi_p),
        .spi_miso_p                 (spi_miso_p),
        .spi_ss_p                   (spi_ss_p),
        .spi_sck_p                  (spi_sck_p),
        .spi_state_s                (spi_state_p),
        .spi_rd_data_s              (spi_rd_data_p),            // OUTPUT - 16 bits - data from the memory map 
        .spi_wr_data_p              (spi_wr_data_s),            // INPUT  - 16 bits - data to the memory map
        .spi_wr_addr_p              (spi_wr_addr_s),            // INPUT  - 16 bits - address to which data needs to be written to in the Memory Map    
        .spi_rd_addr_p              (spi_rd_addr_s),            // INPUT  - 16 bits - address from which data needs to be obtained from
        .spi_initial                (spi_initial_s),            // INPUT  -  1 bit  - TB control
        .spi_command_p              (spi_command_s)
    );
    
    FPGA_TOP FPGA_top_module(
        .clk12_in_p                 (clk210_s),                 // INPUT  -  1 bit  - 12 MHz clock input
        .reset_p                    (reset_s),
        .uart_tx_p                  (uart_tx_p),
        .uart_rx_p                  (uart_rx_p),
        .adc_1_cnv_p                (adc_1_cnv_p),
        .adc_1_sck_p                (adc_1_sck_p),
        .adc_1_sdo_p                (adc_1_sdo_p),
        .sd_spi_miso_p              (sd_spi_miso_p),
        .sd_spi_sck_p               (sd_spi_sck_p),
        .sd_spi_mosi_p              (sd_spi_mosi_p),
        .sd_spi_ss_p                (sd_spi_ss_p),
        .sd_spi_init_done_p         (sd_spi_init_done_p),
        .sd_card_ccs_bit_p          (sd_card_ccs_bit_p),
        .sd_spi_transfer_done_p     (sd_spi_transfer_done_p),
        .fc_spi_mosi_p              (spi_mosi_p),
        .fc_spi_miso_p              (spi_miso_p),
        .fc_spi_sck_p               (spi_sck_p),
        .fc_spi_ss_p                (spi_ss_p)
    );
    
    TB_SD_Card_Spi_Slave SD_test(
        .clk_p                      (clk210_s),
        .tb_spi_miso_p              (sd_spi_miso_p),
        .tb_spi_mosi_p              (sd_spi_mosi_p),
        .tb_spi_sck_p               (sd_spi_sck_p),
        .tb_spi_ss_p                (sd_spi_ss_p)
    );
    
    //read and write register test.
    always # 2.3809523 clk210_s <= ~clk210_s;
    initial
    begin
    reset_s            <= 1'b1;
    #10
    reset_s            <= 1'b0;
    #5000
    
    //case 1: reading register test, it will display each register value
    //case 2: writing register test, it will write value and check the register
    //case 3: SD card reading  test, it will start to read SD card
    
    case(2)
    
    //reading register
    1: begin
        $display("reading register test");
        while(counter <= 4'd11) begin
            #10
            spi_initial_s      <= 1'b1;
            spi_command_s      <= 16'd3;
            spi_wr_addr_s      <= 16'd0;
            spi_rd_addr_s      <= spi_test_ad_s [counter];
            #10
            spi_initial_s      <= 1'b0;
            #8000
            spi_test_da_s[counter] <= spi_rd_data_p;
            counter <= counter + 1;
            end
        #10
        counter <= 4'b0;
        #10
        while(counter <= 4'd11) begin
            #10
            $display("The register address is %h",spi_test_ad_s [counter]);
            $display("The register   value is %h",spi_test_da_s [counter]);
            counter <= counter+1;
            end
        end
    
    //Writing register test
    2:begin
        $display("writing register test");
        #10
        counter <= 4'd0;
        #10
        //write 16'h11 into register
        while(counter <= 4'd4) begin
            #10
            spi_initial_s      <= 1'b1;
            spi_command_s      <= 16'd2;
            spi_wr_addr_s      <= 16'h50+counter;
            spi_wr_data_s      <= 16'h11;
            #10
            spi_initial_s      <= 1'b0;
            #10000
            counter <= counter + 1;
            end
        #10
        counter <= 4'h6;
        #10
        //read register values
        while(counter <= 4'd10) begin
            #10
            spi_initial_s      <= 1'b1;
            spi_command_s      <= 16'd3;
            spi_wr_addr_s      <= 16'd0;
            spi_rd_addr_s      <= spi_test_ad_s [counter];
            #10
            spi_initial_s      <= 1'b0;
            #8000
            spi_test_da_s[counter] <= spi_rd_data_p;
            counter <= counter + 1;
            end
        #10
        counter <= 4'h6;
        #10
        //display
        while(counter <= 4'd10) begin
            if(spi_test_da_s[counter] == 16'h11) begin
            $display("Writing at the register address %h is successful",spi_test_ad_s [counter]);
            end
            else begin
            $display("Writing at the register address %h is fail",spi_test_ad_s [counter]);
            end
            #10
            if(counter == 4'd8) counter <= counter + 2;
            else                counter <= counter + 1;
            end
        end
   
   3: begin
        //SD CARD read test
        $display("SDcard reading test");
        spi_initial_s      <= 1'b1;
        spi_command_s      <= 16'd5;
        #10
        spi_initial_s      <= 1'b0;
        end
   endcase
   end
endmodule

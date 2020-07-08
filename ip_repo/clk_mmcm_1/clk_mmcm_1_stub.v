// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.1 (win64) Build 1538259 Fri Apr  8 15:45:27 MDT 2016
// Date        : Thu Nov 30 18:39:38 2017
// Host        : DESKTOP-U392PMO running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               E:/HASP/Code/Current_Code/Full_Implementation/FPGA-Code-CMOD-A7/ip_repo/clk_mmcm_1/clk_mmcm_1_stub.v
// Design      : clk_mmcm_1
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_mmcm_1(clk_in1, clk_out1, reset, locked)
/* synthesis syn_black_box black_box_pad_pin="clk_in1,clk_out1,reset,locked" */;
  input clk_in1;
  output clk_out1;
  input reset;
  output locked;
endmodule

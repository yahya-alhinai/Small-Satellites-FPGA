// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.1 (win64) Build 1538259 Fri Apr  8 15:45:27 MDT 2016
// Date        : Wed Nov 29 10:09:14 2017
// Host        : DESKTOP-MIMHT10 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/UMN/Cubesat/New_test/FPGA-Code-CMOD-A7/ip_repo/fifo_preprocessing/fifo_preprocessing_stub.v
// Design      : fifo_preprocessing
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_1_0,Vivado 2016.1" *)
module fifo_preprocessing(clk, rst, din, wr_en, rd_en, dout, full, empty, prog_empty)
/* synthesis syn_black_box black_box_pad_pin="clk,rst,din[79:0],wr_en,rd_en,dout[79:0],full,empty,prog_empty" */;
  input clk;
  input rst;
  input [79:0]din;
  input wr_en;
  input rd_en;
  output [79:0]dout;
  output full;
  output empty;
  output prog_empty;
endmodule

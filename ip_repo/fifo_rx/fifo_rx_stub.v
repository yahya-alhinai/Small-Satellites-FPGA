// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.1 (win64) Build 1538259 Fri Apr  8 15:45:27 MDT 2016
// Date        : Sun Aug 27 15:17:51 2017
// Host        : DESKTOP-U392PMO running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub E:/HASP/Code/FPGA-Code-CMOD-A7/ip_repo/fifo_rx/fifo_rx_stub.v
// Design      : fifo_rx
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_1_0,Vivado 2016.1" *)
module fifo_rx(clk, rst, din, wr_en, rd_en, dout, full, almost_full, empty, almost_empty, data_count)
/* synthesis syn_black_box black_box_pad_pin="clk,rst,din[7:0],wr_en,rd_en,dout[7:0],full,almost_full,empty,almost_empty,data_count[4:0]" */;
  input clk;
  input rst;
  input [7:0]din;
  input wr_en;
  input rd_en;
  output [7:0]dout;
  output full;
  output almost_full;
  output empty;
  output almost_empty;
  output [4:0]data_count;
endmodule

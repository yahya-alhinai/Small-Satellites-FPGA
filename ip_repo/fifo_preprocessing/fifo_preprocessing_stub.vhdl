-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.1 (win64) Build 1538259 Fri Apr  8 15:45:27 MDT 2016
-- Date        : Wed Nov 29 10:09:14 2017
-- Host        : DESKTOP-MIMHT10 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               D:/UMN/Cubesat/New_test/FPGA-Code-CMOD-A7/ip_repo/fifo_preprocessing/fifo_preprocessing_stub.vhdl
-- Design      : fifo_preprocessing
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcpg236-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_preprocessing is
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 79 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 79 downto 0 );
    full : out STD_LOGIC;
    empty : out STD_LOGIC;
    prog_empty : out STD_LOGIC
  );

end fifo_preprocessing;

architecture stub of fifo_preprocessing is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,rst,din[79:0],wr_en,rd_en,dout[79:0],full,empty,prog_empty";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v13_1_0,Vivado 2016.1";
begin
end;

-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.1 (win64) Build 1538259 Fri Apr  8 15:45:27 MDT 2016
-- Date        : Mon Dec 04 11:54:57 2017
-- Host        : DESKTOP-U392PMO running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               E:/HASP/Code/Current_Code/Full_Implementation/FPGA-Code-CMOD-A7/ip_repo/fifo_processing/fifo_processing_stub.vhdl
-- Design      : fifo_processing
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcpg236-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_processing is
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 107 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 107 downto 0 );
    full : out STD_LOGIC;
    empty : out STD_LOGIC
  );

end fifo_processing;

architecture stub of fifo_processing is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,rst,din[107:0],wr_en,rd_en,dout[107:0],full,empty";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v13_1_0,Vivado 2016.1";
begin
end;

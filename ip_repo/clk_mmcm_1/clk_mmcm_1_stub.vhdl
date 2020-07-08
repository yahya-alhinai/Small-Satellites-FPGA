-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.1 (win64) Build 1538259 Fri Apr  8 15:45:27 MDT 2016
-- Date        : Thu Nov 30 18:39:38 2017
-- Host        : DESKTOP-U392PMO running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               E:/HASP/Code/Current_Code/Full_Implementation/FPGA-Code-CMOD-A7/ip_repo/clk_mmcm_1/clk_mmcm_1_stub.vhdl
-- Design      : clk_mmcm_1
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcpg236-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_mmcm_1 is
  Port ( 
    clk_in1 : in STD_LOGIC;
    clk_out1 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC
  );

end clk_mmcm_1;

architecture stub of clk_mmcm_1 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_in1,clk_out1,reset,locked";
begin
end;

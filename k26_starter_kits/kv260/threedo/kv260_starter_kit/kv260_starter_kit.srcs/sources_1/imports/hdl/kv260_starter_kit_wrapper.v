//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Thu Mar 30 19:25:41 2023
//Host        : roman-HP-ZBook-Firefly-14-inch-G8-Mobile-Workstation-PC running 64-bit Ubuntu 22.04.1 LTS
//Command     : generate_target kv260_starter_kit_wrapper.bd
//Design      : kv260_starter_kit_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module kv260_starter_kit_wrapper
   (fan_en_b);
  output [0:0]fan_en_b;

  wire [0:0]fan_en_b;

  kv260_starter_kit kv260_starter_kit_i
       (.fan_en_b(fan_en_b));
endmodule

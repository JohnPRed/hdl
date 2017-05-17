// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// Each core or library found in this collection may have its own licensing terms. 
// The user should keep this in in mind while exploring these cores. 
//
// Redistribution and use in source and binary forms,
// with or without modification of this file, are permitted under the terms of either
//  (at the option of the user):
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory, or at:
// https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
//
// OR
//
//   2.  An ADI specific BSD license as noted in the top level directory, or on-line at:
// https://github.com/analogdevicesinc/hdl/blob/dev/LICENSE
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_dac_jesd204_if #(
  parameter DEVICE_TYPE = 0, // altera (0x1) or xilinx (0x0)
  parameter NUM_LANES = 8,
  parameter NUM_CHANNELS = 4
) (
  // jesd interface
  // tx_clk is (line-rate/40)

  input                       tx_clk,
  output [NUM_LANES*32-1:0]   tx_data,

  // dac interface

  input                       dac_rst,
  input   [NUM_LANES*32-1:0]  dac_data
);

  localparam DATA_PATH_WIDTH = 2 * NUM_LANES / NUM_CHANNELS;
  localparam H = NUM_LANES / NUM_CHANNELS / 2;
  localparam HD = NUM_LANES > NUM_CHANNELS ? 1 : 0;
  localparam OCT_OFFSET = HD ? 32 : 8;

  // internal registers

  reg    [NUM_LANES*32-1:0]  tx_data_r = 'd0;
  wire   [NUM_LANES*32-1:0]  tx_data_s;

  always @(posedge tx_clk) begin
    if (dac_rst == 1'b1) begin
      tx_data_r <= 'h00;
    end else begin
      tx_data_r <= tx_data_s;
    end
  end

  generate
  genvar lsb;
  genvar i, j;
  if (DEVICE_TYPE == 1) begin
    for (lsb = 0; lsb < NUM_LANES*32; lsb = lsb + 32) begin: g_swizzle
       assign tx_data[lsb+31:lsb] = {
         tx_data_r[lsb+7:lsb],
         tx_data_r[lsb+15:lsb+8],
         tx_data_r[lsb+23:lsb+16],
         tx_data_r[lsb+31:lsb+24]
       };
    end
  end else begin
    assign tx_data = tx_data_r;
  end

  for (i = 0; i < NUM_CHANNELS; i = i + 1) begin: g_framer_outer
    for (j = 0; j < DATA_PATH_WIDTH; j = j + 1) begin: g_framer_inner
      localparam k = j + i * DATA_PATH_WIDTH;
      localparam dac_lsb = k * 16;
      localparam oct0_lsb = HD ? ((i * H + j % H) * 64 + (j / H) * 8) : (k * 16);
      localparam oct0_msb = oct0_lsb + 7;
      localparam oct1_lsb = oct0_lsb + OCT_OFFSET;
      localparam oct1_msb = oct0_msb + OCT_OFFSET;

      assign tx_data_s[oct0_msb:oct0_lsb] = dac_data[dac_lsb+15:dac_lsb+8];
      assign tx_data_s[oct1_msb:oct1_lsb] = dac_data[dac_lsb+7:dac_lsb];
    end
  end
  endgenerate

endmodule

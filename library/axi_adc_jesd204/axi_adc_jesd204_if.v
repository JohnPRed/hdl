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

module axi_adc_jesd204_if #(
  parameter DEVICE_TYPE = 0,
  parameter NUM_LANES = 1,
  parameter NUM_CHANNELS = 1,
  parameter CHANNEL_WIDTH = 16
) (
  // jesd interface
  // rx_clk is (line-rate/40)

  input                                       rx_clk,
  input       [3:0]                           rx_sof,
  input       [NUM_LANES*32-1:0]              rx_data,

  // adc data output

  output     [NUM_LANES*CHANNEL_WIDTH*2-1:0]  adc_data
);

  localparam TAIL_BITS = 16 - CHANNEL_WIDTH;
  localparam DATA_PATH_WIDTH = 2 * NUM_LANES / NUM_CHANNELS;
  localparam H = NUM_LANES / NUM_CHANNELS / 2;
  localparam HD = NUM_LANES > NUM_CHANNELS ? 1 : 0;
  localparam OCT_OFFSET = HD ? 32 : 8;

  wire [NUM_LANES*32-1:0] rx_data_s;

  // data multiplex

  generate
  genvar i;
  genvar j;
  for (i = 0; i < NUM_CHANNELS; i = i + 1) begin: g_deframer_outer
    for (j = 0; j < DATA_PATH_WIDTH; j = j + 1) begin: g_deframer_inner
      localparam k = j + i * DATA_PATH_WIDTH;
      localparam adc_lsb = k * CHANNEL_WIDTH;
      localparam adc_msb = adc_lsb + CHANNEL_WIDTH - 1;
      localparam oct0_lsb = HD ? ((i * H + j % H) * 64 + (j / H) * 8) : (k * 16);
      localparam oct0_msb = oct0_lsb + 7;
      localparam oct1_lsb = oct0_lsb + OCT_OFFSET + TAIL_BITS;
      localparam oct1_msb = oct0_msb + OCT_OFFSET;

      assign adc_data[adc_msb:adc_lsb] = {rx_data_s[oct0_msb:oct0_lsb],rx_data_s[oct1_msb:oct1_lsb]};
    end
  end
  endgenerate

  // frame-alignment

  generate
  genvar n;
  for (n = 0; n < NUM_LANES; n = n + 1) begin: g_xcvr_if
    ad_xcvr_rx_if #(
      .DEVICE_TYPE (DEVICE_TYPE)
    ) i_xcvr_if (
      .rx_clk (rx_clk),
      .rx_ip_sof (rx_sof),
      .rx_ip_data (rx_data[((n*32)+31):(n*32)]),
      .rx_sof (),
      .rx_data (rx_data_s[((n*32)+31):(n*32)])
    );
  end
  endgenerate

endmodule

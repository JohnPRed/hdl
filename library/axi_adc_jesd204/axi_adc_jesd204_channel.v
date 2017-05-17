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

module axi_adc_jesd204_channel #(
  parameter CHANNEL_ID = 0,
  parameter CHANNEL_WIDTH = 14,
  parameter DATA_PATH_WIDTH = 2,
  parameter TWOS_COMPLEMENT = 1
) (
  // adc interface

  input                                           adc_clk,
  input                                           adc_rst,
  input      [CHANNEL_WIDTH*DATA_PATH_WIDTH-1:0]  adc_data,

  // channel interface

  output     [16*DATA_PATH_WIDTH-1:0]             adc_dfmt_data,
  output                                          adc_enable,
  output                                          up_adc_pn_err,
  output                                          up_adc_pn_oos,

  // processor interface

  input                                           up_rstn,
  input                                           up_clk,
  input                                           up_wreq,
  input      [13:0]                               up_waddr,
  input      [31:0]                               up_wdata,
  output                                          up_wack,
  input                                           up_rreq,
  input      [13:0]                               up_raddr,
  output     [31:0]                               up_rdata,
  output                                          up_rack
);

  // internal signals

  wire            adc_pn_oos_s;
  wire            adc_pn_err_s;
  wire            adc_dfmt_enable_s;
  wire            adc_dfmt_type_s;
  wire            adc_dfmt_se_s;
  wire    [ 3:0]  adc_pnseq_sel_s;

  // instantiations

  axi_adc_jesd204_pnmon #(
    .CHANNEL_WIDTH(CHANNEL_WIDTH),
    .DATA_PATH_WIDTH(DATA_PATH_WIDTH),
    .TWOS_COMPLEMENT(TWOS_COMPLEMENT)
  ) i_pnmon (
    .adc_clk (adc_clk),
    .adc_data (adc_data),
    .adc_pn_oos (adc_pn_oos_s),
    .adc_pn_err (adc_pn_err_s),
    .adc_pnseq_sel (adc_pnseq_sel_s));

  generate
  genvar n;
  for (n = 0; n < DATA_PATH_WIDTH; n = n + 1) begin: g_ad_datafmt_1
    ad_datafmt #(
      .DATA_WIDTH(CHANNEL_WIDTH)
    ) i_ad_datafmt (
      .clk (adc_clk),
      .valid (1'b1),
      .data (adc_data[(n+1)*CHANNEL_WIDTH-1:n*CHANNEL_WIDTH]),
      .valid_out (),
      .data_out (adc_dfmt_data[n*16+15:n*16]),
      .dfmt_enable (adc_dfmt_enable_s),
      .dfmt_type (adc_dfmt_type_s),
      .dfmt_se (adc_dfmt_se_s)
    );
  end
  endgenerate

  up_adc_channel #(
    .CHANNEL_ID(CHANNEL_ID)
  ) i_up_adc_channel (
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_enable (adc_enable),
    .adc_iqcor_enb (),
    .adc_dcfilt_enb (),
    .adc_dfmt_se (adc_dfmt_se_s),
    .adc_dfmt_type (adc_dfmt_type_s),
    .adc_dfmt_enable (adc_dfmt_enable_s),
    .adc_dcfilt_offset (),
    .adc_dcfilt_coeff (),
    .adc_iqcor_coeff_1 (),
    .adc_iqcor_coeff_2 (),
    .adc_pnseq_sel (adc_pnseq_sel_s),
    .adc_data_sel (),
    .adc_pn_err (adc_pn_err_s),
    .adc_pn_oos (adc_pn_oos_s),
    .adc_or (1'b0),
    .adc_usr_datatype_be (1'b0),
    .adc_usr_datatype_signed (1'b1),
    .adc_usr_datatype_shift (8'd0),
    .adc_usr_datatype_total_bits (8'd16),
    .adc_usr_datatype_bits (8'd16),
    .adc_usr_decimation_m (16'd1),
    .adc_usr_decimation_n (16'd1),

    .up_adc_pn_err (up_adc_pn_err),
    .up_adc_pn_oos (up_adc_pn_oos),
    .up_adc_or (),
    .up_usr_datatype_be (),
    .up_usr_datatype_signed (),
    .up_usr_datatype_shift (),
    .up_usr_datatype_total_bits (),
    .up_usr_datatype_bits (),
    .up_usr_decimation_m (),
    .up_usr_decimation_n (),

    .up_clk (up_clk),
    .up_rstn (up_rstn),
    .up_wreq (up_wreq),
    .up_waddr (up_waddr),
    .up_wdata (up_wdata),
    .up_wack (up_wack),
    .up_rreq (up_rreq),
    .up_raddr (up_raddr),
    .up_rdata (up_rdata),
    .up_rack (up_rack)
  );

endmodule

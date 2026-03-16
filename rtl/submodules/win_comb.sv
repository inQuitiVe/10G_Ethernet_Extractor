// win_comb.sv — Sliding window comb: wide, wide_fill, hdr, out_bytes, noff5.
`timescale 1ns/1ps

module win_comb (
  input  logic [63:0]  wa,
  input  logic [63:0]  wb,
  input  logic         wb_vld,
  input  logic [2:0]   off,
  input  logic [5:0]   prem,

  output logic [127:0] wide,
  output logic [127:0] wide_fill,
  output logic [15:0]  hdr,
  output logic [3:0]   out_bytes,
  output logic [4:0]   noff5
);

  assign wide      = {wa, wb};
  assign wide_fill = {wa, wb_vld ? wb : 64'b0};
  assign hdr       = wide[127 - off*8 -: 16];
  assign out_bytes = (prem >= 6'd8) ? 4'd8 : prem[3:0];
  assign noff5     = {1'b0, off} + {1'b0, out_bytes};

endmodule

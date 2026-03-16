// barrel_shift_64.sv — 128b window → 64b at byte offset. 8-way MUX, critical path.
`timescale 1ns/1ps

module barrel_shift_64 (
  input  logic [127:0] window,
  input  logic [2:0]   offset,
  output logic [63:0]  data_out
);

  assign data_out = window[127 - offset*8 -: 64];

endmodule

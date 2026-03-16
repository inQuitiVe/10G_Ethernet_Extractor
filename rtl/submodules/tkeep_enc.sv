// tkeep_enc.sv — byte_count → MSB-first tkeep mask (8→0xFF, 3→0xE0, …)
`timescale 1ns/1ps

module tkeep_enc (
  input  logic [3:0]  byte_count,
  output logic [7:0]  tkeep
);

  assign tkeep = 8'hFF << (4'd8 - byte_count);

endmodule

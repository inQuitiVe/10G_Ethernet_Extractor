// byte_mux8.sv — 8-to-1 byte select, big-endian. ~64 gates vs ~800 for barrel.
`timescale 1ns/1ps

module byte_mux8 (
  input  logic [63:0] word,
  input  logic [2:0]  index,
  output logic [7:0]  byte_out
);

  always_comb case (index)
    3'd0: byte_out = word[63:56];
    3'd1: byte_out = word[55:48];
    3'd2: byte_out = word[47:40];
    3'd3: byte_out = word[39:32];
    3'd4: byte_out = word[31:24];
    3'd5: byte_out = word[23:16];
    3'd6: byte_out = word[15:8];
    default: byte_out = word[7:0];
  endcase

endmodule

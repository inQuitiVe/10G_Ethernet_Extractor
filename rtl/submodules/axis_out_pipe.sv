// axis_out_pipe.sv — Output pipeline reg; data only when v_pre. Power + timing.
`timescale 1ns/1ps

module axis_out_pipe (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [63:0] d_pre,
  input  logic [7:0]  k_pre,
  input  logic        l_pre,
  input  logic        v_pre,
  output logic [63:0] m_tdata,
  output logic [7:0]  m_tkeep,
  output logic        m_tlast,
  output logic        m_tvalid
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_tdata  <= '0;
      m_tkeep  <= '0;
      m_tlast  <= 1'b0;
      m_tvalid <= 1'b0;
    end else begin
      m_tvalid <= v_pre;
      if (v_pre) begin
        m_tdata <= d_pre;
        m_tkeep <= k_pre;
        m_tlast <= l_pre;
      end
    end
  end

endmodule

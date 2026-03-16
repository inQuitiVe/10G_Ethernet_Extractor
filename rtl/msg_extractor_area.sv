// msg_extractor_area.sv — Area-optimized
// Byte-serial: 1 byte/cycle from wa_q → ~8× slower, ~12× smaller comb logic.

`timescale 1ns/1ps

module msg_extractor_area (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [63:0] s_tdata,
  input  logic [7:0]  s_tkeep,
  input  logic        s_tvalid,
  input  logic        s_tlast,
  output logic        s_tready,
  output logic [63:0] m_tdata,
  output logic [7:0]  m_tkeep,
  output logic        m_tvalid,
  output logic        m_tlast,
  input  logic        m_tready
);

  import pkg_msg_extractor::*;

  typedef enum logic [1:0] {
    S_IDLE = 2'd0,
    S_HDR  = 2'd1,
    S_PAY  = 2'd2
  } state_t;

  state_t state_q, state_nx;

  logic [63:0] wa_q,   wa_nx;
  logic [2:0]  bptr_q, bptr_nx;  // byte pointer in wa_q (0-7)
  logic [7:0]  hb0_q;             // saved first header byte
  logic        hgot_q;            // '1' = first header byte captured
  logic [5:0]  prem_q, prem_nx;
  logic [63:0] out_q;             // output accumulator
  logic [2:0]  ocnt_q;            // bytes already in out_q
  logic        last_q;

  logic [7:0] cur_byte;

  byte_mux8 u_bmux (
    .word    (wa_q),
    .index   (bptr_q),
    .byte_out(cur_byte)
  );

  always_comb case (ocnt_q)
    3'd0: m_tdata = {cur_byte, 56'h00};
    3'd1: m_tdata = {out_q[63:56], cur_byte, 48'h00};
    3'd2: m_tdata = {out_q[63:48], cur_byte, 40'h00};
    3'd3: m_tdata = {out_q[63:40], cur_byte, 32'h00};
    3'd4: m_tdata = {out_q[63:32], cur_byte, 24'h00};
    3'd5: m_tdata = {out_q[63:24], cur_byte, 16'h00};
    3'd6: m_tdata = {out_q[63:16], cur_byte, 8'h00};
    default: m_tdata = {out_q[63:8], cur_byte};
  endcase

  // Flush when 8 bytes or last
  logic flush;
  assign flush = (state_q == S_PAY) && ((ocnt_q == 3'd7) || (prem_q == 6'd1));

  logic [7:0] m_tkeep_flush;
  tkeep_enc u_tkeep (
    .byte_count({1'b0, ocnt_q} + 4'd1),
    .tkeep     (m_tkeep_flush)
  );

  assign m_tkeep  = flush ? m_tkeep_flush : 8'h00;
  assign m_tlast  = flush && (prem_q == 6'd1);
  assign m_tvalid = flush;

  assign s_tready = (state_q == S_IDLE) || (bptr_q == 3'd7);

  always_comb begin
    state_nx = state_q;
    wa_nx    = wa_q;
    bptr_nx  = bptr_q;
    prem_nx  = prem_q;

    case (state_q)

      S_IDLE: begin
        if (s_tvalid) begin
          wa_nx    = s_tdata;
          bptr_nx  = 3'd0;
          prem_nx  = 6'd0;
          state_nx = S_HDR;
        end
      end

      S_HDR: begin
        bptr_nx = bptr_q + 3'd1;
        if (bptr_q == 3'd7 && s_tvalid) begin
          wa_nx   = s_tdata;
          bptr_nx = 3'd0;
        end

        if (hgot_q) begin
          // Validate header: hb0 must be 0, payload must be 8-32 bytes
          if (hb0_q != 8'h00 || cur_byte[5:0] < 6'd8 || cur_byte[5:0] > 6'd32) begin
            state_nx = S_IDLE;
          end else begin
            prem_nx  = cur_byte[5:0];
            state_nx = S_PAY;
          end
        end
      end

      S_PAY: begin
        // Escape: need next beat but last beat already received → abandon
        if (bptr_q == 3'd7 && !s_tvalid && last_q && prem_q != 6'd1) begin
          state_nx = S_IDLE;
        end else begin
          bptr_nx = bptr_q + 3'd1;
          if (bptr_q == 3'd7 && s_tvalid) begin
            wa_nx   = s_tdata;
            bptr_nx = 3'd0;
          end

          prem_nx = prem_q - 6'd1;

          if (flush) begin
            if (prem_q == 6'd1) begin
              state_nx = S_HDR;
              prem_nx  = 6'd0;
            end
          end
        end
      end

      default: state_nx = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= S_IDLE;
      wa_q    <= '0;  bptr_q  <= '0;
      hb0_q   <= '0;  hgot_q  <= 1'b0;
      prem_q  <= '0;
      out_q   <= '0;  ocnt_q  <= '0;
      last_q  <= 1'b0;
    end else begin
      state_q <= state_nx;
      wa_q    <= wa_nx;
      bptr_q  <= bptr_nx;
      prem_q  <= prem_nx;

      case (state_q)
        S_IDLE: begin
          hgot_q <= 1'b0;
          if (s_tvalid) last_q <= s_tlast;
        end

        S_HDR: begin
          if (!hgot_q) begin
            hb0_q  <= cur_byte;
            hgot_q <= 1'b1;
          end else begin
            hgot_q <= 1'b0;
            ocnt_q <= 3'd0;
          end
          if (bptr_q == 3'd7 && s_tvalid && s_tlast) last_q <= 1'b1;
        end

        S_PAY: begin
          if (bptr_q == 3'd7 && s_tvalid && s_tlast) last_q <= 1'b1;

          if (!flush) begin
            case (ocnt_q)
              3'd0: out_q[63:56] <= cur_byte;
              3'd1: out_q[55:48] <= cur_byte;
              3'd2: out_q[47:40] <= cur_byte;
              3'd3: out_q[39:32] <= cur_byte;
              3'd4: out_q[31:24] <= cur_byte;
              3'd5: out_q[23:16] <= cur_byte;
              3'd6: out_q[15:8]  <= cur_byte;
              default: out_q[7:0] <= cur_byte;
            endcase
            ocnt_q <= ocnt_q + 3'd1;
          end else begin
            ocnt_q <= 3'd0;
          end
        end

        default: ;
      endcase
    end
  end

endmodule

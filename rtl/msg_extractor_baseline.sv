// msg_extractor_baseline.sv — Baseline (most intuitive)
// Format: [2B payload_len][payload 8–32B], contiguous. s_tready sequential → 1-cycle bubble.

`timescale 1ns/1ps

module msg_extractor_baseline (
  input  logic        clk,
  input  logic        rst_n,

  // AXI-Stream Slave (input)
  input  logic [63:0] s_tdata,
  input  logic [7:0]  s_tkeep,
  input  logic        s_tvalid,
  input  logic        s_tlast,
  output logic        s_tready,

  // AXI-Stream Master (output)
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

  // wa/wb = sliding window; off = msg start in wa; prem = bytes left; last = s_tlast seen
  // wa_valid = 1 when wa holds a real (non-stale) beat for the current window position
  logic [63:0] wa_q,       wa_nx;
  logic [63:0] wb_q,       wb_nx;
  logic        wb_vld_q,   wb_vld_nx;
  logic        wa_valid_q, wa_valid_nx;
  logic [2:0]  off_q,      off_nx;
  logic [5:0]  prem_q,     prem_nx;
  logic        last_q,     last_nx;

  logic [127:0] wide, wide_fill;
  logic [15:0]  hdr;
  logic [3:0]   out_bytes;
  logic [4:0]   noff5;

  win_comb u_win (
    .wa       (wa_q),
    .wb       (wb_q),
    .wb_vld   (wb_vld_q),
    .off      (off_q),
    .prem     (prem_q),
    .wide     (wide),
    .wide_fill(wide_fill),
    .hdr      (hdr),
    .out_bytes(out_bytes),
    .noff5    (noff5)
  );

  barrel_shift_64 u_bshift (
    .window  (wide_fill),
    .offset  (off_q),
    .data_out(m_tdata)
  );

  tkeep_enc u_tkeep (
    .byte_count(out_bytes),
    .tkeep     (m_tkeep)
  );

  assign m_tlast  = (prem_q <= 6'd8);
  // Non-last beats always need wb (for promotion); last beat only needs wb when noff5>8
  assign m_tvalid = (state_q == S_PAY) &&
                    (wb_vld_q || (prem_q <= 6'd8 && noff5 <= 5'd8));
  assign s_tready = (state_q == S_IDLE) || !wb_vld_q;

  always_comb begin
    state_nx    = state_q;
    wa_nx       = wa_q;
    wb_nx       = wb_q;
    wb_vld_nx   = wb_vld_q;
    wa_valid_nx = wa_valid_q;
    off_nx      = off_q;
    prem_nx     = prem_q;
    last_nx     = last_q;

    // Fill wb when slot free
    if (s_tvalid && s_tready && (state_q != S_IDLE)) begin
      wb_nx     = s_tdata;
      wb_vld_nx = 1'b1;
      if (s_tlast) last_nx = 1'b1;
    end

    case (state_q)

      S_IDLE: begin
        if (s_tvalid) begin
          wa_nx       = s_tdata;
          wb_vld_nx   = 1'b0;
          wa_valid_nx = 1'b1;
          off_nx      = 3'd0;
          last_nx     = s_tlast;
          state_nx    = S_HDR;
        end
      end

      S_HDR: begin
        // off=0 and wa is stale: wait for fresh beat to arrive in wb
        if (off_q == 3'd0 && !wa_valid_q) begin
          if (wb_vld_q) begin
            // Promote newly arrived beat; parse header from it
            wa_nx       = wb_q;
            wb_vld_nx   = 1'b0;
            wa_valid_nx = 1'b1;
            prem_nx     = wb_q[53:48];  // bits [5:0] of wb_q[63:48]
            if (prem_nx < 6'd8 || prem_nx > 6'd32) begin
              state_nx = S_IDLE;
            end else begin
              off_nx   = 3'd2;
              state_nx = S_PAY;
            end
          end else if (last_q) begin
            state_nx = S_IDLE;
          end
          // else: keep waiting

        end else if ((off_q <= 3'd5) || wb_vld_q) begin
          // Normal parse: off 1-5 from wa, or off 6-7 with wb promotion
          prem_nx = hdr[5:0];
          if (prem_nx < 6'd8 || prem_nx > 6'd32) begin
            state_nx = S_IDLE;
          end else begin
            if (off_q <= 3'd5) begin
              off_nx = off_q + 3'd2;
            end else begin
              off_nx      = (off_q == 3'd6) ? 3'd0 : 3'd1;
              wa_nx       = wb_q;
              wb_vld_nx   = 1'b0;
              wa_valid_nx = 1'b1;
            end
            state_nx = S_PAY;
          end

        end else if (last_q) begin
          state_nx = S_IDLE;
        end
      end

      S_PAY: begin
        if (m_tvalid && m_tready) begin

          if (prem_q <= 6'd8) begin
            prem_nx = 6'd0;
            if (noff5 >= 5'd8) begin
              off_nx = noff5[2:0];
              if (noff5 != 5'd8 || wb_vld_q) begin
                // Valid promotion: wb holds the next real beat
                wa_nx       = wb_q;
                wb_vld_nx   = 1'b0;
                wa_valid_nx = 1'b1;
              end else begin
                // Stale path (noff5=8, wb empty): fill will load next beat;
                // leave wa and wb_vld to be set by fill block above
                wa_valid_nx = 1'b0;
              end
            end else begin
              off_nx = noff5[2:0];
            end
            state_nx = S_HDR;

          end else begin
            // Non-last beat: wb must be valid (guaranteed by m_tvalid)
            prem_nx     = prem_q - 6'd8;
            wa_nx       = wb_q;
            wb_vld_nx   = 1'b0;
            wa_valid_nx = 1'b1;
          end
        end
      end

      default: state_nx = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q    <= S_IDLE;
      wa_q       <= '0;
      wb_q       <= '0;
      wb_vld_q   <= 1'b0;
      wa_valid_q <= 1'b1;
      off_q      <= '0;
      prem_q     <= '0;
      last_q     <= 1'b0;
    end else begin
      state_q    <= state_nx;
      wa_q       <= wa_nx;
      wb_q       <= wb_nx;
      wb_vld_q   <= wb_vld_nx;
      wa_valid_q <= wa_valid_nx;
      off_q      <= off_nx;
      prem_q     <= prem_nx;
      last_q     <= last_nx;
    end
  end

endmodule

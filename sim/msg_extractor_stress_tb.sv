// msg_extractor_stress_tb.sv — File-driven random stress testbench
//
// Reads a vector file produced by sim/scripts/gen_test.py and replays it
// against the selected DUT variant, checking every output beat.
//
// Run:
//   vvp <compiled>.vvp [+vectors=<path>]
//   Default path: sim/pattern/baseline_custom_seed42.txt  (via Makefile VFILE)
//
// Vector file tokens (one per line):
//   R                              -- reset DUT; start of packet
//   I <data:16h> <keep:2h> <last>  -- AXI-S input beat
//   O <data:16h> <keep:2h> <last>  -- expected output beat
//   # ...                          -- comment (skipped)

`timescale 1ns/1ps

module msg_extractor_stress_tb;

  import pkg_msg_extractor::*;

  // ── DUT interface ────────────────────────────────────────────────────────────
  logic        clk, rst_n;
  logic [63:0] s_tdata;
  logic [7:0]  s_tkeep;
  logic        s_tvalid, s_tlast, s_tready;
  logic [63:0] m_tdata;
  logic [7:0]  m_tkeep;
  logic        m_tvalid, m_tlast;
  logic        m_tready;

  initial clk = 0;
  always  #5 clk = ~clk;
  assign m_tready = 1'b1;

  // ── Optional VCD waveform dump (enabled by -DDUMP_VCD at compile time) ──────
`ifdef DUMP_VCD
  initial begin
`ifdef MSG_DESIGN_POWER
    $dumpfile("sim/waveform/power_stress.vcd");
`elsif MSG_DESIGN_AREA
    $dumpfile("sim/waveform/area_stress.vcd");
`elsif MSG_DESIGN_THROUGHPUT
    $dumpfile("sim/waveform/throughput_stress.vcd");
`elsif MSG_DESIGN_TIMING
    $dumpfile("sim/waveform/timing_stress.vcd");
`else
    $dumpfile("sim/waveform/baseline_stress.vcd");
`endif
    $dumpvars(0, msg_extractor_stress_tb);
  end
`endif

  // ── DUT instantiation (compile-time selection) ────────────────────────────
`ifdef MSG_DESIGN_POWER
  msg_extractor_power dut (
`elsif MSG_DESIGN_AREA
  msg_extractor_area dut (
`elsif MSG_DESIGN_THROUGHPUT
  msg_extractor_throughput dut (
`elsif MSG_DESIGN_TIMING
  msg_extractor_timing dut (
`else
  msg_extractor_baseline dut (
`endif
    .clk(clk),        .rst_n(rst_n),
    .s_tdata(s_tdata), .s_tkeep(s_tkeep),
    .s_tvalid(s_tvalid), .s_tlast(s_tlast), .s_tready(s_tready),
    .m_tdata(m_tdata),  .m_tkeep(m_tkeep),
    .m_tvalid(m_tvalid), .m_tlast(m_tlast), .m_tready(m_tready)
  );

  // ── Output monitor ───────────────────────────────────────────────────────────
  localparam MAX_OUT = 16384;
  integer      n_out;
  logic [63:0] out_d [0:MAX_OUT-1];
  logic [7:0]  out_k [0:MAX_OUT-1];
  logic [0:0]  out_l [0:MAX_OUT-1];

  always @(posedge clk) begin
    if (m_tvalid && m_tready) begin
      out_d[n_out] = m_tdata;
      out_k[n_out] = m_tkeep;
      out_l[n_out] = m_tlast;
      n_out++;
    end
  end

  // ── Vector storage (pre-loaded from file) ────────────────────────────────────
  // v_type: 0 = R (reset), 1 = I (input beat), 2 = O (expected output)
  localparam MAX_V = 65536;
  integer      v_type [0:MAX_V-1];
  logic [63:0] v_d    [0:MAX_V-1];
  logic [7:0]  v_k    [0:MAX_V-1];
  logic [0:0]  v_l    [0:MAX_V-1];
  integer      n_v;

  // ── Expected outputs for current packet ─────────────────────────────────────
  localparam MAX_EXP = 4096;
  logic [63:0] exp_d [0:MAX_EXP-1];
  logic [7:0]  exp_k [0:MAX_EXP-1];
  logic [0:0]  exp_l [0:MAX_EXP-1];
  integer      n_exp;

  integer pass_cnt, fail_cnt, pkt_cnt;

  // Convert 8-bit tkeep to 64-bit byte-enable mask (MSB-first)
  function automatic logic [63:0] tkeep_mask(input logic [7:0] k);
    integer b;
    logic [63:0] m;
    m = '0;
    for (b = 0; b < 8; b++)
      if (k[7-b]) m[63-b*8 -: 8] = 8'hFF;
    return m;
  endfunction

  // ── Helper tasks ─────────────────────────────────────────────────────────────

  task automatic skip_line(input integer fd);
    integer r; reg [7:0] c;
    c = 0;
    while (c != 8'h0A) begin
      r = $fscanf(fd, "%c", c);
      if (r <= 0) disable skip_line;
    end
  endtask

  task do_reset;
    rst_n = 0; s_tvalid = 0; s_tlast = 0;
    s_tdata = '0; s_tkeep = 8'hFF;
    n_out = 0;
    repeat(4) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
  endtask

  task send_beat(input logic [63:0] d,
                 input logic [7:0]  k,
                 input logic        l);
    s_tdata = d; s_tkeep = k; s_tlast = l; s_tvalid = 1;
    @(posedge clk);
    while (!s_tready) @(posedge clk);
  endtask

  // Wait for expected outputs then compare against exp_* buffer.
  task check_packet(input integer pkt_base);
    integer timeout, i;
    // Wait up to 10000 cycles for all expected outputs
    timeout = 0;
    while (timeout < 10000 && n_out < pkt_base + n_exp) begin
      @(posedge clk);
      timeout++;
    end

    if (n_out < pkt_base + n_exp) begin
      $display("  TIMEOUT pkt %0d: expected %0d beats, got %0d",
               pkt_cnt, n_exp, n_out - pkt_base);
      fail_cnt = fail_cnt + (n_exp - (n_out - pkt_base));
    end else begin

    for (i = 0; i < n_exp; i++) begin : check_loop
      logic [63:0] mask, exp_masked, got_masked;
      mask       = tkeep_mask(exp_k[i]);
      exp_masked = exp_d[i]         & mask;
      got_masked = out_d[pkt_base+i] & mask;
      if (got_masked === exp_masked &&
          out_k[pkt_base+i] === exp_k[i] &&
          out_l[pkt_base+i] === exp_l[i]) begin
        pass_cnt++;
      end else begin
        $display("  FAIL pkt %0d beat %0d:", pkt_cnt, i);
        $display("    exp  d=%016h (masked=%016h)  k=%02h  l=%b",
                 exp_d[i], exp_masked, exp_k[i], exp_l[i]);
        $display("    got  d=%016h (masked=%016h)  k=%02h  l=%b",
                 out_d[pkt_base+i], got_masked,
                 out_k[pkt_base+i], out_l[pkt_base+i]);
        fail_cnt++;
      end
    end
    end  // close else
  endtask

  // ── Main ─────────────────────────────────────────────────────────────────────
  initial begin
    string   vfile;
    integer  fd, r, i;
    reg [7:0] tchar;
    logic [63:0] d; logic [7:0] k; logic [0:0] l;
    integer pkt_base;

    if (!$value$plusargs("vectors=%s", vfile))
      vfile = "sim/pattern/baseline_custom_seed42.txt";

    // ── Load entire vector file into arrays ─────────────────────────────────
    fd = $fopen(vfile, "r");
    if (fd == 0) begin
      $display("ERROR: cannot open vector file '%s'", vfile);
      $finish;
    end
    n_v = 0;
    begin : load_loop
      integer done;
      done = 0;
      while (!$feof(fd) && !done) begin
        r = $fscanf(fd, " %c", tchar);
        if (r <= 0) begin
          done = 1;
        end else begin
          case (tchar)
            "R": begin
              v_type[n_v] = 0; n_v++;
            end
            "I": begin
              r = $fscanf(fd, " %h %h %b", d, k, l);
              v_type[n_v] = 1; v_d[n_v] = d; v_k[n_v] = k; v_l[n_v] = l; n_v++;
            end
            "O": begin
              r = $fscanf(fd, " %h %h %b", d, k, l);
              v_type[n_v] = 2; v_d[n_v] = d; v_k[n_v] = k; v_l[n_v] = l; n_v++;
            end
            default: skip_line(fd);
          endcase
        end
      end
    end
    $fclose(fd);

    $display("================================================================");
    $display("Stress Testbench");
    $display("  vectors : %s", vfile);
    $display("  entries : %0d", n_v);
    $display("================================================================");

    // ── Replay vectors ────────────────────────────────────────────────────────
    pass_cnt = 0; fail_cnt = 0; pkt_cnt = 0;
    n_exp = 0; pkt_base = 0;

    for (i = 0; i < n_v; i++) begin
      case (v_type[i])

        0: begin // R — flush previous packet, reset for next
          if (pkt_cnt > 0 && n_exp > 0) begin
            s_tvalid = 0;
            check_packet(pkt_base);
          end
          do_reset;
          pkt_base = n_out;
          n_exp    = 0;
          pkt_cnt++;
        end

        1: begin // I — send input beat
          send_beat(v_d[i], v_k[i], v_l[i]);
        end

        2: begin // O — buffer expected output for this packet
          exp_d[n_exp] = v_d[i];
          exp_k[n_exp] = v_k[i];
          exp_l[n_exp] = v_l[i];
          n_exp++;
        end

      endcase
    end

    // Flush last packet
    if (n_exp > 0) begin
      s_tvalid = 0;
      check_packet(pkt_base);
    end

    repeat(5) @(posedge clk);

    $display("================================================================");
    $display("Packets : %0d", pkt_cnt);
    $display("Results : %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("================================================================");
    $finish;
  end

endmodule

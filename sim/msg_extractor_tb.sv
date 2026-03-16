// =============================================================================
// msg_extractor_tb.sv
// Testbench for 10G Ethernet Message Extractor (all variants)
//
// Compile-time DUT selection:
//   -DMSG_DESIGN_POWER      → msg_extractor_power
//   -DMSG_DESIGN_AREA       → msg_extractor_area
//   -DMSG_DESIGN_THROUGHPUT → msg_extractor_throughput
//   -DMSG_DESIGN_TIMING     → msg_extractor_timing
//   (default)               → msg_extractor_baseline
//
// Design: background monitor collects ALL output beats into arrays.
// Tests send inputs, then verify by indexing collected outputs.
// =============================================================================

`timescale 1ns/1ps

module msg_extractor_tb;

  import pkg_msg_extractor::*;

  // ── DUT signals ─────────────────────────────────────────────────────────────
  logic        clk, rst_n;
  logic [63:0] s_tdata;
  logic [7:0]  s_tkeep;
  logic        s_tvalid, s_tlast, s_tready;
  logic [63:0] m_tdata;
  logic [7:0]  m_tkeep;
  logic        m_tvalid, m_tlast;
  logic        m_tready;

  // Clock: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Downstream always ready (per spec)
  assign m_tready = 1'b1;

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
    .clk      (clk),      .rst_n    (rst_n),
    .s_tdata  (s_tdata),  .s_tkeep  (s_tkeep),
    .s_tvalid (s_tvalid), .s_tlast  (s_tlast),  .s_tready (s_tready),
    .m_tdata  (m_tdata),  .m_tkeep  (m_tkeep),
    .m_tvalid (m_tvalid), .m_tlast  (m_tlast),  .m_tready (m_tready)
  );

  // ── Optional VCD waveform dump (enabled by -DDUMP_VCD at compile time) ──────
  // The output path mirrors the compile-time DUT selection, so each variant
  // produces a uniquely named .vcd in sim/waveform/.
`ifdef DUMP_VCD
  initial begin
`ifdef MSG_DESIGN_POWER
    $dumpfile("sim/waveform/power_func.vcd");
`elsif MSG_DESIGN_AREA
    $dumpfile("sim/waveform/area_func.vcd");
`elsif MSG_DESIGN_THROUGHPUT
    $dumpfile("sim/waveform/throughput_func.vcd");
`elsif MSG_DESIGN_TIMING
    $dumpfile("sim/waveform/timing_func.vcd");
`else
    $dumpfile("sim/waveform/baseline_func.vcd");
`endif
    $dumpvars(0, msg_extractor_tb);
  end
`endif

  // ── Output monitor: captures ALL valid output beats ────────────────────────
  // Using plain arrays for Icarus Verilog compatibility.
  integer      n_out;
  logic [63:0] out_d [0:511];
  logic [7:0]  out_k [0:511];
  logic        out_l [0:511];

  integer pass_cnt, fail_cnt;

  always @(posedge clk) begin
    if (m_tvalid && m_tready) begin
      out_d[n_out] = m_tdata;
      out_k[n_out] = m_tkeep;
      out_l[n_out] = m_tlast;
      n_out        = n_out + 1;
    end
  end

  // ── Timeout watchdog ────────────────────────────────────────────────────────
  initial begin
    #200000;
    $display("ERROR: Global simulation timeout");
    $finish;
  end

  // ── Helper tasks ────────────────────────────────────────────────────────────

  // Reset DUT and clear monitor state
  task do_reset;
    rst_n    = 0;
    s_tvalid = 0; s_tlast = 0;
    s_tdata  = 64'h0; s_tkeep = 8'hFF;
    n_out    = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);
  endtask

  // Send one 64-bit input beat; blocks until the DUT accepts it
  // (s_tready high at the clock edge when s_tvalid is high)
  task send_beat(input logic [63:0] data,
                 input logic [7:0]  keep,
                 input logic        last);
    s_tdata  = data;
    s_tkeep  = keep;
    s_tlast  = last;
    s_tvalid = 1;
    @(posedge clk);
    while (!s_tready) @(posedge clk);
    // Beat accepted on this posedge (s_tready was 1)
  endtask

  // De-assert s_tvalid (idle cycle on input bus)
  task send_idle;
    s_tvalid = 0;
    @(posedge clk);
  endtask

  // Wait until n_out reaches (base + count), with timeout
  task wait_for_outputs(input integer base, input integer count, input string ctx);
    integer timeout_cnt;
    for (timeout_cnt = 0; timeout_cnt < 1000; timeout_cnt = timeout_cnt + 1) begin
      if (n_out >= base + count) disable wait_for_outputs;
      @(posedge clk);
    end
    $display("  TIMEOUT [%s]: got %0d/%0d expected outputs", ctx, n_out - base, count);
  endtask

  // Check a single collected beat against expected values
  task check_beat(input integer    idx,
                  input logic [63:0] exp_d,
                  input logic [7:0]  exp_k,
                  input logic        exp_l,
                  input string       label);
    if (out_d[idx] === exp_d && out_k[idx] === exp_k && out_l[idx] === exp_l) begin
      $display("  PASS [%s]: data=0x%016X keep=0x%02X last=%b",
               label, out_d[idx], out_k[idx], out_l[idx]);
      pass_cnt = pass_cnt + 1;
    end else begin
      $display("  FAIL [%s]:", label);
      $display("    expected data=0x%016X keep=0x%02X last=%b", exp_d, exp_k, exp_l);
      $display("    actual   data=0x%016X keep=0x%02X last=%b",
               out_d[idx], out_k[idx], out_l[idx]);
      fail_cnt = fail_cnt + 1;
    end
  endtask

  // ============================================================================
  // Test cases
  // ============================================================================

  // ----------------------------------------------------------------------------
  // Test 1: Single 8-byte message (aligned, off=0)
  //
  // Packet layout (10 bytes):
  //   [0x00 0x08] [0xDE 0xAD 0xBE 0xEF 0x00 0x00 0x00 0x01]
  //    header(2)   payload(8)
  //
  // Bus beats:
  //   Beat 0: 0x0008_DEAD_BEEF_0000  (header + payload bytes 0-5)
  //   Beat 1: 0x0001_0000_0000_0000  (payload bytes 6-7 in top 2 bytes), tlast
  //
  // Expected output:
  //   1 beat: data=0xDEAD_BEEF_0000_0001, keep=0xFF, last=1
  // ----------------------------------------------------------------------------
  task test_single_8byte_msg;
    integer base;
    $display("[%0t] Test 1: Single 8-byte aligned message", $time);
    do_reset;
    base = n_out;

    send_beat(64'h0008_DEAD_BEEF_0000, 8'hFF, 1'b0);
    send_beat(64'h0001_0000_0000_0000, 8'hC0, 1'b1);
    s_tvalid = 0;

    wait_for_outputs(base, 1, "test1");

    check_beat(base + 0, 64'hDEAD_BEEF_0000_0001, 8'hFF, 1'b1, "T1 msg1");
    repeat (5) @(posedge clk);
  endtask

  // ----------------------------------------------------------------------------
  // Test 2: Two consecutive messages in one packet
  //
  //   Msg1: header=0x0008 (8-byte payload)  → 0xDEAD_BEEF_0000_0001
  //   Msg2: header=0x000A (10-byte payload) → 0xCAFE_BABE_0000_0000_0002
  //
  // Packet layout (22 bytes):
  //   Bytes  0- 1: msg1 header 0x0008
  //   Bytes  2- 9: msg1 payload 0xDE AD BE EF 00 00 00 01
  //   Bytes 10-11: msg2 header 0x000A
  //   Bytes 12-21: msg2 payload 0xCA FE BA BE 00 00 00 00 00 02
  //
  // Bus beats (8 bytes each):
  //   Beat 0: 0x0008_DEAD_BEEF_0000  bytes  0- 7
  //   Beat 1: 0x0001_000A_CAFE_BABE  bytes  8-15
  //   Beat 2: 0x0000_0000_0002_0000  bytes 16-23 (last 2 valid in stream are at [23:16])
  //                                  but with our stream layout bytes 16-21 are valid
  //
  // Expected outputs:
  //   Beat A: msg1 payload  0xDEAD_BEEF_0000_0001  keep=0xFF last=1
  //   Beat B: msg2 pay[0-7] 0xCAFE_BABE_0000_0000  keep=0xFF last=0
  //   Beat C: msg2 pay[8-9] 0x0002_XXXX_XXXX_XXXX  keep=0xC0 last=1
  //             (bytes 0-1 valid = 0x00 0x02, so data[63:48]=0x0002)
  // ----------------------------------------------------------------------------
  task test_two_messages;
    integer base;
    $display("[%0t] Test 2: Two messages (8B + 10B)", $time);
    do_reset;
    base = n_out;

    // Beat 0: header(2) + msg1-payload[0..5]
    send_beat(64'h0008_DEAD_BEEF_0000, 8'hFF, 1'b0);
    // Beat 1: msg1-payload[6..7] + msg2-header(2) + msg2-payload[0..3]
    send_beat(64'h0001_000A_CAFE_BABE, 8'hFF, 1'b0);
    // Beat 2: msg2-payload[4..9] (6 bytes valid), rest padded 0
    // Stream bytes 16-21: 0x00 0x00 0x00 0x00 0x00 0x02
    // In 64-bit big-endian word: [63:56]=0x00 [55:48]=0x00 [47:40]=0x00 [39:32]=0x00 [31:24]=0x00 [23:16]=0x02
    send_beat(64'h0000_0000_0002_0000, 8'hFF, 1'b1);
    s_tvalid = 0;

    wait_for_outputs(base, 3, "test2");

    check_beat(base + 0, 64'hDEAD_BEEF_0000_0001, 8'hFF, 1'b1, "T2 msg1");
    check_beat(base + 1, 64'hCAFE_BABE_0000_0000, 8'hFF, 1'b0, "T2 msg2-beat0");
    // msg2 payload bytes 8-9 are 0x00,0x02 → big-endian at [63:48] = 0x0002
    check_beat(base + 2, 64'h0002_0000_0000_0000, 8'hC0, 1'b1, "T2 msg2-beat1");
    repeat (5) @(posedge clk);
  endtask

  // ----------------------------------------------------------------------------
  // Test 3: Maximum-length payload (32 bytes)
  //
  // Packet: header=0x0020, payload = 32 bytes of 0xAA
  //
  // Bus beats:
  //   Beat 0: 0x0020_AAAA_AAAA_AAAA  header + pay[0..5]
  //   Beat 1: 0xAAAA_AAAA_AAAA_AAAA  pay[6..13]
  //   Beat 2: 0xAAAA_AAAA_AAAA_AAAA  pay[14..21]
  //   Beat 3: 0xAAAA_AAAA_AAAA_AAAA  pay[22..29]
  //   Beat 4: 0xAAAA_AAAA_0000_0000  pay[30..31], tlast (only 2 valid bytes)
  //
  // Expected outputs (4 full beats, prem=32, off=2):
  //   B0: 0xAAAA_AAAA_AAAA_AAAA keep=0xFF last=0
  //   B1: 0xAAAA_AAAA_AAAA_AAAA keep=0xFF last=0
  //   B2: 0xAAAA_AAAA_AAAA_AAAA keep=0xFF last=0
  //   B3: 0xAAAA_AAAA_AAAA_AAAA keep=0xFF last=1
  // ----------------------------------------------------------------------------
  task test_max_payload;
    integer base, i;
    $display("[%0t] Test 3: Maximum 32-byte payload", $time);
    do_reset;
    base = n_out;

    send_beat(64'h0020_AAAA_AAAA_AAAA, 8'hFF, 1'b0);  // hdr + pay[0..5]
    send_beat(64'hAAAA_AAAA_AAAA_AAAA, 8'hFF, 1'b0);  // pay[6..13]
    send_beat(64'hAAAA_AAAA_AAAA_AAAA, 8'hFF, 1'b0);  // pay[14..21]
    send_beat(64'hAAAA_AAAA_AAAA_AAAA, 8'hFF, 1'b0);  // pay[22..29]
    send_beat(64'hAAAA_AAAA_0000_0000, 8'hC0, 1'b1);  // pay[30..31]
    s_tvalid = 0;

    wait_for_outputs(base, 4, "test3");

    for (i = 0; i < 3; i = i + 1) begin
      check_beat(base + i, 64'hAAAA_AAAA_AAAA_AAAA, 8'hFF, 1'b0, "T3 pay");
    end
    check_beat(base + 3, 64'hAAAA_AAAA_AAAA_AAAA, 8'hFF, 1'b1, "T3 last");
    repeat (5) @(posedge clk);
  endtask

  // ----------------------------------------------------------------------------
  // Test 4: Input with bubble cycles (tvalid gaps)
  //
  // Same as Test 1 but with idle beats between valid beats.
  // Verifies the DUT holds state correctly when input stalls.
  // ----------------------------------------------------------------------------
  task test_with_input_gaps;
    integer base;
    $display("[%0t] Test 4: Input with gaps (tvalid bubbles)", $time);
    do_reset;
    base = n_out;

    send_beat(64'h0008_DEAD_BEEF_0000, 8'hFF, 1'b0);
    send_idle; send_idle;                               // 2 idle beats
    send_beat(64'h0001_0000_0000_0000, 8'hC0, 1'b1);
    s_tvalid = 0;

    wait_for_outputs(base, 1, "test4");

    check_beat(base + 0, 64'hDEAD_BEEF_0000_0001, 8'hFF, 1'b1, "T4 msg1");
    repeat (5) @(posedge clk);
  endtask

  // ----------------------------------------------------------------------------
  // Test 5: Minimum-length payload (8 bytes) back-to-back in one packet
  //
  // Three 8-byte messages stacked:
  //   Msg1: header=0x0008, payload=0x1111_1111_1111_1111
  //   Msg2: header=0x0008, payload=0x2222_2222_2222_2222
  //   Msg3: header=0x0008, payload=0x3333_3333_3333_3333
  //
  // Packet total = 3*(2+8) = 30 bytes
  // Bus beats:
  //   Beat 0: 0x0008_1111_1111_1111  msg1 hdr + pay[0..5]
  //   Beat 1: 0x1111_0008_2222_2222  msg1 pay[6..7] + msg2 hdr + msg2 pay[0..3]
  //   Beat 2: 0x2222_2222_0008_3333  msg2 pay[4..7] + msg3 hdr + msg3 pay[0..1]
  //   Beat 3: 0x3333_3333_3333_0000  msg3 pay[2..7], tlast
  //
  // Expected outputs:
  //   0x1111_1111_1111_1111  keep=0xFF last=1
  //   0x2222_2222_2222_2222  keep=0xFF last=1
  //   0x3333_3333_3333_3333  keep=0xFF last=1
  // ----------------------------------------------------------------------------
  task test_multi_min_msgs;
    integer base;
    $display("[%0t] Test 5: Three 8-byte messages back-to-back", $time);
    do_reset;
    base = n_out;

    send_beat(64'h0008_1111_1111_1111, 8'hFF, 1'b0);
    send_beat(64'h1111_0008_2222_2222, 8'hFF, 1'b0);
    send_beat(64'h2222_2222_0008_3333, 8'hFF, 1'b0);
    send_beat(64'h3333_3333_3333_0000, 8'hC0, 1'b1);
    s_tvalid = 0;

    wait_for_outputs(base, 3, "test5");

    check_beat(base + 0, 64'h1111_1111_1111_1111, 8'hFF, 1'b1, "T5 msg1");
    check_beat(base + 1, 64'h2222_2222_2222_2222, 8'hFF, 1'b1, "T5 msg2");
    check_beat(base + 2, 64'h3333_3333_3333_3333, 8'hFF, 1'b1, "T5 msg3");
    repeat (5) @(posedge clk);
  endtask

  // ── Main test sequence ───────────────────────────────────────────────────────
  initial begin
    pass_cnt = 0; fail_cnt = 0; n_out = 0;
    $display("============================================================");
    $display("10G Ethernet Message Extractor Testbench");
    $display("============================================================");

    test_single_8byte_msg;
    test_two_messages;
    test_max_payload;
    test_with_input_gaps;
    test_multi_min_msgs;

    $display("============================================================");
    $display("Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("============================================================");
    $finish;
  end

endmodule

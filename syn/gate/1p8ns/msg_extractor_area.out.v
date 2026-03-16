/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : Q-2019.12-SP5-3
// Date      : Mon Mar 16 06:12:14 2026
/////////////////////////////////////////////////////////////


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_0 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_1 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_2 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_3 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_4 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_5 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_6 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_7 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_8 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_9 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module SNPS_CLOCK_GATE_HIGH_msg_extractor_area_10 ( CLK, EN, ENCLK, TE );
  input CLK, EN, TE;
  output ENCLK;


  CKLNQD1 latch ( .CP(CLK), .E(EN), .TE(TE), .Q(ENCLK) );
endmodule


module msg_extractor_area ( clk, rst_n, s_tdata, s_tkeep, s_tvalid, s_tlast, 
        s_tready, m_tdata, m_tkeep, m_tvalid, m_tlast, m_tready );
  input [63:0] s_tdata;
  input [7:0] s_tkeep;
  output [63:0] m_tdata;
  output [7:0] m_tkeep;
  input clk, rst_n, s_tvalid, s_tlast, m_tready;
  output s_tready, m_tvalid, m_tlast;
  wire   n_Logic0_, n385, n386, n387, state_q_0_, last_q, N375, N383, N384,
         N385, N386, N387, N388, N389, net150, net156, net161, net166, net171,
         net176, net181, net186, net191, net196, net201, n107, n108, n109,
         n110, n117, n118, n119, n120, n121, n122, n123, n124, n125, n126,
         n127, n128, n129, n130, n131, n132, n133, n134, n135, n136, n137,
         n138, n139, n140, n141, n142, n143, n144, n145, n146, n147, n148,
         n149, n150, n151, n152, n153, n154, n155, n156, n157, n158, n159,
         n160, n161, n162, n163, n164, n165, n166, n167, n168, n169, n170,
         n171, n172, n173, n174, n175, n176, n177, n178, n179, n180, n181,
         n182, n183, n184, n185, n186, n187, n188, n189, n190, n191, n192,
         n193, n194, n195, n196, n197, n198, n199, n200, n201, n202, n203,
         n204, n205, n206, n207, n208, n209, n210, n211, n212, n213, n214,
         n215, n216, n217, n218, n219, n220, n221, n222, n223, n224, n225,
         n226, n227, n228, n229, n230, n231, n232, n233, n234, n235, n236,
         n237, n238, n239, n241, n242, n243, n244, n245, n246, n247, n248,
         n249, n250, n251, n252, n253, n254, n255, n256, n257, n258, n259,
         n260, n261, n262, n263, n264, n265, n266, n267, n268, n269, n270,
         n271, n272, n273, n274, n275, n276, n277, n278, n279, n280, n281,
         n282, n283, n284, n285, n286, n287, n288, n289, n290, n291, n292,
         n293, n294, n295, n296, n297, n298, n299, n300, n301, n302, n303,
         n304, n305, n306, n307, n308, n309, n310, n311, n312, n313, n314,
         n315, n316, n317, n318, n319, n320, n321, n322, n323, n324, n325,
         n326, n327, n328, n329, n330, n331, n332, n333, n334, n335, n336,
         n337, n338, n339, n340, n341, n342, n343, n344, n345, n346, n347,
         n348, n349, n350, n351, n352, n353, n354, n355, n356, n357, n358,
         n359, n360, n361, n362, n363, n364, n365, n366, n367, n368, n369,
         n370, n371, n372, n373, n374, n375, n376, n377, n378, n379, n380,
         n381, n382, n383, n384;
  wire   [63:0] wa_q;
  wire   [2:0] bptr_q;
  wire   [7:0] cur_byte;
  wire   [2:0] ocnt_q;
  wire   [5:0] prem_q;

  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_0 clk_gate_wa_q_reg ( .CLK(clk), 
        .EN(n108), .ENCLK(net150), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_10 clk_gate_hb0_q_reg ( .CLK(clk), 
        .EN(N375), .ENCLK(net156), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_9 clk_gate_prem_q_reg ( .CLK(clk), 
        .EN(n110), .ENCLK(net161), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_8 clk_gate_out_q_reg ( .CLK(clk), 
        .EN(N389), .ENCLK(net166), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_7 clk_gate_out_q_reg_0 ( .CLK(clk), 
        .EN(N388), .ENCLK(net171), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_6 clk_gate_out_q_reg_1 ( .CLK(clk), 
        .EN(N387), .ENCLK(net176), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_5 clk_gate_out_q_reg_2 ( .CLK(clk), 
        .EN(N386), .ENCLK(net181), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_4 clk_gate_out_q_reg_3 ( .CLK(clk), 
        .EN(N385), .ENCLK(net186), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_3 clk_gate_out_q_reg_4 ( .CLK(clk), 
        .EN(N384), .ENCLK(net191), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_2 clk_gate_out_q_reg_5 ( .CLK(clk), 
        .EN(N383), .ENCLK(net196), .TE(n_Logic0_) );
  SNPS_CLOCK_GATE_HIGH_msg_extractor_area_1 clk_gate_ocnt_q_reg ( .CLK(clk), 
        .EN(n107), .ENCLK(net201), .TE(n_Logic0_) );
  EDFCNQD1 clk_r_REG138_S5 ( .D(N375), .E(n380), .CP(clk), .CDN(rst_n), .Q(
        n379) );
  DFCNQD1 clk_r_REG8_S2 ( .D(n381), .CP(net156), .CDN(rst_n), .Q(n378) );
  EDFCNQD1 clk_r_REG11_S4 ( .D(state_q_0_), .E(n109), .CP(clk), .CDN(rst_n), 
        .Q(n377) );
  DFCNQD1 clk_r_REG132_S4 ( .D(ocnt_q[0]), .CP(net201), .CDN(rst_n), .Q(n376)
         );
  DFSNQD1 clk_r_REG33_S6 ( .D(n383), .CP(net161), .SDN(rst_n), .Q(n375) );
  EDFCNQD1 clk_r_REG12_S5 ( .D(last_q), .E(n384), .CP(net150), .CDN(rst_n), 
        .Q(n374) );
  DFCNQD1 clk_r_REG135_S5 ( .D(bptr_q[2]), .CP(net150), .CDN(rst_n), .Q(n373)
         );
  DFCNQD1 clk_r_REG137_S5 ( .D(bptr_q[0]), .CP(net150), .CDN(rst_n), .Q(n372)
         );
  DFCNQD1 clk_r_REG42_S6 ( .D(prem_q[1]), .CP(net161), .CDN(rst_n), .Q(n371)
         );
  DFCNQD1 clk_r_REG51_S6 ( .D(prem_q[0]), .CP(net161), .CDN(rst_n), .Q(n370)
         );
  DFCNQD1 clk_r_REG9_S3 ( .D(prem_q[5]), .CP(net161), .CDN(rst_n), .Q(n369) );
  DFCNQD1 clk_r_REG13_S4 ( .D(prem_q[3]), .CP(net161), .CDN(rst_n), .Q(n368)
         );
  DFCNQD1 clk_r_REG43_S5 ( .D(wa_q[0]), .CP(net150), .CDN(rst_n), .Q(n367) );
  DFCNQD1 clk_r_REG34_S5 ( .D(wa_q[1]), .CP(net150), .CDN(rst_n), .Q(n366) );
  DFCNQD1 clk_r_REG24_S5 ( .D(wa_q[2]), .CP(net150), .CDN(rst_n), .Q(n365) );
  DFCNQD1 clk_r_REG16_S5 ( .D(wa_q[3]), .CP(net150), .CDN(rst_n), .Q(n364) );
  DFCNQD1 clk_r_REG84_S5 ( .D(wa_q[4]), .CP(net150), .CDN(rst_n), .Q(n363) );
  DFCNQD1 clk_r_REG83_S5 ( .D(wa_q[5]), .CP(net150), .CDN(rst_n), .Q(n362) );
  DFCNQD1 clk_r_REG82_S5 ( .D(wa_q[6]), .CP(net150), .CDN(rst_n), .Q(n361) );
  DFCNQD1 clk_r_REG81_S5 ( .D(wa_q[7]), .CP(net150), .CDN(rst_n), .Q(n360) );
  DFCNQD1 clk_r_REG80_S5 ( .D(wa_q[8]), .CP(net150), .CDN(rst_n), .Q(n359) );
  DFCNQD1 clk_r_REG79_S5 ( .D(wa_q[9]), .CP(net150), .CDN(rst_n), .Q(n358) );
  DFCNQD1 clk_r_REG78_S5 ( .D(wa_q[10]), .CP(net150), .CDN(rst_n), .Q(n357) );
  DFCNQD1 clk_r_REG77_S5 ( .D(wa_q[11]), .CP(net150), .CDN(rst_n), .Q(n356) );
  DFCNQD1 clk_r_REG69_S5 ( .D(wa_q[12]), .CP(net150), .CDN(rst_n), .Q(n355) );
  DFCNQD1 clk_r_REG61_S5 ( .D(wa_q[13]), .CP(net150), .CDN(rst_n), .Q(n354) );
  DFCNQD1 clk_r_REG53_S5 ( .D(wa_q[14]), .CP(net150), .CDN(rst_n), .Q(n353) );
  DFCNQD1 clk_r_REG52_S5 ( .D(wa_q[15]), .CP(net150), .CDN(rst_n), .Q(n352) );
  DFCNQD1 clk_r_REG96_S5 ( .D(wa_q[16]), .CP(net150), .CDN(rst_n), .Q(n351) );
  DFCNQD1 clk_r_REG95_S5 ( .D(wa_q[17]), .CP(net150), .CDN(rst_n), .Q(n350) );
  DFCNQD1 clk_r_REG94_S5 ( .D(wa_q[18]), .CP(net150), .CDN(rst_n), .Q(n349) );
  DFCNQD1 clk_r_REG93_S5 ( .D(wa_q[19]), .CP(net150), .CDN(rst_n), .Q(n348) );
  DFCNQD1 clk_r_REG92_S5 ( .D(wa_q[20]), .CP(net150), .CDN(rst_n), .Q(n347) );
  DFCNQD1 clk_r_REG91_S5 ( .D(wa_q[21]), .CP(net150), .CDN(rst_n), .Q(n346) );
  DFCNQD1 clk_r_REG90_S5 ( .D(wa_q[22]), .CP(net150), .CDN(rst_n), .Q(n345) );
  DFCNQD1 clk_r_REG89_S5 ( .D(wa_q[23]), .CP(net150), .CDN(rst_n), .Q(n344) );
  DFCNQD1 clk_r_REG88_S5 ( .D(wa_q[24]), .CP(net150), .CDN(rst_n), .Q(n343) );
  DFCNQD1 clk_r_REG87_S5 ( .D(wa_q[25]), .CP(net150), .CDN(rst_n), .Q(n342) );
  DFCNQD1 clk_r_REG86_S5 ( .D(wa_q[26]), .CP(net150), .CDN(rst_n), .Q(n341) );
  DFCNQD1 clk_r_REG85_S5 ( .D(wa_q[27]), .CP(net150), .CDN(rst_n), .Q(n340) );
  DFCNQD1 clk_r_REG108_S5 ( .D(wa_q[28]), .CP(net150), .CDN(rst_n), .Q(n339)
         );
  DFCNQD1 clk_r_REG107_S5 ( .D(wa_q[29]), .CP(net150), .CDN(rst_n), .Q(n338)
         );
  DFCNQD1 clk_r_REG106_S5 ( .D(wa_q[30]), .CP(net150), .CDN(rst_n), .Q(n337)
         );
  DFCNQD1 clk_r_REG105_S5 ( .D(wa_q[31]), .CP(net150), .CDN(rst_n), .Q(n336)
         );
  DFCNQD1 clk_r_REG104_S5 ( .D(wa_q[32]), .CP(net150), .CDN(rst_n), .Q(n335)
         );
  DFCNQD1 clk_r_REG103_S5 ( .D(wa_q[33]), .CP(net150), .CDN(rst_n), .Q(n334)
         );
  DFCNQD1 clk_r_REG102_S5 ( .D(wa_q[34]), .CP(net150), .CDN(rst_n), .Q(n333)
         );
  DFCNQD1 clk_r_REG101_S5 ( .D(wa_q[35]), .CP(net150), .CDN(rst_n), .Q(n332)
         );
  DFCNQD1 clk_r_REG100_S5 ( .D(wa_q[36]), .CP(net150), .CDN(rst_n), .Q(n331)
         );
  DFCNQD1 clk_r_REG99_S5 ( .D(wa_q[37]), .CP(net150), .CDN(rst_n), .Q(n330) );
  DFCNQD1 clk_r_REG98_S5 ( .D(wa_q[38]), .CP(net150), .CDN(rst_n), .Q(n329) );
  DFCNQD1 clk_r_REG97_S5 ( .D(wa_q[39]), .CP(net150), .CDN(rst_n), .Q(n328) );
  DFCNQD1 clk_r_REG120_S5 ( .D(wa_q[40]), .CP(net150), .CDN(rst_n), .Q(n327)
         );
  DFCNQD1 clk_r_REG119_S5 ( .D(wa_q[41]), .CP(net150), .CDN(rst_n), .Q(n326)
         );
  DFCNQD1 clk_r_REG118_S5 ( .D(wa_q[42]), .CP(net150), .CDN(rst_n), .Q(n325)
         );
  DFCNQD1 clk_r_REG117_S5 ( .D(wa_q[43]), .CP(net150), .CDN(rst_n), .Q(n324)
         );
  DFCNQD1 clk_r_REG116_S5 ( .D(wa_q[44]), .CP(net150), .CDN(rst_n), .Q(n323)
         );
  DFCNQD1 clk_r_REG115_S5 ( .D(wa_q[45]), .CP(net150), .CDN(rst_n), .Q(n322)
         );
  DFCNQD1 clk_r_REG114_S5 ( .D(wa_q[46]), .CP(net150), .CDN(rst_n), .Q(n321)
         );
  DFCNQD1 clk_r_REG113_S5 ( .D(wa_q[47]), .CP(net150), .CDN(rst_n), .Q(n320)
         );
  DFCNQD1 clk_r_REG112_S5 ( .D(wa_q[48]), .CP(net150), .CDN(rst_n), .Q(n319)
         );
  DFCNQD1 clk_r_REG111_S5 ( .D(wa_q[49]), .CP(net150), .CDN(rst_n), .Q(n318)
         );
  DFCNQD1 clk_r_REG110_S5 ( .D(wa_q[50]), .CP(net150), .CDN(rst_n), .Q(n317)
         );
  DFCNQD1 clk_r_REG109_S5 ( .D(wa_q[51]), .CP(net150), .CDN(rst_n), .Q(n316)
         );
  DFCNQD1 clk_r_REG131_S5 ( .D(wa_q[52]), .CP(net150), .CDN(rst_n), .Q(n315)
         );
  DFCNQD1 clk_r_REG130_S5 ( .D(wa_q[53]), .CP(net150), .CDN(rst_n), .Q(n314)
         );
  DFCNQD1 clk_r_REG129_S5 ( .D(wa_q[54]), .CP(net150), .CDN(rst_n), .Q(n313)
         );
  DFCNQD1 clk_r_REG128_S5 ( .D(wa_q[55]), .CP(net150), .CDN(rst_n), .Q(n312)
         );
  DFCNQD1 clk_r_REG127_S5 ( .D(wa_q[56]), .CP(net150), .CDN(rst_n), .Q(n311)
         );
  DFCNQD1 clk_r_REG126_S5 ( .D(wa_q[57]), .CP(net150), .CDN(rst_n), .Q(n310)
         );
  DFCNQD1 clk_r_REG125_S5 ( .D(wa_q[58]), .CP(net150), .CDN(rst_n), .Q(n309)
         );
  DFCNQD1 clk_r_REG124_S5 ( .D(wa_q[59]), .CP(net150), .CDN(rst_n), .Q(n308)
         );
  DFCNQD1 clk_r_REG123_S5 ( .D(wa_q[60]), .CP(net150), .CDN(rst_n), .Q(n307)
         );
  DFCNQD1 clk_r_REG122_S5 ( .D(wa_q[61]), .CP(net150), .CDN(rst_n), .Q(n306)
         );
  DFCNQD1 clk_r_REG121_S5 ( .D(wa_q[62]), .CP(net150), .CDN(rst_n), .Q(n305)
         );
  DFCNQD1 clk_r_REG0_S1 ( .D(wa_q[63]), .CP(net150), .CDN(rst_n), .Q(n304) );
  DFCNQD1 clk_r_REG134_S4 ( .D(ocnt_q[1]), .CP(net201), .CDN(rst_n), .Q(n303)
         );
  DFCNQD1 clk_r_REG10_S3 ( .D(n382), .CP(net161), .CDN(rst_n), .Q(n301) );
  DFCNQD1 clk_r_REG136_S5 ( .D(bptr_q[1]), .CP(net150), .CDN(rst_n), .Q(n244)
         );
  DFCNQD1 clk_r_REG14_S3 ( .D(prem_q[4]), .CP(net161), .CDN(rst_n), .Q(n243)
         );
  DFCNQD1 clk_r_REG32_S6 ( .D(prem_q[2]), .CP(net161), .CDN(rst_n), .Q(n242)
         );
  DFCNQD1 clk_r_REG17_S6 ( .D(cur_byte[3]), .CP(net196), .CDN(rst_n), .Q(n273)
         );
  DFCNQD1 clk_r_REG44_S6 ( .D(cur_byte[0]), .CP(net196), .CDN(rst_n), .Q(n266)
         );
  DFCNQD1 clk_r_REG35_S6 ( .D(cur_byte[1]), .CP(net196), .CDN(rst_n), .Q(n259)
         );
  DFCNQD1 clk_r_REG25_S6 ( .D(cur_byte[2]), .CP(net196), .CDN(rst_n), .Q(n252)
         );
  DFCNQD1 clk_r_REG62_S6 ( .D(cur_byte[5]), .CP(net196), .CDN(rst_n), .Q(n245)
         );
  DFCNQD1 clk_r_REG73_S6 ( .D(cur_byte[4]), .CP(net181), .CDN(rst_n), .Q(n283)
         );
  DFCNQD1 clk_r_REG71_S6 ( .D(cur_byte[4]), .CP(net191), .CDN(rst_n), .Q(n281)
         );
  DFCNQD1 clk_r_REG20_S6 ( .D(cur_byte[3]), .CP(net181), .CDN(rst_n), .Q(n276)
         );
  DFCNQD1 clk_r_REG18_S6 ( .D(cur_byte[3]), .CP(net191), .CDN(rst_n), .Q(n274)
         );
  DFCNQD1 clk_r_REG47_S6 ( .D(cur_byte[0]), .CP(net181), .CDN(rst_n), .Q(n269)
         );
  DFCNQD1 clk_r_REG45_S6 ( .D(cur_byte[0]), .CP(net191), .CDN(rst_n), .Q(n267)
         );
  DFCNQD1 clk_r_REG38_S6 ( .D(cur_byte[1]), .CP(net181), .CDN(rst_n), .Q(n262)
         );
  DFCNQD1 clk_r_REG36_S6 ( .D(cur_byte[1]), .CP(net191), .CDN(rst_n), .Q(n260)
         );
  DFCNQD1 clk_r_REG28_S6 ( .D(cur_byte[2]), .CP(net181), .CDN(rst_n), .Q(n255)
         );
  DFCNQD1 clk_r_REG26_S6 ( .D(cur_byte[2]), .CP(net191), .CDN(rst_n), .Q(n253)
         );
  DFCNQD1 clk_r_REG65_S6 ( .D(cur_byte[5]), .CP(net181), .CDN(rst_n), .Q(n248)
         );
  DFCNQD1 clk_r_REG63_S6 ( .D(cur_byte[5]), .CP(net191), .CDN(rst_n), .Q(n246)
         );
  DFCNQD1 clk_r_REG4_S2 ( .D(cur_byte[7]), .CP(net181), .CDN(rst_n), .Q(n297)
         );
  DFCNQD1 clk_r_REG2_S2 ( .D(cur_byte[7]), .CP(net191), .CDN(rst_n), .Q(n295)
         );
  DFCNQD1 clk_r_REG57_S6 ( .D(cur_byte[6]), .CP(net181), .CDN(rst_n), .Q(n290)
         );
  DFCNQD1 clk_r_REG55_S6 ( .D(cur_byte[6]), .CP(net191), .CDN(rst_n), .Q(n288)
         );
  DFCNQD1 clk_r_REG7_S2 ( .D(cur_byte[7]), .CP(net166), .CDN(rst_n), .Q(n300)
         );
  DFCNQD1 clk_r_REG60_S6 ( .D(cur_byte[6]), .CP(net166), .CDN(rst_n), .Q(n293)
         );
  DFCNQD1 clk_r_REG76_S6 ( .D(cur_byte[4]), .CP(net166), .CDN(rst_n), .Q(n286)
         );
  DFCNQD1 clk_r_REG23_S6 ( .D(cur_byte[3]), .CP(net166), .CDN(rst_n), .Q(n279)
         );
  DFCNQD1 clk_r_REG50_S6 ( .D(cur_byte[0]), .CP(net166), .CDN(rst_n), .Q(n272)
         );
  DFCNQD1 clk_r_REG41_S6 ( .D(cur_byte[1]), .CP(net166), .CDN(rst_n), .Q(n265)
         );
  DFCNQD1 clk_r_REG31_S6 ( .D(cur_byte[2]), .CP(net166), .CDN(rst_n), .Q(n258)
         );
  DFCNQD1 clk_r_REG68_S6 ( .D(cur_byte[5]), .CP(net166), .CDN(rst_n), .Q(n251)
         );
  DFCNQD1 clk_r_REG6_S2 ( .D(cur_byte[7]), .CP(net171), .CDN(rst_n), .Q(n299)
         );
  DFCNQD1 clk_r_REG5_S2 ( .D(cur_byte[7]), .CP(net176), .CDN(rst_n), .Q(n298)
         );
  DFCNQD1 clk_r_REG3_S2 ( .D(cur_byte[7]), .CP(net186), .CDN(rst_n), .Q(n296)
         );
  DFCNQD1 clk_r_REG59_S6 ( .D(cur_byte[6]), .CP(net171), .CDN(rst_n), .Q(n292)
         );
  DFCNQD1 clk_r_REG58_S6 ( .D(cur_byte[6]), .CP(net176), .CDN(rst_n), .Q(n291)
         );
  DFCNQD1 clk_r_REG56_S6 ( .D(cur_byte[6]), .CP(net186), .CDN(rst_n), .Q(n289)
         );
  DFCNQD1 clk_r_REG75_S6 ( .D(cur_byte[4]), .CP(net171), .CDN(rst_n), .Q(n285)
         );
  DFCNQD1 clk_r_REG74_S6 ( .D(cur_byte[4]), .CP(net176), .CDN(rst_n), .Q(n284)
         );
  DFCNQD1 clk_r_REG72_S6 ( .D(cur_byte[4]), .CP(net186), .CDN(rst_n), .Q(n282)
         );
  DFCNQD1 clk_r_REG70_S6 ( .D(cur_byte[4]), .CP(net196), .CDN(rst_n), .Q(n280)
         );
  DFCNQD1 clk_r_REG22_S6 ( .D(cur_byte[3]), .CP(net171), .CDN(rst_n), .Q(n278)
         );
  DFCNQD1 clk_r_REG21_S6 ( .D(cur_byte[3]), .CP(net176), .CDN(rst_n), .Q(n277)
         );
  DFCNQD1 clk_r_REG19_S6 ( .D(cur_byte[3]), .CP(net186), .CDN(rst_n), .Q(n275)
         );
  DFCNQD1 clk_r_REG49_S6 ( .D(cur_byte[0]), .CP(net171), .CDN(rst_n), .Q(n271)
         );
  DFCNQD1 clk_r_REG48_S6 ( .D(cur_byte[0]), .CP(net176), .CDN(rst_n), .Q(n270)
         );
  DFCNQD1 clk_r_REG46_S6 ( .D(cur_byte[0]), .CP(net186), .CDN(rst_n), .Q(n268)
         );
  DFCNQD1 clk_r_REG40_S6 ( .D(cur_byte[1]), .CP(net171), .CDN(rst_n), .Q(n264)
         );
  DFCNQD1 clk_r_REG39_S6 ( .D(cur_byte[1]), .CP(net176), .CDN(rst_n), .Q(n263)
         );
  DFCNQD1 clk_r_REG37_S6 ( .D(cur_byte[1]), .CP(net186), .CDN(rst_n), .Q(n261)
         );
  DFCNQD1 clk_r_REG30_S6 ( .D(cur_byte[2]), .CP(net171), .CDN(rst_n), .Q(n257)
         );
  DFCNQD1 clk_r_REG29_S6 ( .D(cur_byte[2]), .CP(net176), .CDN(rst_n), .Q(n256)
         );
  DFCNQD1 clk_r_REG27_S6 ( .D(cur_byte[2]), .CP(net186), .CDN(rst_n), .Q(n254)
         );
  DFCNQD1 clk_r_REG67_S6 ( .D(cur_byte[5]), .CP(net171), .CDN(rst_n), .Q(n250)
         );
  DFCNQD1 clk_r_REG66_S6 ( .D(cur_byte[5]), .CP(net176), .CDN(rst_n), .Q(n249)
         );
  DFCNQD1 clk_r_REG64_S6 ( .D(cur_byte[5]), .CP(net186), .CDN(rst_n), .Q(n247)
         );
  DFCNQD1 clk_r_REG1_S2 ( .D(cur_byte[7]), .CP(net196), .CDN(rst_n), .Q(n294)
         );
  DFCNQD1 clk_r_REG54_S6 ( .D(cur_byte[6]), .CP(net196), .CDN(rst_n), .Q(n287)
         );
  DFSNQD1 clk_r_REG15_S4 ( .D(n241), .CP(clk), .SDN(rst_n), .Q(n380) );
  DFCNQD1 clk_r_REG133_S4 ( .D(ocnt_q[2]), .CP(net201), .CDN(rst_n), .Q(n302)
         );
  INVD0 U285 ( .I(m_tvalid), .ZN(n194) );
  ND4D0 U286 ( .A1(n129), .A2(n128), .A3(n127), .A4(n126), .ZN(cur_byte[5]) );
  NR2XD1 U287 ( .A1(n216), .A2(n164), .ZN(m_tdata[3]) );
  NR2D0 U288 ( .A1(n373), .A2(n179), .ZN(n178) );
  CKAN2D0 U289 ( .A1(n197), .A2(n214), .Z(n195) );
  INR2D0 U290 ( .A1(n231), .B1(n232), .ZN(N384) );
  INR2D0 U291 ( .A1(n233), .B1(n232), .ZN(N386) );
  OR2D0 U292 ( .A1(n187), .A2(n194), .Z(n385) );
  NR2XD1 U293 ( .A1(n217), .A2(n164), .ZN(m_tdata[2]) );
  NR2XD1 U294 ( .A1(n218), .A2(n164), .ZN(m_tdata[5]) );
  NR2XD1 U295 ( .A1(n227), .A2(n164), .ZN(m_tdata[0]) );
  NR2XD1 U296 ( .A1(n215), .A2(n164), .ZN(m_tdata[1]) );
  OR2D0 U297 ( .A1(n193), .A2(n194), .Z(n387) );
  NR2XD1 U298 ( .A1(n228), .A2(n164), .ZN(m_tdata[4]) );
  NR2XD1 U299 ( .A1(n220), .A2(n164), .ZN(m_tdata[6]) );
  NR2XD1 U300 ( .A1(n189), .A2(n194), .ZN(m_tkeep[5]) );
  NR2XD1 U301 ( .A1(n236), .A2(n194), .ZN(m_tkeep[4]) );
  OR2D0 U302 ( .A1(n191), .A2(n194), .Z(n386) );
  NR2XD1 U303 ( .A1(n219), .A2(n164), .ZN(m_tdata[7]) );
  INR2XD1 U304 ( .A1(n225), .B1(n194), .ZN(m_tkeep[2]) );
  BUFFD1 U305 ( .I(n171), .Z(n170) );
  AOI21D2 U306 ( .A1(n234), .A2(n163), .B(n174), .ZN(n169) );
  NR2XD0 U307 ( .A1(n193), .A2(n190), .ZN(n237) );
  NR2XD1 U308 ( .A1(n166), .A2(n165), .ZN(m_tlast) );
  INVD1 U309 ( .I(cur_byte[0]), .ZN(n227) );
  ND4D1 U310 ( .A1(n141), .A2(n140), .A3(n139), .A4(n138), .ZN(cur_byte[1]) );
  AO222D1 U311 ( .A1(n210), .A2(n242), .B1(cur_byte[2]), .B2(n207), .C1(n201), 
        .C2(n375), .Z(prem_q[2]) );
  ND4D1 U312 ( .A1(n133), .A2(n132), .A3(n131), .A4(n130), .ZN(cur_byte[2]) );
  AOI22D0 U313 ( .A1(n172), .A2(n363), .B1(n157), .B2(n355), .ZN(n118) );
  INVD0 U314 ( .I(n211), .ZN(n197) );
  AOI22D0 U315 ( .A1(n172), .A2(n367), .B1(n157), .B2(n359), .ZN(n134) );
  IAO21D0 U316 ( .A1(n145), .A2(n197), .B(n202), .ZN(n204) );
  CKND2D0 U317 ( .A1(n177), .A2(n146), .ZN(n214) );
  INVD0 U318 ( .I(n214), .ZN(n207) );
  ND4D0 U319 ( .A1(n121), .A2(n120), .A3(n119), .A4(n118), .ZN(cur_byte[4]) );
  AOI22D0 U320 ( .A1(n154), .A2(n323), .B1(n178), .B2(n331), .ZN(n120) );
  AOI22D0 U321 ( .A1(n156), .A2(n339), .B1(n155), .B2(n347), .ZN(n119) );
  AOI221D0 U322 ( .A1(n143), .A2(n218), .B1(n142), .B2(cur_byte[5]), .C(n378), 
        .ZN(n146) );
  ND4D0 U323 ( .A1(n143), .A2(n217), .A3(n227), .A4(n215), .ZN(n142) );
  NR2D0 U324 ( .A1(cur_byte[4]), .A2(cur_byte[3]), .ZN(n143) );
  INVD0 U325 ( .I(n189), .ZN(n221) );
  NR2D0 U326 ( .A1(n376), .A2(n221), .ZN(n187) );
  CKND2D0 U327 ( .A1(n186), .A2(n194), .ZN(n232) );
  AOI22D0 U328 ( .A1(n172), .A2(n361), .B1(n157), .B2(n353), .ZN(n148) );
  AOI22D0 U329 ( .A1(n172), .A2(n360), .B1(n157), .B2(n352), .ZN(n158) );
  AOI22D0 U330 ( .A1(n172), .A2(n362), .B1(n157), .B2(n354), .ZN(n126) );
  AOI22D0 U331 ( .A1(n172), .A2(n365), .B1(n157), .B2(n357), .ZN(n130) );
  AOI22D0 U332 ( .A1(n172), .A2(n366), .B1(n157), .B2(n358), .ZN(n138) );
  AOI22D0 U333 ( .A1(n172), .A2(n364), .B1(n157), .B2(n356), .ZN(n122) );
  INVD0 U334 ( .I(cur_byte[3]), .ZN(n216) );
  AOI21D0 U335 ( .A1(n370), .A2(n211), .B(n202), .ZN(n200) );
  NR2D0 U336 ( .A1(n370), .A2(n205), .ZN(n201) );
  OR3D0 U337 ( .A1(n144), .A2(n165), .A3(n301), .Z(n181) );
  INVD0 U338 ( .I(s_tvalid), .ZN(n174) );
  ND4D0 U339 ( .A1(n151), .A2(n150), .A3(n149), .A4(n148), .ZN(cur_byte[6]) );
  AOI22D0 U340 ( .A1(n153), .A2(n305), .B1(n152), .B2(n313), .ZN(n151) );
  AOI22D0 U341 ( .A1(n156), .A2(n337), .B1(n155), .B2(n345), .ZN(n149) );
  AOI22D0 U342 ( .A1(n154), .A2(n321), .B1(n178), .B2(n329), .ZN(n150) );
  ND4D0 U343 ( .A1(n161), .A2(n160), .A3(n159), .A4(n158), .ZN(cur_byte[7]) );
  AOI22D0 U344 ( .A1(n153), .A2(n304), .B1(n152), .B2(n312), .ZN(n161) );
  AOI22D0 U345 ( .A1(n156), .A2(n336), .B1(n155), .B2(n344), .ZN(n159) );
  AOI22D0 U346 ( .A1(n154), .A2(n320), .B1(n178), .B2(n328), .ZN(n160) );
  AOI22D0 U347 ( .A1(n153), .A2(n306), .B1(n152), .B2(n314), .ZN(n129) );
  AOI22D0 U348 ( .A1(n156), .A2(n338), .B1(n155), .B2(n346), .ZN(n127) );
  AOI22D0 U349 ( .A1(n154), .A2(n322), .B1(n178), .B2(n330), .ZN(n128) );
  AOI22D0 U350 ( .A1(n153), .A2(n309), .B1(n152), .B2(n317), .ZN(n133) );
  AOI22D0 U351 ( .A1(n154), .A2(n325), .B1(n178), .B2(n333), .ZN(n132) );
  AOI22D0 U352 ( .A1(n156), .A2(n341), .B1(n155), .B2(n349), .ZN(n131) );
  AOI22D0 U353 ( .A1(n153), .A2(n310), .B1(n152), .B2(n318), .ZN(n141) );
  AOI22D0 U354 ( .A1(n154), .A2(n326), .B1(n178), .B2(n334), .ZN(n140) );
  AOI22D0 U355 ( .A1(n156), .A2(n342), .B1(n155), .B2(n350), .ZN(n139) );
  ND4D0 U356 ( .A1(n137), .A2(n136), .A3(n135), .A4(n134), .ZN(cur_byte[0]) );
  AOI22D0 U357 ( .A1(n153), .A2(n311), .B1(n152), .B2(n319), .ZN(n137) );
  AOI22D0 U358 ( .A1(n156), .A2(n343), .B1(n155), .B2(n351), .ZN(n135) );
  ND4D0 U359 ( .A1(n125), .A2(n124), .A3(n123), .A4(n122), .ZN(cur_byte[3]) );
  AOI22D0 U360 ( .A1(n153), .A2(n308), .B1(n152), .B2(n316), .ZN(n125) );
  AOI22D0 U361 ( .A1(n154), .A2(n324), .B1(n178), .B2(n332), .ZN(n124) );
  AOI22D0 U362 ( .A1(n156), .A2(n340), .B1(n155), .B2(n348), .ZN(n123) );
  CKND2D0 U363 ( .A1(n207), .A2(cur_byte[4]), .ZN(n147) );
  ND3D0 U364 ( .A1(n172), .A2(n374), .A3(n174), .ZN(n144) );
  CKND2D0 U365 ( .A1(n193), .A2(n192), .ZN(n225) );
  CKND2D0 U366 ( .A1(n191), .A2(n239), .ZN(n223) );
  CKND2D0 U367 ( .A1(n190), .A2(n196), .ZN(n229) );
  INVD0 U368 ( .I(n223), .ZN(n236) );
  NR2D0 U369 ( .A1(n117), .A2(n183), .ZN(n155) );
  NR2D0 U370 ( .A1(n373), .A2(n183), .ZN(n152) );
  IND2D0 U371 ( .A1(n372), .B1(n244), .ZN(n182) );
  IND2D0 U372 ( .A1(n244), .B1(n372), .ZN(n183) );
  CKND2D0 U373 ( .A1(n172), .A2(n176), .ZN(n163) );
  NR2D0 U374 ( .A1(n301), .A2(n205), .ZN(n211) );
  OAI21D0 U375 ( .A1(n199), .A2(n197), .B(n200), .ZN(n210) );
  CKND2D0 U376 ( .A1(n186), .A2(n144), .ZN(n205) );
  CKND2D0 U377 ( .A1(n211), .A2(n145), .ZN(n213) );
  INVD0 U378 ( .I(n371), .ZN(n199) );
  NR2D0 U379 ( .A1(n117), .A2(n179), .ZN(n172) );
  NR2D0 U380 ( .A1(n186), .A2(n177), .ZN(n230) );
  INVD0 U381 ( .I(n234), .ZN(n175) );
  INVD0 U382 ( .I(n177), .ZN(n173) );
  NR2D0 U383 ( .A1(n188), .A2(n232), .ZN(N389) );
  NR2D0 U384 ( .A1(n222), .A2(n232), .ZN(N388) );
  NR2D0 U385 ( .A1(n224), .A2(n232), .ZN(N387) );
  NR2D0 U386 ( .A1(n226), .A2(n232), .ZN(N385) );
  NR2D0 U387 ( .A1(n229), .A2(n232), .ZN(N383) );
  CKND2D0 U388 ( .A1(n383), .A2(prem_q[0]), .ZN(n235) );
  OAI211D0 U389 ( .A1(n216), .A2(n214), .B(n213), .C(n212), .ZN(prem_q[3]) );
  AOI32D0 U390 ( .A1(n242), .A2(n368), .A3(n211), .B1(n210), .B2(n368), .ZN(
        n212) );
  OAI31D0 U391 ( .A1(n243), .A2(n369), .A3(n213), .B(n209), .ZN(prem_q[5]) );
  AOI22D0 U392 ( .A1(n369), .A2(n208), .B1(n207), .B2(cur_byte[5]), .ZN(n209)
         );
  OAI21D0 U393 ( .A1(n206), .A2(n205), .B(n204), .ZN(n208) );
  OAI21D0 U394 ( .A1(n227), .A2(n214), .B(n203), .ZN(prem_q[0]) );
  AOI21D0 U395 ( .A1(n370), .A2(n202), .B(n201), .ZN(n203) );
  AOI22D0 U396 ( .A1(n207), .A2(cur_byte[1]), .B1(n201), .B2(n199), .ZN(n198)
         );
  OAI21D0 U397 ( .A1(n372), .A2(n230), .B(n181), .ZN(bptr_q[0]) );
  OAI21D0 U398 ( .A1(n230), .A2(n180), .B(n181), .ZN(bptr_q[2]) );
  AO31D0 U399 ( .A1(s_tvalid), .A2(n172), .A3(s_tlast), .B(n175), .Z(n384) );
  NR2D0 U400 ( .A1(prem_q[2]), .A2(prem_q[1]), .ZN(n383) );
  AOI21D0 U401 ( .A1(n175), .A2(n174), .B(N375), .ZN(n109) );
  IND2D0 U402 ( .A1(m_tlast), .B1(n234), .ZN(state_q_0_) );
  CKND2D0 U403 ( .A1(n185), .A2(n184), .ZN(n381) );
  NR2D0 U404 ( .A1(n379), .A2(n173), .ZN(N375) );
  INVD0 U405 ( .I(cur_byte[1]), .ZN(n215) );
  INVD1 U406 ( .I(n387), .ZN(m_tkeep[1]) );
  INVD1 U407 ( .I(n386), .ZN(m_tkeep[3]) );
  INVD1 U408 ( .I(n385), .ZN(m_tkeep[6]) );
  INVD0 U409 ( .I(cur_byte[2]), .ZN(n217) );
  INVD0 U410 ( .I(cur_byte[5]), .ZN(n218) );
  INVD0 U411 ( .I(cur_byte[4]), .ZN(n228) );
  NR2XD1 U412 ( .A1(n165), .A2(n164), .ZN(m_tkeep[0]) );
  INVD0 U413 ( .I(n237), .ZN(n164) );
  INVD0 U414 ( .I(cur_byte[6]), .ZN(n220) );
  INVD0 U415 ( .I(n186), .ZN(n165) );
  NR2D0 U416 ( .A1(n117), .A2(n182), .ZN(n157) );
  NR2D0 U417 ( .A1(n373), .A2(n182), .ZN(n154) );
  INVD0 U418 ( .I(n373), .ZN(n117) );
  NR2D0 U419 ( .A1(n167), .A2(n162), .ZN(n177) );
  AOI22D0 U420 ( .A1(n153), .A2(n307), .B1(n152), .B2(n315), .ZN(n121) );
  AOI22D0 U421 ( .A1(n154), .A2(n327), .B1(n178), .B2(n335), .ZN(n136) );
  INVD0 U422 ( .I(n301), .ZN(n166) );
  INVD0 U423 ( .I(n193), .ZN(n196) );
  INVD0 U424 ( .I(cur_byte[7]), .ZN(n219) );
  OAI21D0 U425 ( .A1(n200), .A2(n199), .B(n198), .ZN(prem_q[1]) );
  TIEL U426 ( .ZN(n_Logic0_) );
  CKND2D0 U427 ( .A1(n302), .A2(n303), .ZN(n193) );
  INVD0 U428 ( .I(n376), .ZN(n190) );
  NR2D0 U429 ( .A1(n377), .A2(n380), .ZN(n186) );
  AOI21D2 U430 ( .A1(n166), .A2(n164), .B(n165), .ZN(m_tvalid) );
  INVD0 U431 ( .I(n302), .ZN(n191) );
  NR2D0 U432 ( .A1(n302), .A2(n303), .ZN(n189) );
  CKND2D0 U433 ( .A1(n303), .A2(n376), .ZN(n239) );
  NR3D0 U434 ( .A1(n373), .A2(n244), .A3(n372), .ZN(n153) );
  CKND2D0 U435 ( .A1(n244), .A2(n372), .ZN(n179) );
  NR3D0 U436 ( .A1(n244), .A2(n372), .A3(n117), .ZN(n156) );
  NR4D0 U437 ( .A1(n242), .A2(n371), .A3(n370), .A4(n368), .ZN(n145) );
  INVD0 U438 ( .I(n243), .ZN(n206) );
  INVD0 U439 ( .I(n380), .ZN(n167) );
  INVD0 U440 ( .I(n377), .ZN(n162) );
  OAI21D1 U441 ( .A1(n146), .A2(n173), .B(n181), .ZN(n202) );
  OAI221D0 U442 ( .A1(n243), .A2(n213), .B1(n206), .B2(n204), .C(n147), .ZN(
        prem_q[4]) );
  CKND2D0 U443 ( .A1(n380), .A2(n162), .ZN(n234) );
  OR2D1 U444 ( .A1(n172), .A2(n175), .Z(s_tready) );
  AOI222D0 U445 ( .A1(n167), .A2(n377), .B1(s_tvalid), .B2(n172), .C1(n380), 
        .C2(n162), .ZN(n171) );
  CKND2D0 U446 ( .A1(n167), .A2(n377), .ZN(n176) );
  AO22D0 U447 ( .A1(n357), .A2(n170), .B1(n169), .B2(s_tdata[10]), .Z(wa_q[10]) );
  AO22D0 U448 ( .A1(n364), .A2(n170), .B1(n169), .B2(s_tdata[3]), .Z(wa_q[3])
         );
  AO22D0 U449 ( .A1(n365), .A2(n170), .B1(n169), .B2(s_tdata[2]), .Z(wa_q[2])
         );
  AO22D0 U450 ( .A1(n362), .A2(n170), .B1(n169), .B2(s_tdata[5]), .Z(wa_q[5])
         );
  AO22D0 U451 ( .A1(n361), .A2(n170), .B1(n169), .B2(s_tdata[6]), .Z(wa_q[6])
         );
  AO22D0 U452 ( .A1(n360), .A2(n170), .B1(n169), .B2(s_tdata[7]), .Z(wa_q[7])
         );
  AO22D0 U453 ( .A1(n359), .A2(n170), .B1(n169), .B2(s_tdata[8]), .Z(wa_q[8])
         );
  AO22D0 U454 ( .A1(n358), .A2(n170), .B1(n169), .B2(s_tdata[9]), .Z(wa_q[9])
         );
  AO22D0 U455 ( .A1(n363), .A2(n170), .B1(n169), .B2(s_tdata[4]), .Z(wa_q[4])
         );
  AO22D0 U456 ( .A1(n337), .A2(n170), .B1(n169), .B2(s_tdata[30]), .Z(wa_q[30]) );
  AO22D0 U457 ( .A1(n336), .A2(n170), .B1(n169), .B2(s_tdata[31]), .Z(wa_q[31]) );
  AO22D0 U458 ( .A1(n312), .A2(n170), .B1(n169), .B2(s_tdata[55]), .Z(wa_q[55]) );
  AO22D0 U459 ( .A1(n335), .A2(n170), .B1(n169), .B2(s_tdata[32]), .Z(wa_q[32]) );
  AO22D0 U460 ( .A1(n327), .A2(n170), .B1(n169), .B2(s_tdata[40]), .Z(wa_q[40]) );
  AO22D0 U461 ( .A1(n313), .A2(n170), .B1(n169), .B2(s_tdata[54]), .Z(wa_q[54]) );
  AO22D0 U462 ( .A1(n351), .A2(n170), .B1(n169), .B2(s_tdata[16]), .Z(wa_q[16]) );
  AO22D0 U463 ( .A1(n350), .A2(n170), .B1(n169), .B2(s_tdata[17]), .Z(wa_q[17]) );
  AO22D0 U464 ( .A1(n324), .A2(n170), .B1(n169), .B2(s_tdata[43]), .Z(wa_q[43]) );
  AO22D0 U465 ( .A1(n348), .A2(n170), .B1(n169), .B2(s_tdata[19]), .Z(wa_q[19]) );
  AO22D0 U466 ( .A1(n347), .A2(n170), .B1(n169), .B2(s_tdata[20]), .Z(wa_q[20]) );
  AO22D0 U467 ( .A1(n346), .A2(n170), .B1(n169), .B2(s_tdata[21]), .Z(wa_q[21]) );
  AO22D0 U468 ( .A1(n345), .A2(n170), .B1(n169), .B2(s_tdata[22]), .Z(wa_q[22]) );
  AO22D0 U469 ( .A1(n318), .A2(n170), .B1(n169), .B2(s_tdata[49]), .Z(wa_q[49]) );
  AO22D0 U470 ( .A1(n317), .A2(n170), .B1(n169), .B2(s_tdata[50]), .Z(wa_q[50]) );
  AO22D0 U471 ( .A1(n320), .A2(n170), .B1(n169), .B2(s_tdata[47]), .Z(wa_q[47]) );
  AO22D0 U472 ( .A1(n319), .A2(n170), .B1(n169), .B2(s_tdata[48]), .Z(wa_q[48]) );
  AO22D0 U473 ( .A1(n344), .A2(n170), .B1(n169), .B2(s_tdata[23]), .Z(wa_q[23]) );
  AO22D0 U474 ( .A1(n343), .A2(n170), .B1(n169), .B2(s_tdata[24]), .Z(wa_q[24]) );
  AO22D0 U475 ( .A1(n342), .A2(n170), .B1(n169), .B2(s_tdata[25]), .Z(wa_q[25]) );
  AO22D0 U476 ( .A1(n341), .A2(n170), .B1(n169), .B2(s_tdata[26]), .Z(wa_q[26]) );
  AO22D0 U477 ( .A1(n340), .A2(n170), .B1(n169), .B2(s_tdata[27]), .Z(wa_q[27]) );
  AO22D0 U478 ( .A1(n339), .A2(n170), .B1(n169), .B2(s_tdata[28]), .Z(wa_q[28]) );
  AO22D0 U479 ( .A1(n323), .A2(n170), .B1(n169), .B2(s_tdata[44]), .Z(wa_q[44]) );
  AO22D0 U480 ( .A1(n338), .A2(n170), .B1(n169), .B2(s_tdata[29]), .Z(wa_q[29]) );
  AO22D0 U481 ( .A1(n326), .A2(n170), .B1(n169), .B2(s_tdata[41]), .Z(wa_q[41]) );
  AO22D0 U482 ( .A1(n314), .A2(n170), .B1(n169), .B2(s_tdata[53]), .Z(wa_q[53]) );
  AO22D0 U483 ( .A1(n322), .A2(n170), .B1(n169), .B2(s_tdata[45]), .Z(wa_q[45]) );
  CKMUX2D1 U484 ( .I0(n293), .I1(cur_byte[6]), .S(n187), .Z(m_tdata[62]) );
  CKMUX2D1 U485 ( .I0(n300), .I1(cur_byte[7]), .S(n187), .Z(m_tdata[63]) );
  CKND2D0 U486 ( .A1(n167), .A2(n166), .ZN(n168) );
  NR2D0 U487 ( .A1(n376), .A2(n168), .ZN(ocnt_q[0]) );
  OA21D0 U488 ( .A1(s_tvalid), .A2(n234), .B(n176), .Z(n108) );
  AO22D0 U489 ( .A1(n305), .A2(n171), .B1(n169), .B2(s_tdata[62]), .Z(wa_q[62]) );
  AO22D0 U490 ( .A1(n306), .A2(n171), .B1(n169), .B2(s_tdata[61]), .Z(wa_q[61]) );
  AO22D0 U491 ( .A1(n304), .A2(n171), .B1(n169), .B2(s_tdata[63]), .Z(wa_q[63]) );
  AO22D0 U492 ( .A1(n331), .A2(n170), .B1(n169), .B2(s_tdata[36]), .Z(wa_q[36]) );
  AO22D0 U493 ( .A1(n315), .A2(n170), .B1(n169), .B2(s_tdata[52]), .Z(wa_q[52]) );
  AO22D0 U494 ( .A1(n329), .A2(n170), .B1(n169), .B2(s_tdata[38]), .Z(wa_q[38]) );
  AO22D0 U495 ( .A1(n328), .A2(n170), .B1(n169), .B2(s_tdata[39]), .Z(wa_q[39]) );
  AO22D0 U496 ( .A1(n325), .A2(n170), .B1(n169), .B2(s_tdata[42]), .Z(wa_q[42]) );
  AO22D0 U497 ( .A1(n332), .A2(n170), .B1(n169), .B2(s_tdata[35]), .Z(wa_q[35]) );
  AO22D0 U498 ( .A1(n333), .A2(n170), .B1(n169), .B2(s_tdata[34]), .Z(wa_q[34]) );
  AO22D0 U499 ( .A1(n334), .A2(n170), .B1(n169), .B2(s_tdata[33]), .Z(wa_q[33]) );
  AO22D0 U500 ( .A1(n321), .A2(n170), .B1(n169), .B2(s_tdata[46]), .Z(wa_q[46]) );
  AO22D0 U501 ( .A1(n330), .A2(n170), .B1(n169), .B2(s_tdata[37]), .Z(wa_q[37]) );
  AO22D0 U502 ( .A1(n311), .A2(n170), .B1(n169), .B2(s_tdata[56]), .Z(wa_q[56]) );
  AO22D0 U503 ( .A1(n308), .A2(n170), .B1(n169), .B2(s_tdata[59]), .Z(wa_q[59]) );
  AO22D0 U504 ( .A1(n307), .A2(n170), .B1(n169), .B2(s_tdata[60]), .Z(wa_q[60]) );
  AO22D0 U505 ( .A1(n310), .A2(n170), .B1(n169), .B2(s_tdata[57]), .Z(wa_q[57]) );
  AO22D0 U506 ( .A1(n309), .A2(n170), .B1(n169), .B2(s_tdata[58]), .Z(wa_q[58]) );
  AO22D0 U507 ( .A1(n352), .A2(n171), .B1(n169), .B2(s_tdata[15]), .Z(wa_q[15]) );
  AO22D0 U508 ( .A1(n356), .A2(n171), .B1(n169), .B2(s_tdata[11]), .Z(wa_q[11]) );
  AO22D0 U509 ( .A1(n354), .A2(n171), .B1(n169), .B2(s_tdata[13]), .Z(wa_q[13]) );
  AO22D0 U510 ( .A1(n349), .A2(n171), .B1(n169), .B2(s_tdata[18]), .Z(wa_q[18]) );
  AO22D0 U511 ( .A1(n316), .A2(n171), .B1(n169), .B2(s_tdata[51]), .Z(wa_q[51]) );
  AO22D0 U512 ( .A1(n355), .A2(n171), .B1(n169), .B2(s_tdata[12]), .Z(wa_q[12]) );
  AO22D0 U513 ( .A1(n367), .A2(n171), .B1(n169), .B2(s_tdata[0]), .Z(wa_q[0])
         );
  AO22D0 U514 ( .A1(n366), .A2(n171), .B1(n169), .B2(s_tdata[1]), .Z(wa_q[1])
         );
  AO22D0 U515 ( .A1(n353), .A2(n171), .B1(n169), .B2(s_tdata[14]), .Z(wa_q[14]) );
  NR2D0 U516 ( .A1(n302), .A2(n239), .ZN(n233) );
  AO22D1 U517 ( .A1(n269), .A2(n302), .B1(n233), .B2(cur_byte[0]), .Z(
        m_tdata[32]) );
  AO22D1 U518 ( .A1(n302), .A2(n297), .B1(n233), .B2(cur_byte[7]), .Z(
        m_tdata[39]) );
  CKND2D0 U519 ( .A1(n302), .A2(n376), .ZN(n192) );
  NR2D0 U520 ( .A1(n303), .A2(n192), .ZN(n231) );
  AO22D1 U521 ( .A1(n267), .A2(n196), .B1(n231), .B2(cur_byte[0]), .Z(
        m_tdata[16]) );
  AO22D1 U522 ( .A1(n196), .A2(n295), .B1(n231), .B2(cur_byte[7]), .Z(
        m_tdata[23]) );
  AO22D1 U523 ( .A1(n196), .A2(n288), .B1(n231), .B2(cur_byte[6]), .Z(
        m_tdata[22]) );
  AO22D1 U524 ( .A1(n302), .A2(n290), .B1(n233), .B2(cur_byte[6]), .Z(
        m_tdata[38]) );
  AO22D1 U525 ( .A1(n274), .A2(n196), .B1(n231), .B2(cur_byte[3]), .Z(
        m_tdata[19]) );
  AO22D1 U526 ( .A1(n260), .A2(n196), .B1(n231), .B2(cur_byte[1]), .Z(
        m_tdata[17]) );
  AO22D1 U527 ( .A1(n262), .A2(n302), .B1(n233), .B2(cur_byte[1]), .Z(
        m_tdata[33]) );
  AO22D1 U528 ( .A1(n253), .A2(n196), .B1(n231), .B2(cur_byte[2]), .Z(
        m_tdata[18]) );
  AO22D1 U529 ( .A1(n255), .A2(n302), .B1(n233), .B2(cur_byte[2]), .Z(
        m_tdata[34]) );
  CKMUX2D1 U530 ( .I0(n251), .I1(cur_byte[5]), .S(n187), .Z(m_tdata[61]) );
  CKMUX2D1 U531 ( .I0(n265), .I1(cur_byte[1]), .S(n187), .Z(m_tdata[57]) );
  CKMUX2D1 U532 ( .I0(n258), .I1(cur_byte[2]), .S(n187), .Z(m_tdata[58]) );
  CKMUX2D1 U533 ( .I0(n279), .I1(cur_byte[3]), .S(n187), .Z(m_tdata[59]) );
  CKMUX2D1 U534 ( .I0(n272), .I1(cur_byte[0]), .S(n187), .Z(m_tdata[56]) );
  CKMUX2D1 U535 ( .I0(n286), .I1(cur_byte[4]), .S(n187), .Z(m_tdata[60]) );
  AO21D0 U536 ( .A1(n177), .A2(n379), .B(n186), .Z(n107) );
  CKAN2D0 U537 ( .A1(n109), .A2(n176), .Z(n110) );
  AOI21D0 U538 ( .A1(n373), .A2(n179), .B(n178), .ZN(n180) );
  AOI31D0 U539 ( .A1(n183), .A2(n182), .A3(n181), .B(n230), .ZN(bptr_q[1]) );
  NR4D0 U540 ( .A1(cur_byte[7]), .A2(cur_byte[2]), .A3(cur_byte[6]), .A4(
        cur_byte[4]), .ZN(n185) );
  NR4D0 U541 ( .A1(cur_byte[5]), .A2(cur_byte[3]), .A3(cur_byte[1]), .A4(
        cur_byte[0]), .ZN(n184) );
  INVD0 U542 ( .I(n187), .ZN(n188) );
  NR2D0 U543 ( .A1(n303), .A2(n376), .ZN(n238) );
  CKND2D0 U544 ( .A1(n302), .A2(n238), .ZN(n226) );
  CKND2D0 U545 ( .A1(n376), .A2(n189), .ZN(n222) );
  ND3D0 U546 ( .A1(n303), .A2(n191), .A3(n190), .ZN(n224) );
  IOA22D2 U547 ( .B1(n229), .B2(n216), .A1(n273), .A2(n237), .ZN(m_tdata[11])
         );
  IOA22D2 U548 ( .B1(n229), .B2(n215), .A1(n259), .A2(n237), .ZN(m_tdata[9])
         );
  IOA22D2 U549 ( .B1(n229), .B2(n217), .A1(n252), .A2(n237), .ZN(m_tdata[10])
         );
  IOA22D2 U550 ( .B1(n229), .B2(n218), .A1(n245), .A2(n237), .ZN(m_tdata[13])
         );
  IOA22D2 U551 ( .B1(n229), .B2(n227), .A1(n266), .A2(n237), .ZN(m_tdata[8])
         );
  INVD1 U552 ( .I(n194), .ZN(m_tkeep[7]) );
  IND2D0 U553 ( .A1(n195), .B1(n109), .ZN(n241) );
  AO22D1 U554 ( .A1(n281), .A2(n196), .B1(n231), .B2(cur_byte[4]), .Z(
        m_tdata[20]) );
  AO22D1 U555 ( .A1(n283), .A2(n302), .B1(n233), .B2(cur_byte[4]), .Z(
        m_tdata[36]) );
  AO22D1 U556 ( .A1(n276), .A2(n302), .B1(n233), .B2(cur_byte[3]), .Z(
        m_tdata[35]) );
  AO22D1 U557 ( .A1(n248), .A2(n302), .B1(n233), .B2(cur_byte[5]), .Z(
        m_tdata[37]) );
  AO22D1 U558 ( .A1(n246), .A2(n196), .B1(n231), .B2(cur_byte[5]), .Z(
        m_tdata[21]) );
  IOA22D2 U559 ( .B1(n216), .B2(n224), .A1(n277), .A2(n223), .ZN(m_tdata[43])
         );
  IOA22D2 U560 ( .B1(n215), .B2(n224), .A1(n263), .A2(n223), .ZN(m_tdata[41])
         );
  IOA22D2 U561 ( .B1(n216), .B2(n226), .A1(n275), .A2(n225), .ZN(m_tdata[27])
         );
  IOA22D2 U562 ( .B1(n215), .B2(n226), .A1(n261), .A2(n225), .ZN(m_tdata[25])
         );
  IOA22D2 U563 ( .B1(n215), .B2(n222), .A1(n264), .A2(n221), .ZN(m_tdata[49])
         );
  IOA22D2 U564 ( .B1(n216), .B2(n222), .A1(n278), .A2(n221), .ZN(m_tdata[51])
         );
  IOA22D2 U565 ( .B1(n217), .B2(n224), .A1(n256), .A2(n223), .ZN(m_tdata[42])
         );
  IOA22D2 U566 ( .B1(n217), .B2(n226), .A1(n254), .A2(n225), .ZN(m_tdata[26])
         );
  IOA22D2 U567 ( .B1(n217), .B2(n222), .A1(n257), .A2(n221), .ZN(m_tdata[50])
         );
  IOA22D2 U568 ( .B1(n218), .B2(n224), .A1(n249), .A2(n223), .ZN(m_tdata[45])
         );
  IOA22D2 U569 ( .B1(n218), .B2(n222), .A1(n250), .A2(n221), .ZN(m_tdata[53])
         );
  IOA22D2 U570 ( .B1(n218), .B2(n226), .A1(n247), .A2(n225), .ZN(m_tdata[29])
         );
  IOA22D2 U571 ( .B1(n220), .B2(n224), .A1(n291), .A2(n223), .ZN(m_tdata[46])
         );
  IOA22D2 U572 ( .B1(n220), .B2(n226), .A1(n289), .A2(n225), .ZN(m_tdata[30])
         );
  IOA22D2 U573 ( .B1(n219), .B2(n224), .A1(n298), .A2(n223), .ZN(m_tdata[47])
         );
  IOA22D2 U574 ( .B1(n219), .B2(n226), .A1(n296), .A2(n225), .ZN(m_tdata[31])
         );
  IOA22D2 U575 ( .B1(n220), .B2(n222), .A1(n292), .A2(n221), .ZN(m_tdata[54])
         );
  IOA22D2 U576 ( .B1(n219), .B2(n222), .A1(n299), .A2(n221), .ZN(m_tdata[55])
         );
  IOA22D2 U577 ( .B1(n229), .B2(n219), .A1(n237), .A2(n294), .ZN(m_tdata[15])
         );
  IOA22D2 U578 ( .B1(n229), .B2(n220), .A1(n237), .A2(n287), .ZN(m_tdata[14])
         );
  IOA22D2 U579 ( .B1(n228), .B2(n222), .A1(n285), .A2(n221), .ZN(m_tdata[52])
         );
  IOA22D2 U580 ( .B1(n228), .B2(n226), .A1(n282), .A2(n225), .ZN(m_tdata[28])
         );
  IOA22D2 U581 ( .B1(n228), .B2(n224), .A1(n284), .A2(n223), .ZN(m_tdata[44])
         );
  IOA22D2 U582 ( .B1(n227), .B2(n222), .A1(n271), .A2(n221), .ZN(m_tdata[48])
         );
  IOA22D2 U583 ( .B1(n227), .B2(n224), .A1(n270), .A2(n223), .ZN(m_tdata[40])
         );
  IOA22D2 U584 ( .B1(n227), .B2(n226), .A1(n268), .A2(n225), .ZN(m_tdata[24])
         );
  IOA22D2 U585 ( .B1(n229), .B2(n228), .A1(n280), .A2(n237), .ZN(m_tdata[12])
         );
  IOA21D0 U586 ( .A1(s_tlast), .A2(n380), .B(n230), .ZN(last_q) );
  NR4D0 U587 ( .A1(prem_q[4]), .A2(prem_q[3]), .A3(prem_q[5]), .A4(n235), .ZN(
        n382) );
  NR4D0 U588 ( .A1(n301), .A2(n237), .A3(n236), .A4(n380), .ZN(ocnt_q[2]) );
  INR4D0 U589 ( .A1(n239), .B1(n301), .B2(n238), .B3(n380), .ZN(ocnt_q[1]) );
endmodule


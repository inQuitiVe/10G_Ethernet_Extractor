// =============================================================================
// pkg_msg_extractor.sv
// Package for 10G Ethernet Message Extractor - shared types and parameters
// =============================================================================

package pkg_msg_extractor;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int DATA_W = 64;
  localparam int KEEP_W = 8;   // DATA_W/8
  localparam int PAYLOAD_MIN = 8;
  localparam int PAYLOAD_MAX = 32;
  localparam int HDR_BYTES = 2;
  localparam int PKT_MAX_BYTES = 1500;

endpackage

# 10G Ethernet Message Extractor — Design Assumptions

## Message Format

Each message consists of:

```
┌─────────────────────────┬────────────────────────────────────────┐
│  Header (2 bytes)       │  Payload (8–32 bytes)                  │
│  Big-endian payload_len │  Raw bytes, output directly to AXI-S   │
└─────────────────────────┴────────────────────────────────────────┘
```

- **Header**: 2 bytes, big-endian, payload length in bytes
- **Payload**: 8–32 bytes, as specified by header
- Messages are **contiguous** within a packet, no padding

## Examples

### Single 8-byte message
- Input: `[0x00 0x08][0xDE 0xAD 0xBE 0xEF 0x00 0x00 0x00 0x01]`
- Output: `0xDEADBEEF00000001`, `tlast=1`

### Two messages (8B + 10B)
- Msg1: header=0x0008, payload=0xDEADBEEF00000001
- Msg2: header=0x000A, payload=0xCAFEBABE000000000002
- Output: msg1 payload + tlast first, then msg2 payload (2 beats) + tlast

## Specification Assumptions

| Item              | Assumption                                           |
|-------------------|------------------------------------------------------|
| Input tkeep       | Baseline assumes tkeep is always 8'hFF (all valid)   |
| Output tready     | Always 1 (no backpressure)                           |
| Header validity   | payload_len assumed in range 8–32                    |
| Packet boundary   | Marked by s_tlast                                    |

## Known Limitations (Baseline)

- For multi-beat messages, the last beat (partial beat, e.g. 2 bytes) may not assert m_tvalid correctly in some cases; addressed in later optimization variants.

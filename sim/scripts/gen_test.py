#!/usr/bin/env python3
"""
gen_test.py — Random packet generator for msg_extractor stress tests

Generates a vector file consumed by msg_extractor_stress_tb.sv.

Vector file format (one token per line):
  R                             -- reset DUT; start of a new packet
  I <data:16hex> <keep:2hex> <last:1>  -- AXI-S input beat
  O <data:16hex> <keep:2hex> <last:1>  -- expected output beat
  # ...                         -- comment (ignored by testbench)

Configurable parameters:
  --seed        Reproducible random seed (same seed → identical vectors)
  --n-pkts      Total number of independent packets
  --msgs-min    Min messages per packet  (≥ 1)
  --msgs-max    Max messages per packet
  --pay-min     Min payload bytes per message  (≥ 8, per spec)
  --pay-max     Max payload bytes per message  (≤ 32, per spec)
  --output      Output file path (default: stdout)

Usage:
  python sim/gen_test.py --seed 42 --n-pkts 20 --output sim/gen/vectors.txt
  python sim/gen_test.py --seed 7  --n-pkts 50 --msgs-min 5 --msgs-max 15 \\
                         --pay-min 8 --pay-max 12 --output sim/gen/vectors.txt
"""

import argparse
import random
import struct
import sys
import os


# ---------------------------------------------------------------------------
# Packet generation
# ---------------------------------------------------------------------------

def bytes_to_beats(data: bytes, mark_last: bool = True):
    """
    Split a byte sequence into 64-bit big-endian AXI-S beats.
    Returns list of (data:int, keep:int, last:int).
    tkeep uses MSB-first encoding: byte 0 → bit 7, byte 7 → bit 0.
    """
    beats = []
    n = len(data)
    for i in range(0, n, 8):
        chunk = data[i:i + 8]
        valid = len(chunk)
        is_last = mark_last and (i + 8 >= n)
        padded = chunk + bytes(8 - valid)
        word = int.from_bytes(padded, 'big')
        keep = (0xFF << (8 - valid)) & 0xFF if valid < 8 else 0xFF
        beats.append((word, keep, int(is_last)))
    return beats


def generate_packet(n_msgs: int, pay_min: int, pay_max: int, rng: random.Random):
    """
    Build one packet containing n_msgs consecutive messages.
    Returns (packet_bytes, [payload_bytes, ...]).
    """
    payloads = []
    packet = bytearray()
    for _ in range(n_msgs):
        pay_len = rng.randint(pay_min, pay_max)
        payload = bytes(rng.randint(0, 255) for _ in range(pay_len))
        packet += struct.pack('>H', pay_len) + payload   # 2-byte BE header + payload
        payloads.append(payload)
    return bytes(packet), payloads


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument('--seed',     type=int, default=42,
                        help='Random seed (default: 42)')
    parser.add_argument('--n-pkts',   type=int, default=20,
                        help='Number of packets (default: 20)')
    parser.add_argument('--msgs-min', type=int, default=1,
                        help='Min messages per packet (default: 1)')
    parser.add_argument('--msgs-max', type=int, default=5,
                        help='Max messages per packet (default: 5)')
    parser.add_argument('--pay-min',  type=int, default=8,
                        help='Min payload bytes (default: 8, spec minimum)')
    parser.add_argument('--pay-max',  type=int, default=32,
                        help='Max payload bytes (default: 32, spec maximum)')
    parser.add_argument('--output',   type=str, default='-',
                        help='Output file path (default: stdout)')
    args = parser.parse_args()

    # Validate
    if not (1 <= args.msgs_min <= args.msgs_max):
        parser.error('msgs-min must be >= 1 and <= msgs-max')
    if not (8 <= args.pay_min <= args.pay_max <= 32):
        parser.error('pay range must satisfy 8 <= pay-min <= pay-max <= 32')
    if args.n_pkts < 1:
        parser.error('n-pkts must be >= 1')

    rng = random.Random(args.seed)

    if args.output == '-':
        out = sys.stdout
    else:
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        out = open(args.output, 'w')

    # Header comment
    out.write(
        f'# gen_test.py  seed={args.seed}  n_pkts={args.n_pkts}  '
        f'msgs={args.msgs_min}-{args.msgs_max}  '
        f'pay={args.pay_min}-{args.pay_max}\n'
    )

    total_in = total_out = 0

    for pkt_idx in range(args.n_pkts):
        n_msgs = rng.randint(args.msgs_min, args.msgs_max)
        packet_bytes, payloads = generate_packet(n_msgs, args.pay_min, args.pay_max, rng)

        out.write(f'# pkt {pkt_idx + 1}/{args.n_pkts}: {n_msgs} msg(s), {len(packet_bytes)} bytes\n')
        out.write('R\n')

        for data, keep, last in bytes_to_beats(packet_bytes):
            out.write(f'I {data:016X} {keep:02X} {last}\n')
            total_in += 1

        for pay in payloads:
            for data, keep, last in bytes_to_beats(pay):
                out.write(f'O {data:016X} {keep:02X} {last}\n')
                total_out += 1

    out.write(f'# total: {args.n_pkts} pkts  {total_in} input beats  {total_out} expected output beats\n')

    if args.output != '-':
        out.close()
        print(f'[gen_test] {args.n_pkts} pkts → {args.output}')
        print(f'           input beats: {total_in}   expected outputs: {total_out}')


if __name__ == '__main__':
    main()

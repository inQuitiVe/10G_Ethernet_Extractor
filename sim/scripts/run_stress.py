#!/usr/bin/env python3
"""
run_stress.py — Run a vvp simulation and tee stdout to a log file.

Cross-platform replacement for shell 'printf ... > log && vvp ... | tee -a log'
(Windows CMD has neither printf nor tee).

Usage (called by Makefile stress target):
  python sim/run_stress.py \\
      --logfile sim/logs/baseline_default_seed42.log \\
      --meta "variant=baseline scenario=default seed=42 ..." \\
      -- vvp sim/compiled/stress_baseline.vvp +vectors=sim/gen/vectors.txt
"""

import argparse
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--logfile', required=True)
    parser.add_argument('--meta',    default='')
    # Everything after '--' is the command to run
    args, rest = parser.parse_known_args()
    cmd = rest[1:] if rest and rest[0] == '--' else rest

    logpath = Path(args.logfile)
    logpath.parent.mkdir(parents=True, exist_ok=True)

    with logpath.open('w', encoding='utf-8') as log:
        if args.meta:
            log.write(f'# {args.meta}\n')
            log.flush()

        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=None,        # stderr stays on terminal (icarus warnings)
            text=True,
            encoding='utf-8',
            errors='replace',
            bufsize=1,
        )

        for line in proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            log.write(line)

        proc.wait()

    sys.exit(proc.returncode)


if __name__ == '__main__':
    main()

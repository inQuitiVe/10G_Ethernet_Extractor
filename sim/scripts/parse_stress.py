#!/usr/bin/env python3
"""
parse_stress.py — Parse simulation log files and print summary tables.

Handles two log types written by the Makefile:
  Functional  sim/logs/<variant>_func.log        (make all / make <variant>)
  Stress      sim/logs/<variant>_<scenario>_seed<N>.log  (make stress_all / make stress_*)

Each log starts with a metadata comment:
  # variant=baseline type=func
  # variant=baseline scenario=dense seed=42 n_pkts=50 msgs=5-15 pay=8-12

Usage:
  python sim/scripts/parse_stress.py              # default: scan sim/logs/
  python sim/scripts/parse_stress.py sim/logs/    # explicit directory
  python sim/scripts/parse_stress.py a.log b.log  # explicit files
  python sim/scripts/parse_stress.py --fail-only  # only failing runs
"""

import re
import sys
from pathlib import Path


# ── ANSI colours (disabled when not a tty) ────────────────────────────────────
def _colour(code):
    return (lambda s: f'\033[{code}m{s}\033[0m') if sys.stdout.isatty() else (lambda s: s)

GREEN  = _colour('32')
RED    = _colour('31;1')
YELLOW = _colour('33')
BOLD   = _colour('1')


# ── Log parsing ───────────────────────────────────────────────────────────────

def parse_log(path: Path) -> dict:
    text = path.read_text(errors='replace')

    # ── Metadata ──────────────────────────────────────────────────────────────
    variant_m  = re.search(r'variant=(\S+)', text)
    type_m     = re.search(r'\btype=(\S+)', text)
    scenario_m = re.search(r'scenario=(\S+)', text)
    seed_m     = re.search(r'\bseed=(\S+)', text)
    npkts_m    = re.search(r'n_pkts=(\S+)', text)
    msgs_m     = re.search(r'\bmsgs=(\S+)', text)
    pay_m      = re.search(r'\bpay=(\S+)', text)

    variant   = variant_m.group(1)  if variant_m  else path.stem.split('_')[0]
    log_type  = type_m.group(1)     if type_m     else 'stress'
    scenario  = scenario_m.group(1) if scenario_m else '-'
    seed      = seed_m.group(1)     if seed_m     else '-'
    n_pkts    = npkts_m.group(1)    if npkts_m    else '-'
    msgs      = msgs_m.group(1)     if msgs_m     else '-'
    pay       = pay_m.group(1)      if pay_m      else '-'

    # ── Results  (handles both "Results: N" and "Results : N") ────────────────
    res_m     = re.search(r'Results\s*:\s*(\d+)\s+PASS,\s*(\d+)\s+FAIL', text)
    n_timeout = len(re.findall(r'\bTIMEOUT\b', text))
    completed = res_m is not None

    return {
        'file':      path.name,
        'log_type':  log_type,
        'variant':   variant,
        'scenario':  scenario,
        'seed':      seed,
        'n_pkts':    n_pkts,
        'msgs':      msgs,
        'pay':       pay,
        'n_pass':    int(res_m.group(1)) if res_m else None,
        'n_fail':    int(res_m.group(2)) if res_m else None,
        'n_timeout': n_timeout,
        'completed': completed,
        'ok':        completed and int(res_m.group(2)) == 0,
    }


# ── Table helpers ─────────────────────────────────────────────────────────────

def _sep(col_widths):
    return '+-' + '-+-'.join('-' * w for w in col_widths) + '-+'

def _row(cells):          # cells = list of (text, width) or pre-formatted str
    return '| ' + ' | '.join(cells) + ' |'

def _status_cell(r, w):
    if r['ok']:
        return GREEN('PASS'.center(w))
    if not r['completed']:
        return YELLOW('INCOMPLETE'.center(w))
    return RED('FAIL'.center(w))

def _fail_cell(val, w):
    s = str(val).rjust(w) if val is not None else '?'.rjust(w)
    return RED(s) if val and val > 0 else s

def _timeout_cell(val, w):
    s = str(val).rjust(w)
    return YELLOW(s) if val > 0 else s


# ── Functional table ──────────────────────────────────────────────────────────

_VARIANT_ORDER = {'baseline': 0, 'power': 1, 'area': 2, 'throughput': 3, 'timing': 4}

def print_func_table(records: list, fail_only: bool = False):
    shown = [r for r in records if not fail_only or not r['ok']]
    if not shown:
        if fail_only:
            print(GREEN('  (no failures — all functional runs passed)'))
        return

    COL_W = [11, 6, 6, 10]                     # variant, pass, fail, status
    HDR   = ['variant', 'pass', 'fail', 'status']
    sep   = _sep(COL_W)
    hdr   = _row([BOLD(h.center(w)) for h, w in zip(HDR, COL_W)])

    print(sep); print(hdr); print(sep)
    for r in shown:
        cells = [
            r['variant'].ljust(COL_W[0]),
            str(r['n_pass'] or '?').rjust(COL_W[1]),
            _fail_cell(r['n_fail'], COL_W[2]),
            _status_cell(r, COL_W[3]),
        ]
        print(_row(cells))
    print(sep)


# ── Stress table ──────────────────────────────────────────────────────────────

_SCENARIO_ORDER = {'default': 0, 'dense': 1, 'max': 2, 'long': 3}

def _stress_sort_key(r):
    return (
        _VARIANT_ORDER.get(r['variant'],   99),
        _SCENARIO_ORDER.get(r['scenario'], 99),
        r['seed'],
    )

def print_stress_table(records: list, fail_only: bool = False):
    shown = [r for r in records if not fail_only or not r['ok']]
    if not shown:
        if fail_only:
            print(GREEN('  (no failures — all stress runs passed)'))
        return

    COL = [
        ('variant',  11, lambda r: r['variant'].ljust(11)),
        ('scenario',  9, lambda r: r['scenario'].ljust(9)),
        ('seed',      6, lambda r: str(r['seed']).center(6)),
        ('pkts',      5, lambda r: str(r['n_pkts']).center(5)),
        ('pass',      6, lambda r: str(r['n_pass'] or '?').rjust(6)),
        ('fail',      6, lambda r: _fail_cell(r['n_fail'], 6)),
        ('timeout',   8, lambda r: _timeout_cell(r['n_timeout'], 8)),
        ('status',    8, lambda r: _status_cell(r, 8)),
    ]

    sep = _sep([w for _, w, _ in COL])
    hdr = _row([BOLD(n.center(w)) for n, w, _ in COL])

    print(sep); print(hdr); print(sep)
    prev = None
    for r in shown:
        if prev and prev != r['variant']:
            print(sep)
        prev = r['variant']
        print(_row([fn(r) for _, _, fn in COL]))
    print(sep)


# ── Summary line ──────────────────────────────────────────────────────────────

def print_summary_line(label: str, records: list):
    total_pass    = sum(r['n_pass'] or 0 for r in records if r['completed'])
    total_fail    = sum(r['n_fail'] or 0 for r in records if r['completed'])
    total_timeout = sum(r['n_timeout']    for r in records)
    n_ok          = sum(1 for r in records if r['ok'])
    n_runs        = len(records)
    n_incomplete  = sum(1 for r in records if not r['completed'])

    if total_fail == 0 and n_incomplete == 0:
        print(GREEN(f'  RESULT  {n_ok}/{n_runs} {label} PASS'
                    f'  |  beats: {total_pass} PASS, 0 FAIL'))
    else:
        parts = []
        if total_fail    > 0: parts.append(RED(f'{total_fail} beat FAIL'))
        if total_timeout > 0: parts.append(YELLOW(f'{total_timeout} TIMEOUT'))
        if n_incomplete  > 0: parts.append(YELLOW(f'{n_incomplete} incomplete'))
        print(RED(f'  RESULT  {n_ok}/{n_runs} {label} PASS  | ') + ', '.join(parts))


# ── Main ──────────────────────────────────────────────────────────────────────

def collect_logs(args: list) -> list[Path]:
    paths = []
    if not args:
        args = ['sim/logs']
    for a in args:
        p = Path(a)
        if p.is_dir():
            paths.extend(sorted(p.glob('*.log')))
        elif p.exists():
            paths.append(p)
        else:
            print(f'[warn] not found: {a}', file=sys.stderr)
    return paths


def main():
    argv      = sys.argv[1:]
    fail_only = '--fail-only' in argv
    argv      = [a for a in argv if not a.startswith('--')]

    logs = collect_logs(argv)
    if not logs:
        print('[parse_stress] no log files found.', file=sys.stderr)
        sys.exit(0)

    records = [parse_log(p) for p in logs]

    func_recs   = sorted([r for r in records if r['log_type'] == 'func'],
                         key=lambda r: _VARIANT_ORDER.get(r['variant'], 99))
    stress_recs = sorted([r for r in records if r['log_type'] == 'stress'],
                         key=_stress_sort_key)

    WIDTH = 66
    any_fail = False

    # ── Functional section ────────────────────────────────────────────────────
    if func_recs:
        print()
        print('=' * WIDTH)
        print(BOLD('  Functional Test Summary'))
        print(f'  {len(func_recs)} variant(s)')
        print('=' * WIDTH)
        print()
        print_func_table(func_recs, fail_only=fail_only)
        print()
        print_summary_line('variants', func_recs)
        print()
        print('=' * WIDTH)
        any_fail = any_fail or any(not r['ok'] for r in func_recs)

    # ── Stress section ────────────────────────────────────────────────────────
    if stress_recs:
        logdir_str = str(Path(argv[0] if argv else 'sim/logs').resolve())
        print()
        print('=' * WIDTH)
        print(BOLD('  Stress Test Summary'))
        print(f'  {len(stress_recs)} run(s) in: {logdir_str}')
        print('=' * WIDTH)
        print()
        print_stress_table(stress_recs, fail_only=fail_only)
        print()
        print_summary_line('runs', stress_recs)
        print()
        print('=' * WIDTH)
        any_fail = any_fail or any(not r['ok'] for r in stress_recs)

    sys.exit(1 if any_fail else 0)


if __name__ == '__main__':
    main()

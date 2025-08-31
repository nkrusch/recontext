import os
import random
import shutil
import signal
import subprocess
import sys
from itertools import combinations as comb
from os.path import join, dirname, abspath
from pathlib import Path
from typing import Callable

from rich.progress import Progress

from __init__ import read, input_csv, b_name
from __init__ import read_trace, construct_trace, parse_dig_str

ENV = {'PICK_N': 5, 'TMP': '.tmp', 'STO': 60, 'TO': 600, **os.environ}
TOTAL_TO, SUBPROC_TO = map(int, [(ENV['TO']), ENV['STO']])
PICK_N, TMP = int(ENV['PICK_N']), ENV['TMP']


def construct_fn(base_name, indices):
    return f'{base_name}-' + '-'.join(map(str, indices)) + '.csv'


def __analyze(indices, name, args, trace, variables):
    """A generator for invariant inference.

    Arguments:
        indices: list of indices to analyze
        name: benchmark name
        args: Dig arguments
        trace: input data
        variables: trace variables
    """
    for ix in indices:
        vrs = [v for i, v in enumerate(variables) if i in ix]
        tmp_in = join(TMP, construct_fn(name, ix))
        construct_trace(vrs, trace[:, ix], fn=tmp_in)
        try:
            yield subprocess.run(
                ['python3', '-O', 'dig/src/dig.py', tmp_in, *args],
                cwd=dirname(dirname(abspath(__file__))),
                timeout=SUBPROC_TO,
                capture_output=True, text=True).stdout
        except subprocess.TimeoutExpired:
            yield ''
        os.remove(tmp_in)


def add_num(offset, values):
    """Number a list of values."""
    return [f'{offset + n}. {x}' for n, x in enumerate(values)]


def calc_diff(n, combinations):
    result = []
    for c in combinations:
        diff = lambda r: set(c).symmetric_difference(set(r))
        if not next((r for r in result if len(diff(r)) < n), None):
            result.append(c)
    return result


def header(tloc, count='?'):
    """Format a result header."""
    return f'{tloc} ({count} invs):'


def do_with_to(action: Callable, cleanup: Callable = None):
    def to_handler(signum, frame):
        raise TimeoutError()

    signal.signal(signal.SIGALRM, to_handler)
    signal.alarm(TOTAL_TO)
    code = 0
    try:
        action()
    except TimeoutError:
        code = 129
    if cleanup:
        cleanup()
    sys.exit(code)


def main(fp, *args):
    """Modified Dig run that partitions the input trace.

    If number of variables is low (<= 6), runs regular Dig.
    Otherwise, sample at most MAX_VARS and analyze a subset
    of the traces.

    Arguments:
        fp: path to input trace
        *args: Dig arguments
    """
    trc, vrs, tloc = read_trace(fp)

    if len(vrs) <= 6:
        def run_me():
            try:
                res = subprocess.run(
                    ['python3', '-O', 'dig/src/dig.py', fp, *args],
                    cwd=dirname(dirname(abspath(__file__))),
                    timeout=SUBPROC_TO,
                    capture_output=True, text=True).stdout
                print(res)
            except subprocess.TimeoutExpired:
                pass
        return do_with_to(run_me)

    ids = calc_diff(4, list(comb(range(len(vrs)), PICK_N)))
    Path(TMP).mkdir(parents=True, exist_ok=True)
    cleanup = lambda: shutil.rmtree(TMP, ignore_errors=True)
    random.shuffle(ids)

    def do_all():
        history, recount = {}, 1
        flt = lambda x: x not in history
        with Progress() as progress:
            print(header(tloc))
            task = progress.add_task('', total=len(ids))
            for item in __analyze(ids, Path(fp).stem, args, trc, vrs):
                if inv := list(filter(flt, parse_dig_str(item))):
                    history.update(dict([(k, 1) for k in inv]))
                    print('\n'.join(add_num(recount, inv)))
                    recount += len(inv)
                progress.update(task, advance=1)

    return do_with_to(do_all, cleanup)


def reform(fp):
    """Rewrite stream result to sorted format."""
    source = input_csv(b_name(fp))
    tloc = read_trace(source)[-1]
    lines = (read(fp) or '').strip().split('\n')
    if lines:
        nums = [x for x in lines if '. ' in x]
        ins = [ln.split('. ', 1)[1] for ln in nums]
        lines = add_num(1, sorted(ins, key=len))
    data = '\n'.join([header(tloc, str(len(lines)))] + lines)
    with open(fp, 'w') as f:
        f.write(data)


if __name__ == "__main__":
    input_file, *dig_args = sys.argv[1:]
    if input_file.endswith('.csv'):
        main(input_file, *dig_args)
    if input_file.endswith('.digup'):
        reform(input_file)

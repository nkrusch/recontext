import os
import shutil
import subprocess
import sys
from itertools import combinations as comb
from os.path import join, dirname, abspath
from pathlib import Path
import random

from rich.progress import Progress

from __init__ import read_trace, construct_trace, parse_dig_str, \
    read, input_csv, b_name

ENV = {'PICK_N': 5, 'TMP': '.tmp', 'SUB_TO': 60, **os.environ}
PICK_N, TMP = ENV['PICK_N'], ENV['TMP']
SUBPROC_TO = ENV['SUB_TO']


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
        tmp_in = join(TMP, construct_fn(name, ix))
        vrs = [v for i, v in enumerate(variables) if i in ix]
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


def i_filter(hst, cand):
    """Basic filter to ignore duplicates and simple patterns."""
    if cand in hst:
        return False
    hst[cand] = 1
    if '<=' in cand:  # ignore var <= num
        return ' ' in cand.split('<=', 1)[0].strip()
    return True


def cleanup():
    """Cleanup tasks after analyzer run."""
    shutil.rmtree(TMP, ignore_errors=True)


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
    n_vars, history = len(vrs), {}
    flt = lambda x: i_filter(history, x)
    Path(TMP).mkdir(parents=True, exist_ok=True)
    if n_vars <= 6:
        ids = [tuple(range(0, n_vars))]
    else:
        ids = calc_diff(4, list(comb(range(n_vars), PICK_N)))
        random.shuffle(ids)

    # generator
    def do_all(after_each=lambda: True):
        recount = 1
        for item in __analyze(ids, Path(fp).stem, args, trc, vrs):
            if inv := list(filter(flt, parse_dig_str(item))):
                print('\n'.join(add_num(recount, inv)))
                recount += len(inv)
            after_each()

    def with_prog():
        with Progress() as progress:
            task = progress.add_task('', total=len(ids))
            do_all(lambda: progress.update(task, advance=1) and True)

    with_prog() if len(ids) > 1 else do_all()
    cleanup()


def header(tloc, count='?'):
    """Format a result header."""
    return f'{tloc} ({count} invs):'


def reform(fp):
    """Rewrite stream result to sorted format."""
    source = input_csv(b_name(fp))
    tloc = read_trace(source)[-1]
    lines = (read(fp) or '').strip().split('\n')
    if lines:
        nums = [x for x in lines[1:] if '. ' in x]
        (ins := [ln.split('. ', 1)[1] for ln in nums]).sort(key=len)
        lines = add_num(1, ins)
    data = '\n'.join([header(tloc, str(len(lines)))] + lines)
    with open(fp, 'w') as f:
        f.write(data)


if __name__ == "__main__":
    input_file, *dig_args = sys.argv[1:]
    if input_file.endswith('.csv'):
        main(input_file, *dig_args)
    if input_file.endswith('.digup'):
        reform(input_file)

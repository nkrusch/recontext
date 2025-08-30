import os
import subprocess
import sys
from itertools import combinations as comb
from os.path import join, dirname, abspath
from pathlib import Path

from __init__ import read_trace, construct_trace, parse_dig_str

ENV = {'MAXV': 3, 'TMP': '.tmp', **os.environ}
MAX_VAR, TMP = ENV['MAXV'], ENV['TMP']


def construct_fn(base_name, indices):
    return f'{base_name}-' + '-'.join(map(str, indices)) + '.csv'


def __analyze(indices, name, args, trace, variables):
    """A generator for tracing"""
    for ix in indices:
        tmp_in = join(TMP, construct_fn(name, ix))
        vrs = [v for i, v in enumerate(variables) if i in ix]
        construct_trace(vrs, trace[:, ix], fn=tmp_in)
        yield subprocess.run(
            ['python3', '-O', 'dig/src/dig.py', tmp_in, *args],
            cwd=dirname(dirname(abspath(__file__))),
            timeout=60,
            capture_output=True, text=True).stdout
        os.remove(tmp_in)


def i_filter(hst, cand):
    """Basic filter to ignore duplicates and simple patterns."""
    if cand in hst:
        return False
    hst[cand] = 1
    if '<=' in cand:  # ignore var <= num
        return ' ' in cand.split('<=', 1)[0].strip()
    return True


def main():
    """Modified Dig that partitions input."""
    fp, *args = sys.argv[1:]
    _, vrs = tp = read_trace(fp)
    n_vars, recount, history = len(vrs), 1, {}
    max_v = min(MAX_VAR, n_vars)
    flt = lambda x: i_filter(history, x)
    Path(TMP).mkdir(parents=True, exist_ok=True)

    ids = [comb(range(n_vars), sz) for sz in range(max_v, max_v + 1)]
    ids = [x for lst in ids for x in lst]
    ids.reverse()  # longest subsets first

    # generator
    for item in __analyze(ids, Path(fp).stem, args, *tp):
        if inv := parse_dig_str(item):
            inv = list(filter(flt, inv))
        if inv:
            res = [f'{recount + n}. {x}' for n, x in enumerate(inv)]
            print('\n'.join(res), end='\n')
            recount += len(inv)
    Path(TMP).rmdir()


if __name__ == "__main__":
    main()

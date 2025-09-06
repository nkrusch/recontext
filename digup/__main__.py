import random
import shutil
import signal
import subprocess
import sys
from itertools import combinations as comb
from os.path import join, dirname, abspath, isfile
from pathlib import Path

from rich.progress import Progress

from scripts import read_lines, input_csv, b_name
from scripts import read_trace, construct_trace, dig_p
from scripts.env import *


def __calc_diff(n, combinations):
    """Combinations with symmetric difference > n."""
    result = []
    for c in combinations:
        diff = lambda r: set(c).symmetric_difference(set(r))
        if not next((r for r in result if len(diff(r)) < n), None):
            result.append(c)
    return result


def __run_dig(in_file, *args):
    """Run Dig with timeout."""
    return subprocess.run(
        ['python3', '-O', 'dig/src/dig.py', in_file, *args],
        cwd=dirname(dirname(abspath(__file__))),
        timeout=SUBPROC_TO, capture_output=True, text=True).stdout


def run_parts(indices, name, args, trace, variables):
    """A generator for invariant inference over partitions.

    Arguments:
        indices: list of indices to analyze
        name: benchmark name
        args: Dig arguments
        trace: input data
        variables: list of variables
    """
    for ix in indices:
        vars_ = [v for i, v in enumerate(variables) if i in ix]
        f_names = f'{name}-' + '-'.join(map(str, ix)) + '.csv'
        tmp_in = join(TMP, f_names)
        construct_trace(vars_, trace[:, ix], fn=tmp_in)
        try:
            yield __run_dig(tmp_in, *args)
        except subprocess.TimeoutExpired:
            yield ''
        os.remove(tmp_in)


def run_one(fp, *args):
    """Run Dig on specified file."""
    try:
        print(__run_dig(fp, *args))
    except subprocess.TimeoutExpired:
        pass


def partition(trace, vars_, fp, *args):
    """Modified Dig run that partitions the input trace.

    If number of variables is low (<= 6), runs regular Dig.
    Otherwise, sample at most MAX_VARS and analyze a subset
    of the traces.

    Arguments:
        trace: traced values
        vars_: list of variables names
        fp: path to input trace
        *args: Dig arguments
    """
    history, recount = {}, 1
    flt = lambda x: x not in history
    ids = __calc_diff(4, list(comb(range(len(vrs)), PICK_N)))
    random.shuffle(ids)
    Path(TMP).mkdir(parents=True, exist_ok=True)
    to_handler = lambda _, __: sys.exit(129)
    signal.signal(signal.SIGALRM, to_handler)
    signal.alarm(TOTAL_TO)
    with Progress() as progress:
        task = progress.add_task('', total=len(ids))
        for item in run_parts(ids, b_name(fp), args, trace, vars_):
            if inv := list(filter(flt, dig_p(item))):
                history.update(dict([(k, 1) for k in inv]))
                print('\n#. '.join(inv))
            progress.update(task, advance=1)
    shutil.rmtree(TMP, ignore_errors=True)


def reformat(fp):
    """Rewrite stream result to sorted format."""
    if isfile(fp):
        loc = read_trace(input_csv(b_name(fp)))[-1]
        if lines := read_lines(fp):
            values = sorted(dig_p(lines), key=len)
            lines = [f'{1 + n}. {x}' for n, x in enumerate(values)]
        head = f'{loc} ({len(lines)} invs):'
        data = '\n'.join([head] + lines)
        with open(fp, 'w') as f:
            f.write(data)


if __name__ == "__main__":
    input_file, *dig_args = sys.argv[1:]
    if input_file.endswith('.csv'):
        trc, vrs, _ = read_trace(input_file)
        a = lambda: run_one(input_file, *dig_args)
        b = lambda: partition(trc, vrs, input_file, *dig_args)
        a() if len(vrs) <= 6 else b()
    if input_file.endswith('.digup'):
        reformat(input_file)

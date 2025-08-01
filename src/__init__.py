import re
from itertools import product
from os.path import isfile
from typing import List

import numpy as np
import pandas as pd
from prettytable import PrettyTable
from z3 import *

# Path to traces
IN_DIR = 'input/traces'
ENV = {'T_DTYPE': np.int64, **os.environ}

# Format configs
T_SEP, C_SEP = ';', ','
T_PREFIX, T_LABEL = 'I ', 'trace1'
TOKENS = re.escape('==,**,<=,>=,(,),[,],*,-,+,/,%').split(',')
T_DTYPE = ENV["T_DTYPE"]
PRED_PAD = 64


def read(fn):
    with open(fn, 'r') as fp:
        raw = fp.read()
    return raw


def read_trace(path) -> np.array:
    df = pd.read_csv(path, sep=T_SEP)
    idx_slice, variables = [], []
    for i, c in enumerate(df.columns):
        if i == 0 or c.startswith('Unnamed:'):
            continue
        if c2 := str(c).strip().replace(T_PREFIX, ''):
            idx_slice.append(i)
            variables.append(c2)
    data = np.array(df.values[:, idx_slice], dtype=T_DTYPE)
    return data, variables


def trace_to_csv(input_file: str):
    data, var = read_trace(input_file)
    data = np.vstack([np.array(var), data])
    np.savetxt(sys.stdout, data, delimiter=C_SEP, fmt='%s')


def csv_to_trace(input_file: str):
    init = pd.read_csv(input_file, sep=',')
    var = [f'{T_PREFIX}{x}' for x in init.columns]
    data = np.vstack([np.array(var), np.array(init.values)])
    prefix = np.full((data.shape[0], 1), T_LABEL)
    data = np.hstack([prefix, data])
    np.savetxt(sys.stdout, data, delimiter=T_SEP, fmt='%s')


def flow(taken: List[str], init: List[str] = None):
    """[f]irst [low]ercase char sequence not in taken"""
    cmap = [c for c in list(map(chr, range(ord('a'), ord('z') + 1)))]
    cmap = [f'{c}{d}' for c, d in product(cmap, init)] if init else cmap
    first = [c for c in cmap if c not in taken]
    return first[0] if first else flow(taken, cmap)


def to_lambda(text, *variables) -> str:
    # generate array identifier
    xc = flow(list(variables))
    # replace all variables by x -> arr[i]
    for t in sorted(variables, key=len, reverse=True):
        i = variables.index(t)
        # FIXME: with such naive replace max(x) becomes maa[0](a[0])
        text = text.replace(t, f'{xc}[{i}]')
    return f'lambda {xc}: {text}'.strip()


def parse_dig_result(input_file):
    temp = read(input_file).strip().split('\n')[1:]
    return [x.split('.', 1)[1].strip() for x in temp]


def result_source(result_file):
    base_name = os.path.basename(result_file)
    fn = os.path.splitext(base_name)[0]
    return os.path.join(IN_DIR, f'{fn}.csv')


def negpos(x):
    return x and (x.isnumeric() or x[0] == '-' and x[1:].isnumeric())


def tokenize(str_input, tokens):
    exists = [x for x in tokens if re.search(x, str_input)]
    terms = str_input.split(' ')
    for x in exists:
        tmp = terms
        n = len(terms) - 1
        for i in range(n, -1, -1):
            curr = terms[i]
            if (not (curr in tokens or negpos(curr))
                    and re.search(x, curr)):
                parts = [p for p in re.split(f'({x})', curr) if p]
                before = tmp[:i] if i > 0 else []
                after = tmp[i + 1:] if i < n else []
                tmp = before + parts + after
        terms = tmp
    return terms


def val_fmt(value):
    if T_DTYPE != np.int64:
        frac = Fraction(str(value))
        return f'Q({frac.numerator},{frac.denominator})'
    return value


def literalize(values, keys, tkn_pred):
    _dct = dict(zip(keys, values))
    subst = [(val_fmt(_dct[x]) if x in _dct else x) for x in tkn_pred]
    return (''.join([str(s) for s in subst])).ljust(PRED_PAD, ' ')


def find_cex(pred, limit=3):
    cex, solver = [], Solver()
    for lit in pred:
        solver.reset()
        solver.add(eval(lit))
        if solver.check() != sat:
            cex.append(lit.strip())
        if len(cex) == limit:
            break
    return cex


def check(input_file: str) -> None:
    """Confirm invariants are valid.

    Checks that the inferred DIG invariants are valid for the input
    data. Displays at the screen the evaluation result for every
    inferred invariant.

    Arguments:
        input_file (str): path to a results file.
    """
    src = result_source(input_file)
    if not (isfile(src) and isfile(input_file) and
            input_file.endswith('.dig')):
        print('Invalid:', src, '->', input_file)
        return
    predicates = parse_dig_result(input_file)
    if not predicates:
        return

    data, var = read_trace(src)
    table = PrettyTable(["P(…)", "eval(P)", "CEX"])
    solver = Solver()

    for p in predicates:
        tkn_p, cex = tokenize(p, TOKENS), '---'
        idx, occ = zip(*[c for c in enumerate(var) if c[1] in tkn_p])
        values = np.unique(data[:, idx], axis=0)
        pred = np.apply_along_axis(literalize, 1, values, occ, tkn_p)
        solver.reset()
        [solver.add(eval(lit)) for lit in pred]
        if (sc := solver.check()) != sat:
            cex = ' '.join(find_cex(pred))
        table.add_row([p, sc, cex])
    print(table)

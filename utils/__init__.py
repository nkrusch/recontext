import os
from itertools import product
from typing import List
import sys
import numpy as np
import pandas as pd

T_PREFIX = 'I '
T_LABEL = 'trace1'
T_SEP = ';'
IN_DIR = 'traces'


class Actions:
    TRACE, CSV, CHECK = 'trace,csv,check'.split(',')
    ACTIONS = (TRACE, CSV, CHECK)

    def __init__(self, args):
        match args.action:
            case Actions.TRACE:
                csv_to_trace(args.input_file)
            case Actions.CSV:
                trace_to_csv(args.input_file)
            case Actions.CHECK:
                check(args.input_file, args.source)


def read(fn):
    with open(fn, 'r') as fp:
        raw = fp.read()
    return raw


def read_trace(path) -> np.array:
    df = pd.read_csv(path, sep=';')
    idx_slice, variables = [], []
    for i, c in enumerate(df.columns):
        if i == 0 or c.startswith('Unnamed:'):
            continue
        if c2 := str(c).strip().replace(T_PREFIX, ''):
            idx_slice.append(i)
            variables.append(c2)
    data = np.array(df.values[:, idx_slice])
    return data, variables


def flow(taken: List[str], init: List[str] = None):
    """[f]irst [low]ercase char sequence that does not occur in taken"""
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
        # FIXME: this replaces e.g., max(x) with maa[0](a[0])
        text = text.replace(t, f'{xc}[{i}]')
    return f'lambda {xc}: {text}'.strip()


def trace_to_csv(input_file: str, **kwargs):
    data, var = read_trace(input_file)
    data = np.vstack([np.array(var), data])
    np.savetxt(sys.stdout, data, delimiter=',', fmt='%s')


def csv_to_trace(input_file: str, **kwargs):
    init = pd.read_csv(input_file, sep=',')
    var = [f'{T_PREFIX}{x}' for x in init.columns]
    data = np.vstack([np.array(var), np.array(init.values)])
    prefix = np.full((data.shape[0], 1), T_LABEL)
    data = np.hstack([prefix, data])
    np.savetxt(sys.stdout, data, delimiter=T_SEP, fmt='%s')


def parse_dig_result(input_file):
    temp = read(input_file).strip().split('\n')[1:]
    return [x.split('.', 1)[1].strip() for x in temp]


def default_source(result_file):
    base_name = os.path.basename(result_file)
    fn, _ = os.path.splitext(base_name)
    return os.path.join(IN_DIR, f'{fn}.csv')


def check(input_file, source=None):
    assert input_file.endswith('.dig')
    predicates = parse_dig_result(input_file)
    data, var = read_trace(source or default_source(input_file))
    for f in predicates:
        pred = eval(P := to_lambda(f, *var))
        bits = np.apply_along_axis(pred, 1, data)
        fail = [i for i, v in enumerate(bits) if not v]
        corr = fail == []
        if not corr:
            for ri in fail:
                print(fail, f, data[ri], '\t', P)

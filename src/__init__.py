import re
from os.path import isfile, basename, splitext, join
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
TOKENS = re.escape('==,**,<=,>=,(,),[,],*,-,+,/,%').split(',') + [',']

# Types
P = str
"""Predicate"""
PT = List[str]
"""Tokenized predicate"""
T_DTYPE = ENV["T_DTYPE"]
"""Type of numerical data (int, float, double)"""


def read(fn):
    """Reads a file into memory."""
    with open(fn, 'r') as fp:
        raw = fp.read()
    return raw


def read_trace(path: str) -> Tuple[np.array, List[str]]:
    """Reads a DIG trace into memory."""
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
    """Convert a DIG trace to a CSV file."""
    data, var = read_trace(input_file)
    data = np.vstack([np.array(var), data])
    np.savetxt(sys.stdout, data, delimiter=C_SEP, fmt='%s')


def csv_to_trace(input_file: str):
    """Convert a CSV file to a DIG trace."""
    init = pd.read_csv(input_file, sep=',')
    var = [f'{T_PREFIX}{x}' for x in init.columns]
    data = np.vstack([np.array(var), np.array(init.values)])
    prefix = np.full((data.shape[0], 1), T_LABEL)
    data = np.hstack([prefix, data])
    np.savetxt(sys.stdout, data, delimiter=T_SEP, fmt='%s')


def parse_dig_result(input_file):
    """Extract invariants from a DIG result file."""
    temp = read(input_file).strip().split('\n')[1:]
    return [x.split('.', 1)[1].strip() for x in temp]


def is_num(x: str) -> bool:
    """Test if expression is a negative or positive number."""
    return (x[1:] if x and x[0] == '-' else x).isnumeric()


def tokenize(plain: str, tokens: List[str]) -> PT:
    """Splits a plaintext string by tokens.
    
    Example:
        Input `x + y == 0` and given tokens `['+', '==']`
        produces ['x', '+', 'y', '==', '0'].
        
    Arguments:
        plain: Plaintext input.
        tokens: List of tokens.

    Returns:
        The tokenized string.               
    """
    exists = [x for x in tokens if re.search(x, plain)]
    terms = plain.split(' ')
    for x in exists:
        tmp = terms
        n = len(terms) - 1
        for i in range(n, -1, -1):
            curr = terms[i]
            terminal = curr in tokens or is_num(curr)
            if not terminal and re.search(x, curr):
                parts = [p for p in re.split(f'({x})', curr) if p]
                before = tmp[:i] if i > 0 else []
                after = tmp[i + 1:] if i < n else []
                tmp = before + parts + after
        terms = tmp
    return terms


def val_fmt(value: T_DTYPE) -> str | T_DTYPE:
    """Express all real values as Q(n, d)."""
    if T_DTYPE != np.int64:
        frac = Fraction(str(value))
        return f'Q({frac.numerator},{frac.denominator})'
    return value


def to_assert(data: List[T_DTYPE], keys: List[str], pred: PT) -> P:
    """Construct a numerical assertion.

    Arguments:
        data: an array of numerical values.
        keys: variable names that match data in shape.
        pred: a tokenized assertion.

    Returns:
        A string expression where all variables are replaced with
        numerical values.
    """
    dct = dict(zip(keys, data))
    subst = [(val_fmt(dct[x]) if x in dct else x) for x in pred]
    return ''.join([str(s) for s in subst])


def find_cex(pred: List[P], limit: int = 3) -> List[P]:
    """Find (at most limit) failing assertions."""
    cex, solver = [], Solver()
    for lit in pred:
        solver.reset()
        solver.add(eval(lit))
        if solver.check() != sat:
            cex.append(lit)
        if len(cex) == limit:
            break
    return cex


def check(dig_result: str) -> bool:
    """Sanity check to confirm DIG invariants are valid.

    Checks that DIG invariants are valid for the input data. Displays,
    at stdout, the evaluation result for every invariant.

    Arguments:
        dig_result (str): path to the results file to check.

    Returns:
        True if all invariants are satisfactory; otherwise False.
    """
    src = join(IN_DIR, f'{splitext(basename(dig_result))[0]}.csv')
    if not (dig_result.endswith('.dig') and isfile(src) and
            isfile(dig_result)):
        print('Something is wrong here:', src, '=>', dig_result)
        return False
    predicates = parse_dig_result(dig_result)
    if not predicates:
        return True

    data, var = read_trace(src)
    table = PrettyTable(["P(…)", "eval(P)", "CEX"])
    solver = Solver()
    all_true = True

    for p in predicates:
        solver.reset()
        pred, cex = tokenize(p, TOKENS), ''
        idx, occ = zip(*[c for c in enumerate(var) if c[1] in pred])
        values = np.unique(data[:, idx], axis=0)
        for lit in map(lambda val: to_assert(val, occ, pred), values):
            solver.add(eval(lit))
        if (sc := solver.check()) != sat:
            all_true = False
            cex = ' '.join(find_cex(pred))
        table.add_row([p, sc, cex])
    print(table)
    return all_true

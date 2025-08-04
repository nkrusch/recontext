import re
from argparse import Namespace
# noinspection PyUnresolvedReferences
from math import *
from os.path import isfile, basename, splitext, join
from random import randint
from typing import List, Tuple

import numpy as np
import pandas as pd
import yaml
from prettytable import PrettyTable
from z3 import *

# Path to traces
IN_DIR = 'input/traces'
F_CONFIG = 'inputs.yaml'
ENV = {'T_DTYPE': np.int64, **os.environ}

# Format configs
T_SEP, C_SEP = ';', ','
T_PREFIX, T_LABEL = 'I ', 'trace1'

# How to tokenize invariant expressions
__tkn = 'if,else,or,and,not,==,**,<=,>=,(,),[,],*,-,+,/,%'
TOKENS = (re.escape(__tkn)).split(',') + [',']

# Types
P = str
"""Predicate"""
PT = List[str]
"""Tokenized predicate"""
T_DTYPE = ENV["T_DTYPE"]
"""Type of numerical data (int, double)"""


def read(fn):
    """Reads a file into memory."""
    with open(fn, 'r') as fp:
        return fp.read()


def read_yaml(path):
    """Read (and parse) a yaml file"""
    with open(path, 'r', encoding='utf-8') as yml:
        return yaml.safe_load(yml)


def read_trace(path: str) -> Tuple[np.array, List[str]]:
    """Reads a DIG trace into memory."""
    df = pd.read_csv(path, sep=T_SEP)
    idx_slice, variables = [], []
    for i, c in enumerate(df.columns[1:]):
        if not c.lower().startswith('unnamed:'):
            if c2 := str(c).strip().replace(T_PREFIX, ''):
                idx_slice.append(i + 1)
                variables.append(c2)
    data = np.array(df.values[:, idx_slice], dtype=T_DTYPE)
    return data, variables


def input_csv(bench_name):
    """Construct input data path."""
    return join(IN_DIR, f'{bench_name}.csv')


def b_name(file_path):
    """file name without path and extension."""
    return splitext(basename(file_path))[0]


def trace_to_csv(input_file: str):
    """Convert a DIG trace to a CSV file."""
    data, var = read_trace(input_file)
    data = np.vstack([np.array(var), data])
    np.savetxt(sys.stdout, data, delimiter=C_SEP, fmt='%s')


def csv_to_trace(input_file: str):
    """Convert a CSV file to a DIG trace."""
    init = pd.read_csv(input_file, sep=',')
    construct_trace(init.columns, init.values)


def construct_trace(vars_: List[str], values):
    np_val = np.array(values)
    int_test = np_val.astype(int)
    data = int_test if np.all(np_val == int_test) else np_val
    var = [f'{T_PREFIX}{x}' for x in vars_]
    data = np.vstack([np.array(var), data])
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


def qt_fmt(value: T_DTYPE):
    """Express values as Q(n, d)."""
    frac = Fraction(str(value))
    return (frac.numerator if frac.denominator == 1 else
            f'Q({frac.numerator},{frac.denominator})')


def to_assert(
        var: List[str], val: List[T_DTYPE], pred: PT,
        fmt: Callable = None
) -> P:
    """Construct a numerical assertion.

    Arguments:
        var: variable names.
        val: variable values.
        pred: a tokenized assertion.
        fmt: value formatter

    Returns:
        A string expression where all variables are replaced with
        numerical values.
    """
    fmt_ = fmt or (lambda x: x)
    dct = dict(zip(var, val))
    subst = [(fmt_(dct[x]) if x in var else x) for x in pred]
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
    src = input_csv(b_name(dig_result))
    if not (dig_result.endswith('.dig') and isfile(src) and
            isfile(dig_result)):
        raise Exception(f'Invalid: {src} => {dig_result}')
    predicates = parse_dig_result(dig_result)
    if not predicates:
        return True

    data, var = read_trace(src)
    table = PrettyTable(["P(…)", "eval(P)", "CEX"])
    solver = Solver()
    all_true = True
    fmt = qt_fmt if T_DTYPE == 'd' else None

    for p in predicates:
        solver.reset()
        pred, cex, sc = tokenize(p, TOKENS), '', None
        idx, occ = zip(*[c for c in enumerate(var) if c[1] in pred])
        for val in np.unique(data[:, idx], axis=0):
            lit = to_assert(occ, val, pred, fmt=fmt)
            try:
                solver.add(eval(lit))
            except z3types.Z3Exception:
                sc, cex = '⚠ symbolic', lit
        if not sc and (sc := solver.check()) != sat:
            all_true = False
            cex = ' '.join(find_cex(pred))
        table.add_row([p, sc, cex])
    print(table)
    return all_true


def rand_data(in_vars, ranges, expr, n_out):
    """Calculate value of a function for random inputs.

    Given an expression with variables,
        1. Choose random value for each variable.
        2. Substitute all variables in expression with values.
        3. Evaluate the expression to get output value.

    Arguments:
        in_vars: input variables that occur in expr.
        ranges: (min, max) of each variable.
        expr: literal (str) of a function to evaluate.
        n_out: number of outputs

    Raises:
        Exception: if `expr` contains variables not in `in_vars`
            or other expressions outside the Python math stdlib.

    Returns:
        A row of data, of selected inputs and the calculated output.
    """
    dt_v = lambda nx: randint(*nx) if isinstance(nx, list) else nx
    data = list(map(dt_v, ranges))
    if n_out > 0:
        result = eval(to_assert(in_vars, data, expr))
        result = list(result) if isinstance(result, tuple) else [result]
        data += result
    return data


def gen(f_name):
    """Generate random function traces based on config template."""
    conf = read_yaml(F_CONFIG)
    if f_name not in conf:
        raise Exception(f'No generator known for {f_name}')
    fun = Namespace(**conf[f_name])
    pred = tokenize(fun.expr, TOKENS)
    f_in = fun.vin if fun.vin else {}
    vin, ranges = list(f_in.keys()), list(f_in.values())
    v_out = (fun.vo if isinstance(fun.vo, list)
             else [fun.vo] if fun.vo else [])
    data = [rand_data(vin, ranges, pred, len(v_out))
            for _ in range(fun.n)]
    construct_trace(vin + v_out, data)

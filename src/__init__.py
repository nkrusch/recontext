import re
from argparse import Namespace
from collections import Counter
# noinspection PyUnresolvedReferences
from math import *
from os import listdir
from os.path import isfile, basename, splitext, join
from pathlib import Path
from random import randint
from typing import List, Tuple, Optional

import numpy as np
import pandas as pd
import yaml
from prettytable import PrettyTable
from z3 import *

# Path to traces
IN_DIR = 'input/traces'
F_CONFIG = 'inputs.yaml'
ENV = {'T_DTYPE': np.int64, 'Z3_TO': 60, 'DEBUG': False,
       'C_SEP': ',', **os.environ}

# Format configs
T_SEP = ';'
C_SEP = ENV['C_SEP']
T_PREFIX, T_LABEL = 'I ', 'trace1'

# Tokenization of invariant expressions(in order)
__tkn = ('randint,else,for,and,not,max,min,mod,log,sin,cos,tan,'
         'if,in,or,===,==,**,<=,>=,(,),[,],*,-,+,/,%')
TOKENS = (re.escape(__tkn)).split(',') + [',']
WSP = '↡'  # a special symbol to mark spaces

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
    # noinspection PyTypeChecker
    np.savetxt(sys.stdout, data, delimiter=C_SEP, fmt='%s')


def csv_to_trace(input_file: str):
    """Convert a CSV file to a DIG trace."""
    init = pd.read_csv(input_file, sep=C_SEP)
    construct_trace(init.columns, init.values)


def construct_trace(vars_: List[str], values):
    np_val = np.array(values)
    int_test = np_val.astype(int)
    data = int_test if np.all(np_val == int_test) else np_val
    var = [f'{T_PREFIX}{x}' for x in vars_]
    data = np.vstack([np.array(var), data])
    prefix = np.full((data.shape[0], 1), T_LABEL)
    data = np.hstack([prefix, data])
    # noinspection PyTypeChecker
    np.savetxt(sys.stdout, data, delimiter=T_SEP, fmt='%s')


def parse_dig_result(input_file):
    """Extract invariants from a DIG result file."""
    temp = read(input_file).strip().split('\n')[1:]
    preds = [x.split('.', 1)[1].strip() for x in temp]
    return [dig_mod_repair(p) for p in preds]


def is_num(x: str) -> bool:
    """Test if expression is a negative or positive number."""
    return (x[1:] if x and x[0] == '-' else x).isnumeric()


def tokenize(plain: str, tokens: List[str] = None) -> PT:
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
    tokens_ = tokens or TOKENS
    exists = [x for x in tokens_ if re.search(x, plain)]
    terms = re.split(f'({WSP})', plain.replace(' ', WSP))
    for x in exists:
        tmp = terms
        n = len(terms) - 1
        for i in range(n, -1, -1):
            curr = terms[i]
            terminal = curr in tokens_ or is_num(curr)
            if not terminal and re.search(x, curr):
                parts = [p for p in re.split(f'({x})', curr) if p]
                before = tmp[:i] if i > 0 else []
                after = tmp[i + 1:] if i < n else []
                tmp = before + parts + after
        terms = tmp
    return terms


def pad_neg(value: T_DTYPE) -> str:
    """Parenthesize negative values."""
    return f'({value})' if \
        str(value).isnumeric() and value < 0 else str(value)


def qt_fmt(value: T_DTYPE):
    """Express values as Q(n, d)."""
    frac = Fraction(str(value))
    return (pad_neg(frac.numerator) if frac.denominator == 1 else
            f'Q({frac.numerator},{frac.denominator})')


def dig_mod_repair(expr):
    """Rewrites a DIG modulo to a Python/SMT-compat format."""
    if '===' and 'mod' in expr:
        pre, post = expr.split('===', 1)  # ___, X (mod Y)
        post = post.replace('(', '').replace(')', '')  # ___ mod ___
        eqv, cong = post.split('mod', 1)
        pre, cong, eqv = [x.strip() for x in (pre, cong, eqv)]
        return f'({pre}) % {cong} == {eqv}'  # construct term
    return expr


def sym_min(*vs):
    m = vs[0]
    for v in vs[1:]:
        m = If(v < m, v, m)
    return m


def sym_max(*vs):
    m = vs[0]
    for v in vs[1:]:
        m = If(v > m, v, m)
    return m


def sym_minmax(term: str):
    for alt, mtc in [('sym_min', 'min'), ('sym_max', 'max')]:
        term = alt if term == mtc else term
    return term


def to_assert(var: List[str], val, pred: PT, smt: bool = False) -> P:
    """Construct a numerical assertion.

    Arguments:
        var: variable names.
        val: variable values.
        pred: a tokenized assertion.
        fmt: value formatter
        smt: convert Python symbols to SMT-lib

    Returns:
        A string expression where all variables are replaced with
        numerical values.
    """
    fmt_ = qt_fmt if T_DTYPE == 'd' else pad_neg
    dct = dict(zip(var, val))
    subst = [(fmt_(dct[x]) if x in var else x) for x in pred]
    subst = [sym_minmax(x) for x in subst] if smt else subst
    subst = [(' ' if x == WSP else x) for x in subst]
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

    for p in predicates:
        solver.reset()
        pred, cex, sc = tokenize(p, TOKENS), '', None
        idx, occ = zip(*[c for c in enumerate(var) if c[1] in pred])
        literals = []
        for val in np.unique(data[:, idx], axis=0):
            lit = to_assert(occ, val, pred)
            literals.append(lit)
            try:
                solver.add(eval(lit))
            except z3types.Z3Exception:
                sc, cex = '⚠ symbolic', lit
        if not sc and (sc := solver.check()) != sat:
            all_true = False
            cex = ' '.join(find_cex(literals))
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
        assert_ = to_assert(in_vars, data, expr)
        result = eval(assert_)
        result = list(result) if isinstance(result, Iterable) \
            else [result]
        data += result
    return data


def generate(f_name):
    """Generate random function traces based on config template."""
    conf = read_yaml(F_CONFIG)
    if f_name not in conf:
        raise Exception(f'No generator known for {f_name}\n'
                        'Likely mismatch in Makefile vs. inputs')
    fun = Namespace(**conf[f_name])
    pred = tokenize(fun.expr, TOKENS)
    f_in = fun.vin if fun.vin else {}
    vin, ranges = list(f_in.keys()), list(f_in.values())
    v_out = (fun.vo if isinstance(fun.vo, list)
             else [fun.vo] if fun.vo else [])
    data = [rand_data(vin, ranges, pred, len(v_out))
            for _ in range(fun.n)]
    construct_trace(vin + v_out, data)


def stats(dir_path):
    """Display statistics about a directory."""
    files = [f for f in listdir(dir_path)
             if f.endswith(".csv") and '_' in f]
    if files:
        cats = [f.split('_', 1)[0] for f in files]
        vl = [len(read_trace(join(dir_path, f))[1]) for f in files]
        pt, ct = Counter(cats), Counter(vl)
        mn, mx = min(vl), max(vl)

        pt['Total'] = sum(pt.values())
        table1 = PrettyTable(list(pt.keys()), title='Traces by kind')
        table1.add_row(list(pt.values()))

        scope = range(mn, mx + 1)
        dct = {**dict([(x, 0) for x in scope]), **ct, 'Total': sum(vl)}
        table2 = PrettyTable(
            list(dct.keys()), title='Variable frequencies')
        table2.add_row(list(dct.values()))

        conf = read_yaml(F_CONFIG)
        table3 = PrettyTable(
            ['#', 'Name', 'Formula', 'Ranges', 'Samples', 'Comments'],
            title='Benchmark details', align='l', min_width=6)
        fmt = lambda x: f' ∈ {x}' if x.startswith('[') else f'={x}'
        for i, (name, opts) in enumerate(sorted(conf.items())):
            fun = Namespace(**conf[name])
            nm = name.split('_')[1]
            vin = fun.vin if fun.vin else {}
            uniq_v = set([str(x) for x in vin.values()])
            uv = dict([(vl, '') for vl in uniq_v])
            for k, val in vin.items():
                uu = uv[str(val)]
                uv[str(val)] = (k if uu == '' else f'{uu}, {k}')
            fm = fun.formula
            for x in ['+', '-', '=', '≤', '%']:
                fm = fm.replace(f' {x} ', x)
            desc = ' '.join([f'{k}{fmt(r)}' for r, k in uv.items()])
            comm = fun.comment.replace('#', '') \
                .replace('combines', 'comb') \
                if 'comment' in fun else ''
            table3.add_row([i+1, nm, fm, desc, fun.n, comm])

        print(table1, end='\n\n')
        print(table2, end='\n\n')
        print(table3)


def score(dir_path):
    """Given the known invariant, and the inferred candidates,
    test how many correct invariants are recovered."""
    files = [f for f in listdir(dir_path) if f.endswith(".dig")]
    sources = [input_csv(b_name(f)) for f in files]
    f_s = [x for x in zip(files, sources) if isfile(x[1])]
    headers = 'Benchmark,V,∑,=,≤,%,↕,✔'
    table = PrettyTable(headers.split(','), align='r')
    table.align[table.field_names[0]] = 'l'
    conf = read_yaml(F_CONFIG)

    for f, src in sorted(f_s):
        name = Path(f).stem
        vrs = read_trace(src)[1]
        goal = conf[name]['goal']
        goals = goal if (isinstance(goal, list)) else [goal]

        # result statistics
        res = parse_dig_result(join(dir_path, f))
        eqv, inq, mod, mx, inv = 0, 0, 0, 0, len(res)
        for term in res:
            pred = tokenize(term, TOKENS)
            inq += 1 if '<=' in pred else 0
            eqv += 1 if '==' in pred else 0
            mod += pred.count('%')
            mx += (pred.count('min') + pred.count('max'))
        assert inv == eqv + inq

        # equivalence check
        match, pool, resp = False, res[:], '✗'
        while pool and not match:
            term, i = pool.pop(), 0
            while i < len(goals) and not match:
                goal, i = goals[i], i + 1
                res, _ = term_eq(vrs, goal, term)
                resp = '?' if res == unknown else resp
                match = (res == unsat)

        table.add_row([
            name, len(vrs), inv, eqv, inq, mod,
            mx, ('✔' if match else resp)])
    print(table)


def term_eq(var_list, t1, t2) \
        -> Tuple[CheckSatResult, Optional[ModelRef]]:
    """Try to prove equivalence of two expressions.

    Arguments:
        var_list: list of variables, must include A U B.
        t1: expression A
        t2: expression B

    Returns:
        A pair of <result, model>.
        * The result is one of: unsat (== proved), unknown, or no.
        * If no, the model will be a counterexample.
    """
    ttk1, ttk2 = [tokenize(x) for x in (t1, t2)]
    for un_sup in ['log', 'sin', 'cos', 'tan']:
        if un_sup in ttk1 or un_sup in ttk2:
            return unknown, None
    # noinspection PyUnusedLocal
    z3v = [Int(vr) for vr in var_list]
    values = [f'z3v[{i}]' for i in range(len(var_list))]
    g = to_assert(var_list, values, ttk1, smt=True)
    f = to_assert(var_list, values, ttk2, smt=True)
    solver = Solver()
    solver.set('timeout', ENV['Z3_TO'])
    # try:
    solver.add(Not(eval(g) == eval(f)))
    res = solver.check()
    mod = solver.model() if res == sat else None
    return res, mod
    # except:
    #     print(f'Cannot parse {g} or {f}')
    #     return unknown, None

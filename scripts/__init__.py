from argparse import Namespace
from collections import Counter
from functools import reduce
from itertools import product
# noinspection PyUnresolvedReferences
from math import *
from os import listdir
from os.path import isfile, basename, splitext, join
from random import randint
from typing import Tuple

import numpy as np
import pandas as pd
import yaml
from prettytable import PrettyTable as PrettyT
from rich.progress import Progress
from z3 import *

from .env import *


def read(fn):
    """Reads a file into memory."""
    with open(fn, 'r') as fp:
        return fp.read()


def read_lines(fn):
    return read(fn).strip().split('\n')


def read_yaml(path):
    """Read (and parse) a yaml file"""
    with open(path, 'r', encoding='utf-8') as yml:
        return yaml.safe_load(yml)


def input_csv(bench_name):
    """Construct input data path."""
    return join(IN_DIR, f'{bench_name}.csv')


def b_name(file_path):
    """file name without path and extension."""
    return splitext(basename(file_path))[0]


def is_ds(f):
    return f.startswith("ds_")


def is_num(x: str) -> bool:
    """Test if expression is a negative or positive number."""
    return (x[1:] if x and x[0] == '-' else x).isnumeric()


def pad_neg(v: T_DTYPE) -> str:
    """Parenthesize negative values."""
    return f'({v})' if str(v).isnumeric() and v < 0 else str(v)


def as_list(x: Any) -> List[Any]:
    return (([x] if isinstance(x, str) else list(x))
            if isinstance(x, Iterable) else
            ([x] if x is not None else []))


def c_vars(conf):
    vin = conf['vin'] if 'vin' in conf and conf['vin'] else {}
    vo = conf['vo'] if 'vo' in conf else []
    return list(vin.keys()) + as_list(vo)


def lmap(f, iterable):
    return list(map(f, iterable))


def fresh_solver(sol=None):
    solver = sol or Solver()
    solver.reset() if sol else None
    solver.set("timeout", Z3_TO)
    return solver


def parse_times(input_file):
    """Parse times experiment results."""
    return [x.split(',') for x in read_lines(input_file)]


def parse_dig_result(input_file):
    """Extract invariants from a DIG result file."""
    return dig_p(read_lines(input_file))


def dig_p(lines: List[str]):
    """Parse lines of dig predicates"""
    pl = [x.split('.', 1)[1].strip() for x in lines if '.' in x]
    return [dig_mod_repair(p) for p in pl]


def sym_min(*vs):
    """Python min evaluation for Z3."""
    return reduce(lambda x, m: If(x < m, x, m), vs[1:], vs[0])


def sym_max(*vs):
    """Python max evaluation for Z3."""
    return reduce(lambda x, m: If(x > m, x, m), vs[1:], vs[0])


def dict_rev(dct):
    """Reverse dictionary keys and values."""
    uniq = set(map(str, dct.values()))
    mtc = lambda x: [k for k, y in dct.items() if str(y) == x]
    return dict([(uq, mtc(uq)) for uq in uniq])


def read_trace(path: str) -> Tuple[np.array, List[str], str]:
    """Reads a DIG trace into memory."""
    df = pd.read_csv(path, sep=T_SEP)
    idx_slice, variables, loc = [], [], df.columns[0]
    for i, c in enumerate(df.columns[1:]):
        if not c.lower().startswith('unnamed:'):
            if c2 := str(c).strip().replace(T_PREFIX, ''):
                idx_slice.append(i + 1)
                variables.append(c2)
    data = np.array(df.values[:, idx_slice], dtype=T_DTYPE)
    return data, variables, loc


def trace_to_csv(input_file: str):
    """Convert a DIG trace to a CSV file."""
    data, var, _ = read_trace(input_file)
    data = np.vstack([np.array(var), data])
    # noinspection PyTypeChecker
    np.savetxt(sys.stdout, data, delimiter=C_SEP, fmt='%s')


def csv_to_trace(input_file: str):
    """Convert a CSV file to a DIG trace."""
    init = pd.read_csv(input_file, sep=C_SEP)
    construct_trace(init.columns, init.values)


def construct_trace(vars_: List[str], values, fn=sys.stdout):
    np_val = np.array(values)
    int_test = np_val.astype(int)
    data = int_test if np.all(np_val == int_test) else np_val
    var = [f'{T_PREFIX}{x}' for x in vars_]
    data = np.vstack([np.array(var), data])
    prefix = np.full((data.shape[0], 1), T_LABEL)
    data = np.hstack([prefix, data])
    # noinspection PyTypeChecker
    np.savetxt(fn, data, delimiter=T_SEP, fmt='%s')


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
        tmp, n = terms, len(terms) - 1
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


def qt_fmt(value: T_DTYPE):
    """Convert a fractional numeric values to Q(n, d)."""
    if (s := str(value)).isnumeric():
        frac = Fraction(s)
        fn, fd = frac.numerator, frac.denominator
        return pad_neg(fn) if fd == 1 else f'Q({fn},{fd})'
    return value


def dig_mod_repair(expr):
    """Rewrites a DIG modulo to a Python/SMT-compat format."""
    if '===' and 'mod' in expr:
        pre, post = expr.split('===', 1)
        post = post.replace('(', '').replace(')', '')
        eqv, cong = post.split('mod', 1)
        pre, cong, eqv = [x.strip() for x in (pre, cong, eqv)]
        return f'({pre}) % {cong} == {eqv}'  # construct term
    return expr


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


def find_cex(pred: List[P], limit: int = 3) -> str:
    """Find (at most limit) failing assertions."""
    cex, solver, pool = [], None, pred[:]
    while pool and len(cex) < limit:
        lit, solver = pool.pop(), fresh_solver(solver)
        solver.add(eval(lit))
        if solver.check() != sat:
            cex.append(lit)
    return ', '.join(cex)


def check(fn: str) -> bool:
    """Sanity check to confirm DIG invariants are valid on a trace.

    Checks that DIG invariants are valid for the input data. Displays,
    at stdout, the evaluation result for every invariant.

    Arguments:
        fn (str): path to the DIG results file to check.

    Returns:
        True if all invariants are satisfactory.
    """
    src = input_csv(b_name(fn))
    predicates = parse_dig_result(fn)
    data, var = read_trace(src)[:2]
    solver, all_t, rows = None, True, []
    for p in predicates:
        solver = fresh_solver(solver)
        pred = tokenize(p, TOKENS)
        cex, sc, expr = '', None, []
        idx, occ = zip(*[c for c in enumerate(var) if c[1] in pred])
        for val in np.unique(data[:, idx], axis=0):
            expr.append(lit := to_assert(occ, val, pred))
            try:
                solver.add(eval(lit))
            except z3types.Z3Exception:
                pass  # '⚠ symbolic'
            if (sc := solver.check()) == unsat:
                all_t, cex = False, find_cex(expr)
        rows.append([p, sc, cex])
    table = PrettyT(["P(…)", "eval(P)", "CEX"])
    table.add_rows(rows)
    print(table)
    return all_t


def rand_data(in_v, ranges, expr, has_o) -> List[T_DTYPE]:
    """Calculate value of a function for random inputs.

    Given an expression with variables,
        1. Choose random value for each variable.
        2. Substitute all variables in expression with values.
        3. Evaluate the expression to get output value.

    Arguments:
        in_v: input variables that occur in expr.
        ranges: (min, max) of each variable.
        expr: literal (str) of a function to evaluate.
        has_o: true if evaluation returns values

    Raises:
        Exception: if `expr` contains variables not in `in_vars`
            or other expressions outside the Python math stdlib.

    Returns:
        A row of data, of selected inputs and the calculated output.
    """
    dt_v = lambda nx: randint(*nx) if isinstance(nx, list) else nx
    data = lmap(dt_v, ranges)
    res = as_list(eval(to_assert(in_v, data, expr))) if has_o else []
    return data + res


def generate(f_name):
    """Generate random function traces based on configuration."""
    if f_name not in (conf := read_yaml(F_CONFIG)):
        raise Exception(f'No generator known for {f_name}!')
    fun = Namespace(**conf[f_name])
    fin = fun.vin if fun.vin else {}
    p, has_o = tokenize(fun.expr, TOKENS), len(as_list(fun.vo)) > 0
    vrs, r = map(list, [fin.keys(), fin.values()])
    values = [rand_data(vrs, r, p, has_o) for _ in range(fun.n)]
    construct_trace(c_vars(conf[f_name]), values)


# noinspection PyPep8Naming
def stats(dir_path):
    """Display statistics about a directory."""
    is_trace = lambda f: f.endswith(".csv") and '_' in f
    if files := list(filter(is_trace, listdir(dir_path))):
        # traces stats
        pt = Counter([f.split('_', 1)[0] for f in files])
        pt['∑'] = sum(pt.values())
        T1 = PrettyT(list(pt.keys()), title='Traces by kind')
        T1.add_row(list(pt.values()))

        # variable frequencies
        vl = [len(read_trace(join(dir_path, f))[1]) for f in files]
        scope = [(x, 0) for x in range(min(vl), max(vl) + 1)]
        dct = {**dict(scope), **Counter(vl), ' ∑ ': sum(vl)}
        T2 = PrettyT(lmap(str, dct.keys()))
        T2.title = 'Variable counts (frequency)'
        T2.add_row(list(dct.values()))

        # datasets
        fmap = lambda f: map(len, read_trace(join(dir_path, f))[:2])
        vals = lambda f: list(reversed(list(fmap(f))))
        data = [[b_name(f)] + vals(f) for f in filter(is_ds, files)]
        T3 = PrettyT(['Name', 'V', 'N'], title='Datasets', align='l')
        T3.add_rows(sorted(data))

        # invariant configurations
        cf = read_yaml(F_CONFIG)
        fft = lambda f: f.replace(' ', '')
        kfm = lambda l: ','.join(sorted(l))
        rfm = lambda x: fft(x) if x.startswith('[') else f'={x}'
        formulae = [fft(x['formula']) for x in cf.values()]
        rng = [[kfm(k) + rfm(r) for r, k in dict_rev(vin).items()]
               for vin in [op['vin'] or {} for op in cf.values()]]
        T4 = PrettyT(title='Invariant benchmarks')
        T4.add_column('Name', list(cf), align='l')
        T4.add_column('V', lmap(len, lmap(c_vars, cf.values())))
        T4.add_column('N', [x['n'] for x in cf.values()])
        T4.add_column('Formula', formulae, align='l')
        T4.add_column('Ranges', [' '.join(x) for x in rng], align='l')

        print('\n\n'.join(map(str, [T1, T2, T3, T4])))


# noinspection PyPep8Naming
def score(dir_path):
    """Score analysis results at `dir_path`."""
    digs = lambda f: f.endswith(".dig") or f.endswith(".digup")
    is_t = lambda f: f.endswith(".time")
    files = list(filter(digs, listdir(dir_path)))
    srcs = [input_csv(b_name(f)) for f in files]
    conf = read_yaml(F_CONFIG)
    base_h = 'Detector,Benchmark,V,∑,=,≤,%,↕'.split(',')
    T1, T2, T3 = PrettyT(base_h + ['✔']), PrettyT(base_h), None

    for f, s in sorted([x for x in zip(files, srcs) if isfile(x[1])]):
        name, ext = b_name(f), f.rsplit('.', 1)[-1]
        res = parse_dig_result(join(dir_path, f))
        vrs = read_trace(s)[1]
        row = [ext, name, len(vrs), len(res)]
        stats_ = np.array([np.zeros(4)])
        if len(res):
            stats_ = np.array([[
                1 if '==' in pred else 0,
                1 if '<=' in pred else 0,
                pred.count('%'),
                pred.count('min') + pred.count('max')]
                for pred in [tokenize(term, TOKENS) for term in res]])
        row += np.sum(stats_, axis=0).astype(int).tolist()

        if not is_ds(f):
            mtc, resp = False, '✗'
            pool = list(product(as_list(conf[name]['goal']), res))
            while pool and not mtc:
                res = term_eq(vrs, *pool.pop())
                mtc = res == unsat
                resp = '?' if res == unknown else resp
            row.append('✔' if mtc else resp)
        (T2 if is_ds(f) else T1).add_row(row)

    if times := list(filter(is_t, listdir(dir_path))):
        sec_f = lambda t: round(float(t) / T_FMT, 1)
        t_fmt = lambda t: (int(t) if T_FMT <= 1 else sec_f(t))
        res, sizes = {}, set()

        for f in sorted(times):
            rows = parse_times(join(dir_path, f))
            res[bm := b_name(f)] = {}
            tools = [(x, {}) for x in set([r[0] for r in rows])]
            res[bm].update(**dict(sorted(tools, reverse=True)))
            sizes.update(set([int(r[1]) for r in rows]))
            for row in rows:
                res[bm][row[0]][int(row[1])] = \
                    (t_fmt(dur) if (dur := row[-1]) else '')

        sizes = sorted(list(sizes))
        unit = 's' if T_FMT == 1000 else 'ms'
        head = 'Benchmark,Detector'.split(',')
        szh = [f'N={n}, {unit}' for n in sizes]
        T3 = PrettyT(head + szh, align='r')

        for bm, val in res.items():
            for dt, tms in val.items():
                times = [tms[n] if n in tms else '' for n in sizes]
                T3.add_row([bm, dt.lower()] + times)

    for x in [T1, T2, T3]:
        for i in [0, 1]:
            if x:
                x.align[x.field_names[i]] = 'l'
    print('\n\n'.join(map(str, filter(lambda x: x, [T1, T2, T3]))))


def match(fn):
    """Count matching invariants between Dig and DigUp.

    Arguments:
        fn: DigUp results file
    """
    fc = fn.replace('.digup', '.dig')
    trc, mtc, tgt = input_csv(b_name(fn)), 0, []
    if fn.endswith(".digup") and all(map(isfile, [fn, fc, trc])):
        src, tgt = map(parse_dig_result, [fn, fc])
        vars_ = read_trace(trc)[1]
        eqv = lambda x: term_eq(vars_, *x) == unsat
        if (n := len(src) * len(tgt)) > 0:
            with Progress() as progress:
                task = progress.add_task(str(n), total=n)
                for p in [product([t], src) for t in tgt]:
                    mtc += next((1 for x in p if eqv(x)), 0)
                    progress.update(task, advance=len(src))
    print(f'{b_name(fn)}: {mtc}/{len(tgt)}')


def term_eq(v_list: List[str], t1: str, t2: str):
    """Try to prove equivalence of two expressions.

    Arguments:
        v_list: list of variables, A U B.
        t1: expression A
        t2: expression B
    """
    t1, t2 = [tokenize(x) for x in (t1, t2)]
    if next((x for x in Z3_SKIP_W if x in t1 + t2), False):
        return unknown, None
    # noinspection PyUnusedLocal
    z3v = [Int(vr) for vr in v_list]
    vals = [f'z3v[{i}]' for i in range(len(v_list))]
    to_a = lambda x: to_assert(v_list, vals, x, smt=True)
    g, f = map(to_a, [t1, t2])
    solver = fresh_solver()
    solver.add(Not(eval(g) == eval(f)))
    return solver.check()

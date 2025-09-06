from argparse import Namespace
from collections import Counter
from itertools import product
# noinspection PyUnresolvedReferences
from math import *
from os import listdir
from os.path import isfile, basename, splitext, join
from pathlib import Path
from random import randint
from typing import Tuple

import pandas as pd
import yaml
from prettytable import PrettyTable
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


def is_num(x: str) -> bool:
    """Test if expression is a negative or positive number."""
    return (x[1:] if x and x[0] == '-' else x).isnumeric()


def pad_neg(v: T_DTYPE) -> str:
    """Parenthesize negative values."""
    return f'({v})' if str(v).isnumeric() and v < 0 else str(v)


def as_list(x: Any) -> List[Any]:
    return list(x) if isinstance(x, Iterable) else [x]


def vos(vout):
    return [vout] if isinstance(vout, str) else (vout or [])


def c_vars(conf):
    return list((conf['vin'] or {}).keys()) + vos(conf['vo'])


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
    m = vs[0]
    for v in vs[1:]:
        m = If(v < m, v, m)
    return m


def sym_max(*vs):
    m = vs[0]
    for v in vs[1:]:
        m = If(v > m, v, m)
    return m


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
    """Express values as Q(n, d)."""
    frac = Fraction(str(value))
    fn, fd = frac.numerator, frac.denominator
    return pad_neg(fn) if fd == 1 else f'Q({fn},{fd})'


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


def check(fn: str) -> bool:
    """Sanity check to confirm DIG invariants are valid.

    Checks that DIG invariants are valid for the input data. Displays,
    at stdout, the evaluation result for every invariant.

    Arguments:
        fn (str): path to the results file to check.

    Returns:
        True if all invariants are satisfactory; otherwise False.
    """
    src = input_csv(b_name(fn))
    if not (fn.endswith('.dig') and all(map(isfile, [src, fn]))):
        raise Exception(f'Invalid: {src} => {fn}')
    if not (predicates := parse_dig_result(fn)):
        return True

    table = PrettyTable(["P(…)", "eval(P)", "CEX"])
    (data, var), solver = read_trace(src)[:2], Solver()
    all_true = True

    for p in predicates:
        solver.reset()
        pred, cex, sc, literals = tokenize(p, TOKENS), '', None, []
        idx, occ = zip(*[c for c in enumerate(var) if c[1] in pred])
        for val in np.unique(data[:, idx], axis=0):
            # lit = to_assert(occ, val, pred)
            literals.append(lit := to_assert(occ, val, pred))
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
        data += as_list(eval(to_assert(in_vars, data, expr)))
    return data


def generate(f_name):
    """Generate random function traces based on config template."""
    if f_name not in (conf := read_yaml(F_CONFIG)):
        raise Exception(f'No generator known for {f_name}!')
    fun = Namespace(**conf[f_name])
    pred = tokenize(fun.expr, TOKENS)
    f_in = fun.vin if fun.vin else {}
    vin, ranges = list(f_in.keys()), list(f_in.values())
    v_out = vos(fun.vo)
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

        pt['∑'] = sum(pt.values())
        table1 = PrettyTable(list(pt.keys()), title='Traces by kind')
        table1.add_row(list(pt.values()))

        scope = range(mn, mx + 1)
        dct = {**dict([(x, 0) for x in scope]), **ct, ' ∑ ': sum(vl)}
        table2 = PrettyTable(list(map(str, dct)))
        table2.title = 'Variable counts (frequency)'
        table2.add_row(list(dct.values()))

        ds = [f for f in files if f.startswith("ds_")]
        fmap = lambda f: map(len, read_trace(join(dir_path, f))[:2])
        vals = lambda f: tuple(reversed(list(fmap(f))))
        data = [(f.split('.')[0],) + vals(f) for f in ds]
        table3 = PrettyTable(['Name', 'V', 'N'])
        table3.align[table3.field_names[0]] = 'l'
        table3.title = 'Datasets'
        table3.add_rows(sorted(data))

        kfm = lambda l: ','.join(sorted(l))
        fmt = lambda x: x.replace(' ', '') \
            if x.startswith('[') else f'={x}'
        fft = lambda f: f.replace(' ', '')

        conf = read_yaml(F_CONFIG)
        cv = conf.values()
        data = [('Name', list(conf)),
                ('V', [len(c_vars(x)) for x in cv]),
                (' N ', [x['n'] for x in cv]),
                ('Formula', [fft(x['formula']) for x in cv]),
                ('Ranges', ranges := [])]

        for vin in [opts['vin'] or {} for opts in cv]:
            uniq = set(map(str, vin.values()))
            rgs = dict([(uq, []) for uq in uniq])
            for k, val in vin.items():
                rgs[str(val)].append(k)
            rg = [kfm(k) + fmt(r) for r, k in rgs.items()]
            ranges.append(' '.join(rg))

        table4 = PrettyTable(title='Invariant benchmarks', align='l')
        [table4.add_column(*c) for c in data]
        for i in range(len(data)):
            table4.align[table4.field_names[i]] = 'l'

        tables = map(str, [table1, table2, table3, table4])
        print('\n\n'.join(tables))


def score(dir_path):
    """Given the known invariant, and the inferred candidates,
    test how many correct invariants are recovered."""
    files = [f for f in listdir(dir_path) if
             f.endswith(".dig") or f.endswith(".digup")]
    sources = [input_csv(b_name(f)) for f in files]
    times = [f for f in listdir(dir_path) if f.endswith(".time")]
    f_s = [x for x in zip(files, sources) if isfile(x[1])]
    t1h = 'Detector,Benchmark,V,∑,=,≤,%,↕,✔'.split(',')
    t2h = 'Detector,Benchmark,V,∑,=,≤,%,↕'.split(',')
    tmh = 'Benchmark,Detector'.split(',')
    conf = read_yaml(F_CONFIG)
    t1, t2, tm = [], [], []

    for f, src in sorted(f_s):
        name, ext = Path(f).stem, Path(f).suffix[1:]
        vrs = read_trace(src)[1]
        is_ds = f.startswith('ds')

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
        row = [ext, name, len(vrs), inv, eqv, inq, mod, mx]

        if not is_ds:
            match, resp = False, ''
            goal = conf[name]['goal']
            goals = [goal] if isinstance(goal, str) else goal
            pool, resp = res[:], '✗'
            while pool and not match:
                term, i = pool.pop(), 0
                while i < len(goals) and not match:
                    goal, i = goals[i], i + 1
                    res = term_eq(vrs, goal, term)
                    resp = '?' if res == unknown else resp
                    match = (res == unsat)
            row.append(('✔' if match else resp))
        (t1 if not is_ds else t2).append(row)

    if times:
        results, sizes = {}, set()
        for f in sorted(times):
            bm = Path(f).stem
            results[bm] = {}
            for row in parse_times(join(dir_path, f)):
                tool, sz, dur = row[0], int(row[1]), row[-1]
                if tool not in results[bm]:
                    results[bm][tool] = {}
                tmp = ''
                if dur:
                    tmp = float(dur) / TIME_FMT
                    tmp = int(tmp) if TIME_FMT == 1 else round(tmp, 1)
                results[bm][tool][sz] = tmp
                sizes.add(sz)
        sizes = sorted(list(sizes))
        unit = 's' if TIME_FMT == 1000 else 'ms'
        tmh += [f'N={n}, {unit}' for n in sizes]
        for bm, val in results.items():
            for dt, tms in val.items():
                times = [tms[n] if n in tms else '' for n in sizes]
                tm.append([bm, dt.lower()] + times)

    for h, t in [(t1h, t1), (t2h, t2), (tmh, tm)]:
        if t:
            table = PrettyTable(h, align='r')
            for i in [0, 1]:
                table.align[table.field_names[i]] = 'l'
            table.add_rows(t)
            print(table, '\n')


def match(fn):
    """Count matching invariants between Dig and DigUp.

    Arguments:
        fn: DigUp results file
    """
    fc, bfc = fn.replace('.digup', '.dig'), b_name(fn)
    trc, mtc, tgt = input_csv(bfc), 0, []
    if fn.endswith(".digup") and all(map(isfile, [fn, fc, trc])):
        src, tgt = map(parse_dig_result, [fn, fc])
        vars_ = read_trace(trc)[1]
        eqv = lambda x: term_eq(vars_, *x) == unsat
        n = len(src) * len(tgt)
        with Progress() as progress:
            task = progress.add_task(str(n), total=n)
            for p in [product([t], src) for t in tgt]:
                mtc += next((1 for x in p if eqv(x)), 0)
                progress.update(task, advance=len(src))
    print(f'{bfc}: {mtc}/{len(tgt)}')


def term_eq(v_list: List[str], t1: str, t2: str):
    """Try to prove equivalence of two expressions.

    Arguments:
        v_list: list of variables, must include A U B.
        t1: expression A
        t2: expression B
    """
    tf = ['log', 'sin', 'cos', 'tan']
    t1, t2 = [tokenize(x) for x in (t1, t2)]
    if next((x for x in tf if x in t1 + t2), False):
        return unknown, None
    # noinspection PyUnusedLocal
    z3v = [Int(vr) for vr in v_list]
    vals = [f'z3v[{i}]' for i in range(len(v_list))]
    to_a = lambda x: to_assert(v_list, vals, x, smt=True)
    g, f = map(to_a, [t1, t2])
    solver = Solver()
    solver.set('timeout', Z3_TO)
    solver.add(Not(eval(g) == eval(f)))
    return solver.check()

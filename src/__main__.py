import argparse

from . import csv_to_trace, trace_to_csv, check, gen

TRACE, CSV, CHECK, GEN = 'trace,csv,check,gen'.split(',')


def main():
    parser = argparse.ArgumentParser(
        prog="utils", description="Helpful operations")
    parser.add_argument(
        'input_file',
        help="input file")
    parser.add_argument(
        '-a', '--action',
        action='store',
        choices=(TRACE, CSV, CHECK, GEN),
        dest='action',
        help='action to perform on input file'
    )
    args = parser.parse_args()
    if args.action == TRACE:
        csv_to_trace(args.input_file)
    elif args.action == CSV:
        trace_to_csv(args.input_file)
    elif args.action == CHECK:
        check(args.input_file)
    elif args.action == GEN:
        gen(args.input_file)
    else:
        raise Exception('Unknown action')


if __name__ == '__main__':
    main()

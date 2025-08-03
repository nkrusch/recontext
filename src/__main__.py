import argparse

from . import csv_to_trace, trace_to_csv, check, gen

TRACE, CSV, CHECK, GEN = 'trace,csv,check,gen'.split(',')


def main():
    parser = argparse.ArgumentParser(
        prog="utils", description="Helpful operations")
    parser.add_argument('file', help="the file on which to operate")
    parser.add_argument(
        '-a', '--action',
        choices=(TRACE, CSV, CHECK, GEN),
        action='store',
        dest='action',
        help='action to perform on file'
    )
    args = parser.parse_args()
    if args.action == TRACE:
        csv_to_trace(args.file)
    elif args.action == CSV:
        trace_to_csv(args.file)
    elif args.action == CHECK:
        check(args.file)
    elif args.action == GEN:
        gen(args.file)
    else:
        raise Exception('Unknown action')


if __name__ == '__main__':
    main()

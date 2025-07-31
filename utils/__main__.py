import argparse

from argparse import ArgumentParser

from . import Actions


def main():
    parser = argparse.ArgumentParser(
        prog="utils", description="Helpful operations")
    args = __parse_args(parser)
    Actions(args)


def __parse_args(parser: ArgumentParser, args=None):
    parser.add_argument(
        'input_file',
        help="input file")
    parser.add_argument(
        '-a', '--action',
        action='store',
        choices=Actions.ACTIONS,
        dest='action',
        help='action to perform on input file'
    )
    parser.add_argument(
        '-s', '--src',
        action='store',
        dest='source',
        help='dat source to check'
    )
    return parser.parse_args(args)


if __name__ == '__main__':
    main()

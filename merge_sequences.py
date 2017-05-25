#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import codecs
import argparse


# hack for python2/3 compatibility
from io import open

argparse.open = open


def create_parser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Merge parallel corporas")

    parser.add_argument(
        '--input', '-i', type=argparse.FileType('r'), required=True, nargs='+',
        metavar='PATH',
        help="Input texts (multiple allowed).")
    parser.add_argument(
        '--output', '-o', type=argparse.FileType('w'), required=True, nargs='+',
        metavar='PATH')

    return parser

if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()

    # read/write files as UTF-8
    args.input = [codecs.open(f.name, encoding='UTF-8') for f in args.input]
    args.output = [codecs.open(f.name, 'w', encoding='UTF-8') for f in args.output]

    sources, targets = args.input
    for line_from, line_to in zip(sources, targets):
        args.output[0].write(line_from)
        args.output[0].write(line_to)
        args.output[1].write(line_to)
        args.output[1].write(line_from)

    args.input = [f.close() for f in args.input]
    args.output = [f.close() for f in args.output]
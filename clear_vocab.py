#! /usr/bin/env python

import sys
import argparse


def create_parser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        '--threshold', type=int, default=0,
        help="Vocabulary threshold. Any word with frequency < threshold will be treated as OOV")

    return parser


parser = create_parser()
args = parser.parse_args()

for line in sys.stdin:
    line = line.replace("\n", "")
    word, freq = line.split()
    if int(freq) > args.threshold:
        print(line)

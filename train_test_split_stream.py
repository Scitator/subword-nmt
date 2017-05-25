#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import argparse

from itertools import islice
from sklearn.model_selection import train_test_split


def create_parser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Train-test split ")

    parser.add_argument(
        "--batch_size",
        type=int,
        default=1000000,
        help="Batch size for stream shuffling. (default: %(default)s)")

    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed. (default: %(default)s)")

    parser.add_argument(
        "--test_ratio",
        type=float,
        default=0.2,
        help="Test part. (default: %(default)s)")

    return parser

if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()

    outputs = ["train.txt", "test.txt"]
    outputs = [open(f, 'w') for f in outputs]

    lines = []

    for line in sys.stdin:
        lines.append(line)
        if len(lines) > args.batch_size:
            train_lines, test_lines = train_test_split(
                lines, test_size=args.test_ratio,
                random_state=args.seed)
            outputs[0].writelines(train_lines)
            outputs[1].writelines(test_lines)
            lines = []

    train_lines, test_lines = train_test_split(
        lines, test_size=args.test_ratio, random_state=args.seed)
    outputs[0].writelines(train_lines)
    outputs[1].writelines(test_lines)

    outputs = [f.close() for f in outputs]

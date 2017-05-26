#! /usr/bin/env python
"""
Generate vocabulary for a tokenized text file.
"""

import sys
import argparse
import collections

parser = argparse.ArgumentParser(
    description="Generate vocabulary for a tokenized text file.")
parser.add_argument(
    "--min_frequency",
    dest="min_frequency",
    type=int,
    default=0,
    help="Minimum frequency of a word to be included in the vocabulary.")
parser.add_argument(
    "--max_vocab_size",
    dest="max_vocab_size",
    type=int,
    help="Maximum number of tokens in the vocabulary")
parser.add_argument(
    "infile",
    nargs="?",
    type=argparse.FileType("r"),
    default=sys.stdin,
    help="Input tokenized text file to be processed.")
parser.add_argument(
    "--delimiter",
    dest="delimiter",
    type=str,
    default=" ",
    help="Delimiter character for tokenizing. Use \" \" and \"\" for word and char level respectively."
)
args = parser.parse_args()

# Counter for all tokens in the vocabulary
cnt = collections.Counter()

for line in args.infile:
    if args.delimiter == "":
        tokens = list(line.strip())
    else:
        tokens = line.strip().split(args.delimiter)
    tokens = [_ for _ in tokens if len(_) > 0]
    cnt.update(tokens)

# Filter tokens below the frequency threshold
if args.min_frequency > 0:
    filtered_tokens = [(w, c) for w, c in cnt.most_common()
                       if c > args.min_frequency]
    cnt = collections.Counter(dict(filtered_tokens))

# Sort tokens by 1. frequency 2. lexically to break ties
word_with_counts = cnt.most_common()
word_with_counts = sorted(
    word_with_counts, key=lambda x: (x[1], x[0]), reverse=True)

# Take only max-vocab
if args.max_vocab_size is not None:
    word_with_counts = word_with_counts[:args.max_vocab_size]

for word, count in word_with_counts:
    print("{}\t{}".format(word, count))

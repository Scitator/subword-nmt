#! /usr/bin/env python

import sys

for line in sys.stdin:
    line = line.lower().replace("\n", "")
    print(line)



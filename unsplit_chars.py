#! /usr/bin/env python

import sys

for line in sys.stdin:
    line = line.replace("\n", "").replace(" ", "").replace("_#_", " ")
    print(line)



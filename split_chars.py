#! /usr/bin/env python

import sys

for line in sys.stdin:
    line = " ".join(list(line.replace("\n", ""))).replace("   ", " _#_ ")
    print(line)



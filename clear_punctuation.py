#! /usr/bin/env python

import sys
import string
import re


word_regex = re.compile('[%s]' % re.escape(string.punctuation))

for line in sys.stdin:
    line = word_regex.sub("", line).strip().replace("\n", "")
    print(line)



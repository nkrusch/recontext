"""
Converts a csv file to a trace
"""
import sys

SEP1, SEP2 = ',', ';'
t = 'trace1;'
f0 = ord('a')

with open(sys.argv[1], 'r') as fp:
    raw = fp.read().strip().split('\n')

entries = [x.strip().split(SEP1) for x in raw]
cols = len(entries[0])

print(entries)
print(cols)
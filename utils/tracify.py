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
n = max([max([len(x) for x in e]) for e in entries])
d = [SEP2.join([x.rjust(n) for x in e]) for e in entries]
h = [SEP2.join([('I '+chr(i)).rjust(n) for i in range(f0, f0 + cols)])]
f = '\n'.join([t + x for x in h + d])
print(f)

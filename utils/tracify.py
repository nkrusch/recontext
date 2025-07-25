"""
Converts a csv file to a trace
"""
import sys

S1, S2, S3 = ',', ';', '\n'
T, F0 = 'trace1;', ord('a')

with open(sys.argv[1], 'r') as fp:
    raw = fp.read().strip().split('\n')

entries = [x.strip().split(S1) for x in raw]
n = max([max([len(x) for x in e]) for e in entries])
d = [S2.join([x.rjust(n) for x in e]) for e in entries]
h = [('I ' + chr(i)).rjust(n) for i in range(F0, F0 + len(entries[0]))]
f = S3.join([T + x for x in [S2.join(h)] + d])

print(f)

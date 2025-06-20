"""
Converts a (DIG) trace to a csv
"""
import sys

with open(sys.argv[1], 'r') as fp:
    raw = fp.read()
entries = [','.join(filter(lambda c: c, (map(
    lambda c: c.strip(), x.split(';')[1:]))))
           for x in raw.split('\n')
           if x and not x.strip().startswith('#')][1:]
print('\n'.join(entries))

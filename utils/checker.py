"""
Check consistency
"""

import numpy as np
import pandas as pd

INPUT = './traces/l_001.csv'
f = '2*x - y**2 + y - 2 == 0'
v = 'x,y'.split(',')
idx = (0, 1)

# convert f to this
pred = lambda x: 2*x[0] - x[1]**2 + x[1] - 2 == 0

# now check
data = np.array(pd.read_csv(INPUT, sep=';'))[:, 1:-1]
in_ = data[:, idx]
bits = np.apply_along_axis(pred, 1, data)
invalid = np.where(bits == 0)

print(data)
print(bits)
print(invalid)
print(pred, v)

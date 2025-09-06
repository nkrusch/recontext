import os
import re
from typing import List

import numpy as np

ENV = {'T_DTYPE': np.int64, 'Z3_TO': 60, 'C_SEP': ',',
       'IN_DIR': 'input/traces', 'F_CONFIG': 'inputs.yaml',
       'N_VAR': 5, 'TMP': '.tmp', 'STO': 60, 'TO': 600,
       **os.environ}

# Config files
IN_DIR, F_CONFIG, TMP = ENV['IN_DIR'], ENV['F_CONFIG'], ENV['TMP']

# Format configs
T_PREFIX, T_LABEL, T_SEP, C_SEP = 'I ', 'trace1', ';', ENV['C_SEP']
Z3_TO, TIME_FMT = ENV['Z3_TO'], 1  # 1=MS, 1000=S
TOTAL_TO, SUBPROC_TO = int(ENV['TO']), int(ENV['STO'])
PICK_N = int(ENV['N_VAR'])

# Tokenization of invariant expressions(in order)
__tkn = ('randint,else,for,and,not,max,min,mod,log,sin,cos,tan,'
         'if,in,or,===,==,**,<=,>=,(,),[,],*,-,+,/,%')
TOKENS = (re.escape(__tkn)).split(',') + [',']
WSP = '↡'  # a special symbol to mark spaces

P = str  # predicate type
PT = List[str]  # tokenized predicate type
T_DTYPE = ENV["T_DTYPE"]  # value type

import os
import re
from typing import List

import numpy as np

ENV = {'T_DTYPE': np.int64, 'Z3_TO': 60, 'C_SEP': ',',
       'IN_DIR': 'input/traces', 'F_CONFIG': 'inputs.yaml',
       'N_VAR': 5, 'TMP': '.tmp', 'STO': 60, 'TO': 600,
       'T_FMT': 1,  # 1=MS, 1000=S
       **os.environ}

# Config files
F_CONFIG = ENV['F_CONFIG']
IN_DIR = ENV['IN_DIR']
TMP = ENV['TMP']

# Format configs
C_SEP = ENV['C_SEP']
T_SEP = ';'
T_PREFIX = 'I '
T_LABEL = 'trace1'
SUBPROC_TO = int(ENV['STO'])
T_FMT = int(ENV['T_FMT'])
TOTAL_TO = int(ENV['TO'])
PICK_N = int(ENV['N_VAR'])
Z3_TO = ENV['Z3_TO']
Z3_SKIP_W = 'log,sin,cos,tan'.split(',')

# Tokenization of invariant expressions(in order)
__tkn = ('randint,else,for,and,not,max,min,mod,log,sin,cos,tan,'
         'if,in,or,===,==,**,<=,>=,(,),[,],*,-,+,/,%')
TOKENS = (re.escape(__tkn)).split(',') + [',']
WSP = '↡'  # a special symbol to mark spaces

P = str  # predicate type
PT = List[str]  # tokenized predicate type
T_DTYPE = ENV["T_DTYPE"]  # value type

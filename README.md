# Invariants

Explorations of finding numerical invariants in (generic) numerical data.


## Running various tools

**Prerequisites.**
git, make, and [Python](https://www.python.org/downloads/).

**Getting started.**
Clone the repository with submodules.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git

To pull submodules after clone, run `git submodule update --init`


### DIG

Setup   
 
    pip install sympy z3-solver beartype pycparser

Experiment

    (cd dig/src && echo "xy.csv" >> ../../out/xy_dig.txt 
        time python -O dig.py -log 0 ../../inputs/xy.csv -noss -nomp >> ../../out/xy_dig.txt) 


### TaCle

Setup
 
    (cd tacle && pip install . && pip install numpy==1.23.4)

Experiment

    python taclef.py inputs/xy.csv > temp && time (cd tacle && python -m tacle ../temp) && rm -rf temp


## Inputs

| Filename | Invariant(s)    |
|:---------|:----------------|
| `xy`     | `x - y = 0`     |
| `test`   | `2 * x + 3 = y` |

# Invariants

Explorations of finding numerical invariants in numerical data.

## Running various tools

**Prerequisites.** &nbsp; 
[git](https://git-scm.com/downloads), 
[make](https://www.gnu.org/software/make/), and 
[Python](https://www.python.org/downloads/).

**Getting started.**

1. Clone the repository with submodules.

       git clone --recurse-submodules https://github.com/nkrusch/invariants.git

   To pull submodules after clone, run `git submodule update --init`

2. Install dependencies

       pip install -r requirements.txt

**Experiments.** Run all experiments at once.

    make

The results are written to `results`.

## Inputs

See `inputs.yaml` for detailed information.
 
    DATASETS (ds)                                                              
    blink       https://archive.ics.uci.edu/dataset/754
    iris        https://archive.ics.uci.edu/dataset/53
    lt-fs-id    https://archive.ics.uci.edu/dataset/715
    wine        https://archive.ics.uci.edu/dataset/109
    
    FUNCTIONS (f)   
    f_***       math functions 

    LINEAR (l)
    001 -- 133  progam traces, from github.com/PL-ML/code2invbenchmarks/C_instances/c


Initially the Linear suite has 133 benchmarks, but we keep 49.
* 37 differ only on postcondition (combined)
* 38 are duplicates (removed)
* 9 are invalid (removed)
* 1|2, 3|4|5 - differ only on some variable range (combined)

       
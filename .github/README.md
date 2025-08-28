# Experiments on Discovering Invariants

This repository provides an experimental setting for invariant detection over numeric data.

With the provided tooling it is possible to:
* generate traces from known invariants,
* run invariant inference on traces using Dig, and
* alternatively, run the inference using Tacle.

Additionally, it is possible to:
* generate table plots of results (`make score`),
* generate statistics of inputs (`make stats`),  
* capture host machines details (`make host`), and
* run sanity check to confirm dig results are SAT (`make check`).
* convert between formats csv ↔ traces (`python -m src --help`)

**Repository organization**

     input           contains inputs 
     dig and tacle   (submodules) dynamic analyzers 
     src             all scripts for running experiments
     verified        all Dafny-verified codes

## Getting Started

**Prerequisites.** &nbsp; 
[git](https://git-scm.com/downloads), 
[make](https://www.gnu.org/software/make/), and 
[Python](https://www.python.org/downloads/).

**Steps.**

1. Clone the repository with submodules.

       git clone --recurse-submodules https://github.com/nkrusch/invariants.git

   To pull submodules after clone, run `git submodule update --init`

2. Install dependencies

       pip install -r requirements.txt

**Experiments.** Run all experiments at once.

    make

The results are written to `results`.

## About Inputs

See [`inputs.yaml`](../inputs.yaml) for detailed information about f/l inputs.
Details about datasets are at the associated links.
 
    DATASETS (ds)                                                              
    blink       https://archive.ics.uci.edu/dataset/754
    iris        https://archive.ics.uci.edu/dataset/53
    lt-fs-id    https://archive.ics.uci.edu/dataset/715
    wine        https://archive.ics.uci.edu/dataset/109
    wred        https://archive.ics.uci.edu/dataset/186
    
    FUNCTIONS (f)   
    f_***       pure math functions 

    LINEAR (l)
    001 -- 133  program traces

Some problems require extra user-supplied information to solve.
The [`config.txt`](../config.txt) defines input specific run options.
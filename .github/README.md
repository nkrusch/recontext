# Invariant Discovery Experiments

This repository provides an experimental setting for _dynamic invariant detection_ over numeric data.

With the repository tooling, it is possible to run invariant inference on numeric data using 
[Dig](https://github.com/dynaroars/dig/tree/dev) or [Tacle](https://github.com/ML-KULeuven/tacle)
on [input traces](../input).

## Getting Started

**Prerequisites.** &nbsp; 
[git](https://git-scm.com/downloads), 
[make](https://www.gnu.org/software/make/), and 
[Python](https://www.python.org/downloads/).

**Setup steps.** Clone the repository and install dependencies.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git
    cd invariants
    pip install -r requirements.txt

**Experiments.** Run all experiments at once.

    make

The results are written to `results` directory.

**Additional actions**

    make score                       : Generate table plots of inference results


## Inputs

* See [`inputs.yaml`](../inputs.yaml) for detailed descriptions of function and linear invariants.
* Details about datasets are available at the associated links.
* Some problems require user-supplied options (see [`config.txt`](../config.txt))
* To compute some statistics about inputs run `make stats`
* Dig analyzer expects traces [in `input/traces`]
* Tacle analyzer expects CSV [in `input/csv`]


    DATASETS (ds)                                                              
    blink       https://archive.ics.uci.edu/dataset/754
    iris        https://archive.ics.uci.edu/dataset/53
    lt-fs-id    https://archive.ics.uci.edu/dataset/715
    wine        https://archive.ics.uci.edu/dataset/109
    wred        https://archive.ics.uci.edu/dataset/186
    
    FUNCTION INVARIANTS (f)   
    f_***       pure math functions 

    LINEAR INVARIANT (l)
    001 -- 133  program traces


## Repository organization

     .
     ├─ dig             analyzer (submodule)
     ├─ input           contains inputs 
     ├─ src             all scripts for running experiments
     ├─ tacle           analyzer (submodule) 
     └─ verified        Dafny-verified codes

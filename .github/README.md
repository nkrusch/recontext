# Invariant discovery experiments

This repository provides an experimental setting for _dynamic invariant detection_ over numeric data.

With the repository tooling, it is possible to run invariant inference on numeric data using 
[Dig](https://github.com/dynaroars/dig/tree/dev) or [Tacle](https://github.com/ML-KULeuven/tacle)
on [input traces](../input).

## Getting Started

**Prerequisites.** &nbsp; 
[git](https://git-scm.com/downloads) and [make](https://www.gnu.org/software/make/) (reasonably recent) 
and [Python](https://www.python.org/downloads/) 3.11 or later.

The commands `python3` should resolve to the intended runtime.


**Setup steps.** Clone the repository and install dependencies.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git
    cd invariants
    python3 -m pip install -r requirements.txt

**Experiments.** Run all experiments at once.

    make

The results are written to `results` directory.

Generate plots of inference results:

    make score                       


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

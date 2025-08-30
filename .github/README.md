# Dynamic invariant discovery

This repository provides an experimental setting for _dynamic invariant detection_ over numeric data.
The environment is pre-configured with two detectors,
[Dig](https://github.com/dynaroars/dig/tree/dev) or [Tacle](https://github.com/ML-KULeuven/tacle),
and various input [traces](../input).
Some portions of the development are verified in Dafny.

## Getting Started

### 🖥️ Native host

**Prerequisites.** 
* [git](https://git-scm.com/downloads) and [make](https://www.gnu.org/software/make/) (reasonably recent) 
* [Python](https://www.python.org/downloads/) 3.11 or later.

Command `python3` should resolve to the intended runtime.

**Setup steps.** Clone the repository and install dependencies.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git
    cd invariants
    python3 -m pip install -r requirements.txt


## Experiments

Run all experiments at once.

    make

The results, including plots, are written to `results` directory.


**Digup** is a wrapper for dig, that partitions the input trace and yields intermediate results based on the partitions.
Running digup requires one positional argument: the input `[TRACE]`. Arguments after the trace are forwarded to Dig as-is.

```
python3 src/digup.py [TRACE] [DIG-ARGS]
```

## Inputs

* See [`inputs.yaml`](../inputs.yaml) for detailed descriptions of function and linear invariants.
* Details about datasets are available at the associated links.
* Some problems require user-supplied options (see [`config.txt`](../config.txt))
* To compute some statistics about inputs run `make stats`
* Dig analyzer expects traces [in `input/traces`]
* Tacle analyzer expects CSV [in `input/csv`]

<pre>
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
</pre>



## Repository Details

### Organization

     .
     ├─ 🗀 dig                 analyzer (submodule)
     ├─ 🗀 input               all input traces 
     ├─ 🗀 src                 scripts for running experiments
     ├─ 🗀 tacle               analyzer (submodule) 
     ├─ 🗀 verified            Dafny-verified codes
     ├─ config.txt             input-specific run options
     ├─ inputs.yaml            trace configurations (for generation)
     ├─ LICENSE                software license
     ├─ Makefile               useful commands
     └─ requirements.txt       Python dependencies

The verified directory contains:
* Verified linear benchmarks: extracted invariants are true invariants.
* Verified data mutation: we can maintain invariants under data perturbations.

### Licensing

* Developments in this repository are licensed under the MIT license.
* Dig and Tacle are submodules and have their own respective terms.
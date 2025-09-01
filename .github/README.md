# Dynamic invariant discovery

This repository provides an _experimental setting_ for _dynamic invariant detection_ over _numeric data_.
Invariant detection aims to find assertions that hold over all instances of the data.

The environment is pre-configured with two detectors, [Dig](https://github.com/dynaroars/dig/tree/dev) or [Tacle](https://github.com/ML-KULeuven/tacle), and many input [traces](#inputs).
The analyzers will have scalability issues with larger inputs. 
[Digup](../src/digup.py) is a wrapper for Dig that partitions the input trace, and yields inference results based on the partitions.

Select parts of the development are verified in Dafny.


## Getting Started

**Prerequisites.** &nbsp;
[git](https://git-scm.com/downloads), [make](https://www.gnu.org/software/make/), and
[Python](https://www.python.org/downloads/) (v3.10 or later)

**🖥️ Setup steps for native host.** Clone the repository and install dependencies.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git 
    cd invariants
    python3 -m venv venv && source venv/bin/activate
    python3 -m pip install -r requirements.txt


## Experiments

#### Run all experiments at once

    make

The results (including command logs) are written to `results` directory.

The `make` command will generate statistics of inputs traces and host machine,
runs all pre-configured experiments, and generates a plot of the results.
To run the same as **individual steps**:

<pre>
COMMAND             DESCRIPTION                             DURATION[^1]
────────────────────────────────────────────────────────────────────────
make stats          Gather statistics about input traces         < 1 min
make host           Capture host machine details                 < 1 min
make dig            Run Dig experiments                         ~ 30 min
make digup          Run Digup experiments                        ~ 5 min
make times          Run exec time experiments                   ~ 30 min
make score          Plot results                                 < 1 min
</pre>

[^1]: The duration estimates are based on `result.0`.

Run `make clean` to reset the `results` directory.    


#### Execute a single benchmark

    make results/[INPUT].[EXT]

* `[INPUT]` is a benchmark name (like `l_003`).
* `[EXT]` is the choice analyzer (`dig`, `digup`, or `tacle`). 
* Example `make results/l_003.dig`

#### Overridable Makefile options

<pre>
OPTION         DEFAULT              DESCRIPTION     
────────────────────────────────────────────────────────────────────────
PYTHON         python3              Path to Python runtime
OUT            results              Directory for writing results
TMP            .tmp                 Temporary files directory 
TO             60                   Analysis timeout in seconds
DOPT           (None)               Dig analysis options
T_SIZES        25 50 75 100         Trace sizes for times experiment
</pre>

The "times"-experiment runs until completion and is unaffected by the timeout.
It can be adjusted by changing the sample sizes.
For example, the following command will finish in about 10 minutes.

     make TO=30 T_SIZES="10 25"


## Inputs

* Dataset details are available at the associated links.
* Function and linear invariants are described in [`inputs.yaml`](../inputs.yaml).
* Some problems require user-supplied options, defined in [`config.txt`](../config.txt)
* Dig expects inputs as traces and tacle expects input in CSV format

<pre>
DATASETS (ds)                                                              
ds_blink         https://archive.ics.uci.edu/dataset/754
ds_iris          https://archive.ics.uci.edu/dataset/53
ds_lt-fs-id      https://archive.ics.uci.edu/dataset/715
ds_wine          https://archive.ics.uci.edu/dataset/109
ds_wred          https://archive.ics.uci.edu/dataset/186

FUNCTION INVARIANTS (f)   
f_***            pure math functions 

LINEAR INVARIANT (l)
l_001 -- l_133   program traces
</pre>


## Repository Details

### Organization

<pre>
 .
 ├─ 🗀 dig                 analyzer (submodule)
 ├─ 🗀 input               all input traces 
 ├─ 🗀 results.0           referential result for inspection
 ├─ 🗀 src                 scripts for running experiments
 ├─ 🗀 tacle               analyzer (submodule) 
 ├─ 🗀 verified            Dafny-verified codes
 ├─ config.txt             input-specific run options
 ├─ inputs.yaml            configurations for trace generation
 ├─ LICENSE                software license
 ├─ Makefile               useful commands
 └─ requirements.txt       Python dependencies
</pre>

The verified directory contains:
* Verified linear benchmarks: extracted invariants are true invariants.
* Verified data mutation: we can maintain invariants under data perturbations.

### Licensing

* Developments in this repository are licensed under the MIT license.
* Dig and Tacle are submodules and have their own respective terms.
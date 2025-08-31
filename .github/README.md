# Dynamic invariant discovery

**This repository provides an experimental setting for _dynamic invariant detection_ over numeric data.**
Invariant detection finds assertions in data that hold for all instances of the data.

The environment is pre-configured with two detectors, [Dig](https://github.com/dynaroars/dig/tree/dev) or [Tacle](https://github.com/ML-KULeuven/tacle) and many input [traces](#inputs).
[Digup](../src/digup.py) is modified version of Dig that partitions the input trace and yields intermediate results based on the partitions.
Select parts of the development are [verified](../verified) in Dafny.


## Getting Started

**Prerequisites.** 
* [git](https://git-scm.com/downloads) and [make](https://www.gnu.org/software/make/)
* [Python](https://www.python.org/downloads/) 3.10 or later

**🖥️ Setup steps for native host.** Clone the repository and install dependencies.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git
    cd invariants
    python3 -m pip install -r requirements.txt


## Experiments

Run **all experiments at once**.

    make

The results, including plots, are written to `results` directory.

The `make` command will generate statistics of inputs traces and host machine,
runs Dig on all available inputs, and generates a plot of the results.
To run the same steps as **individual steps**:

<pre>
COMMAND             DESCRIPTION     
────────────────────────────────────────────────────────────
make stats          Statistics about input traces
make host           Capture host machine details
make dig            Run all Dig experiments
make digup          Run all Digup experiments
make score          Plot results
</pre>

To run a **single benchmark**, run:

    make results/[INPUT].[EXT]

* `[INPUT]` is a benchmark (input) name, like `l_003`.
* `[EXT]` is the choice analyzer `dig`, `digup`, or `tacle`. 

Overridable **Makefile options**.

<pre>
OPTION      DEFAULT     DESCRIPTION     
────────────────────────────────────────────────────────────
PYTHON      python3     Python runtime
OUT         results     Directory for writing results
TMP         .tmp        Temporary files directory 
TO          600         Analysis timeout, in seconds
DOPT        (None)      Extra dig analysis options
</pre>

## Inputs

* Function and linear invariants are described in [`inputs.yaml`](../inputs.yaml).
* Dataset details are available at the associated links.
* Some problems require user-supplied options, defined in [`config.txt`](../config.txt)
* Dig expects inputs as traces and tacle expects CSV format

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
 ├─ 🗀 ref_result          referential result
 ├─ 🗀 src                 scripts for running experiments
 ├─ 🗀 tacle               analyzer (submodule) 
 ├─ 🗀 verified            Dafny-verified codes
 ├─ config.txt             input-specific run options
 ├─ inputs.yaml            trace configurations (for generation)
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
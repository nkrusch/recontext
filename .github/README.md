# Dynamic invariant discovery

This repository provides an _experimental setting_ for _dynamic invariant detection_ over _numeric data_.
Invariant detection aims to find assertions that hold over all instances of the data.

The environment is pre-configured with two detectors, [Dig](https://github.com/dynaroars/dig/tree/dev) or [Tacle](https://github.com/ML-KULeuven/tacle), and many input [traces](#inputs).
The analyzers will have scalability issues with larger inputs. 
[Digup](../src/digup.py) (a modified version of Dig) partitions the input trace, and yields inference results based on the partitions.

Select parts of the development are verified in Dafny.


## Getting Started

**Prerequisites.** &nbsp;
[git](https://git-scm.com/downloads) and [make](https://www.gnu.org/software/make/)
[Python](https://www.python.org/downloads/) 3.10 or later

**🖥️ Setup steps for native host.** Clone the repository and install dependencies.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git
    cd invariants
    python3 -m pip install -r requirements.txt


## Experiments

Run **all experiments at once**.

    make

The results are written to `results` directory.

The `make` command will generate statistics of inputs traces and host machine,
runs all pre-configured experiments, and generates a plot of the results.
To run the same as **individual steps**:

<pre>
COMMAND             DESCRIPTION     
────────────────────────────────────────────────────────────
make stats          Gather statistics about input traces
make host           Capture host machine details
make dig            Run Dig experiments
make digup          Run Digup experiments
make score          Plot results
</pre>

To execute a **single benchmark**, run:

    make results/[INPUT].[EXT]

* `[INPUT]` is a benchmark name, like `l_003`.
* `[EXT]` is the choice analyzer: `dig`, `digup`, `tacle`. 
* Example `make results/l_003.dig`

Overridable **Makefile options**.

<pre>
OPTION      DEFAULT     DESCRIPTION     
────────────────────────────────────────────────────────────
PYTHON      python3     Python runtime
OUT         results     Directory for writing results
TMP         .tmp        Temporary files directory 
TO          600         Analysis timeout in seconds
DOPT        (None)      Dig analysis options
</pre>

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
 ├─ 🗀 results.0           referential result
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
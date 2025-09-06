# Dynamic invariant discovery

This repository is an experimental setting for _dynamic invariant detection over numeric data_.
Invariant detection aims to find assertions that hold over all instances of the data.

The environment is pre-configured with two detectors, Dɪɢ and TᴀCʟᴇ, and many input traces.
The analyzers will have scalability issues with larger inputs. 
DɪɢUᴘ is a wrapper for Dɪɢ that partitions the input trace and yields inference results based on the partitions.

Select parts of the development are verified in Dafny.


## Getting Started

**🖥️ Setup for native hosts.** 

PREREQUISITES:
[git](https://git-scm.com/downloads), 
[bash](https://www.gnu.org/software/bash/),
[make](https://www.gnu.org/software/make/), and
[Python](https://www.python.org/downloads/) (v3.10 or later)

Clone the repository and install dependencies.
```bash
git clone --recurse-submodules https://github.com/nkrusch/invariants.git
cd invariants
python3 -m venv venv && source venv/bin/activate    # recommended
python3 -m pip install -r requirements.txt
```

The `venv` setup is for unix hosts. 
Follow [this guide &nearr;](https://docs.python.org/3/library/venv.html#creating-virtual-environments) on other hosts.


## Experiments

#### Run all experiments at once

    make

The results, including command logs, are written to `results` directory.

The `make` command will generate statistics of inputs traces and host machine,
runs all pre-configured experiments, and generates a plot of the results.
To run the same as **individual steps**:

<pre>
COMMAND             DESCRIPTION                                 DURATION
────────────────────────────────────────────────────────────────────────
make stats          Gather statistics about input traces         < 1 min
make host           Capture host machine details                 < 1 min
make dig            Run Dig experiments                          ~30 min
make digup          Run Digup experiments                         ~5 min
make times          Run exec time experiments                    ~30 min
make score          Plot results                                 < 1 min
</pre>

The duration estimates are based on `result.0`.

Run `make clean` to reset the `results` directory.    


#### Execute a single benchmark

    make results/[INPUT].[EXT]

* `[INPUT]` is a benchmark name (like `l_003`).
* `[EXT]` is the choice analyzer (`dig`, `digup`, or `tacle`). 
* For example `make results/l_003.dig`

#### Overridable Makefile options

<pre>
OPTION         DEFAULT              DESCRIPTION     
────────────────────────────────────────────────────────────────────────
PYTHON         python3              Path to Python runtime
OUT            results              Path to results directory
TMP            .tmp                 Directory for temporary files 
TO             90                   Analysis timeout in seconds
DOPT           (None)               Dig analysis options
T_SIZES        25 50 75 100         Trace sizes for times experiment
</pre>

The times experiment runs until completion independently of timeout.


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
 ├─ 🗀 digup               our modified analyzer
 ├─ 🗀 input               all input traces 
 ├─ 🗀 results.0           referential result for inspection
 ├─ 🗀 scripts             scripts for running experiments
 ├─ 🗀 tacle               analyzer (submodule) 
 ├─ 🗀 verified            Dafny-verified codes
 ├─ config.txt             input-specific run options
 ├─ inputs.yaml            configurations for trace generation
 ├─ LICENSE                software license
 ├─ Makefile               useful commands
 └─ requirements.txt       Python dependencies
</pre>

The `verified` directory contains:
* Verified linear benchmarks: extracted invariants are true invariants.
* Verified data mutation: we can maintain invariants under data perturbations.

### Licensing

* Developments in this repository are licensed under the MIT license.
* Dig and Tacle are submodules and have their own respective terms.

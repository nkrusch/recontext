# Dynamic Invariant Detection

This repository is an experimental setting for _dynamic invariant detection_.
Invariant detection aims to find assertions that hold over all instances of traced values.

The environment is pre-configured with two detectors, Dɪɢ and TᴀCʟᴇ, and many numerical input traces.
The analyzers will have scalability issues with larger inputs. 
DɪɢUᴘ is a wrapper for Dɪɢ that partitions the input trace and yields inference results based on the partitions.

Select parts of the development are verified in Dafny.


## Getting Started

### 🖥️ &nbsp; Setup for native hosts

Prerequisites:
[git](https://git-scm.com/downloads), 
[bash](https://www.gnu.org/software/bash/),
[make](https://www.gnu.org/software/make/), and
[Python](https://www.python.org/downloads/) (v3.10 or later).

**Clone the repository and install dependencies.**

```bash
git clone --recurse-submodules https://github.com/nkrusch/invariants.git
cd invariants
python3 -m venv venv && source venv/bin/activate    # recommended
python3 -m pip install -r requirements.txt
```

The included `venv` command is for POSIX/bash hosts. 
Follow [this guide &nearr;](https://docs.python.org/3/library/venv.html#creating-virtual-environments) on other hosts.

### 🐳 &nbsp; Setup for virtual environments

Prerequisites:
[Docker](https://docs.docker.com/engine/install).

**[10 min] Build and launch a container.**

```bash
docker build . -t rectx
docker run --rm -v "$(pwd)/results:/rectx/results" -it rectx:latest
```

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
make dig            Run Dɪɢ experiments                          ~30 min
make digup          Run DɪɢUᴘ experiments                         ~5 min
make times          Run exec-time experiments                    ~30 min
make score          Plot results                                 < 1 min
</pre>

Run `make clean` to reset the `results` directory.    


#### Execute a single benchmark

    make results/[INPUT].[EXT]

* `[INPUT]` is a benchmark name (like `l_003`).
* `[EXT]` is the choice analyzer (`dig`, `digup`, or `tacle`). 
* For example `make results/l_003.dig` runs linear problem #3 on Dɪɢ.

#### Overridable Makefile options

<pre>
OPTION       DESCRIPTION                                         DEFAULT             
────────────────────────────────────────────────────────────────────────
PYTHON       Path to Python runtime                              python3
DOPT         Dɪɢ analysis options
OUT          Path to results directory                           results
TMP          Directory for temporary files                          .tmp
SZ           Trace sizes for times experiment               25 50 75 100
TO           Analysis timeout in seconds                              90
</pre>

Times experiment runs until completion, ignoring timeout.
It can be adjusted by modifying the workloads `SZ`.


## Repository Details

### Organization

<pre>
 .
 ├─ 📁 dig                 [submodule] Dɪɢ analyzer 
 ├─ 📁 digup               our modified analyzer
 ├─ 📁 input               all input traces 
 ├─ 📁 logs                referential result for inspection
 ├─ 📁 scripts             scripts for running experiments
 ├─ 📁 tacle               [submodule] TᴀCʟᴇ analyzer 
 ├─ 📁 verified            Dafny-verified codes
 ├─ config.txt             input-specific run options
 ├─ Dockerfile             virtual runtime environment setup
 ├─ inputs.yaml            configurations for trace generation
 ├─ LICENSE                software license
 ├─ Makefile               useful commands
 ├─ readme.txt             artifact readme
 ├─ req.repro.txt          [frozen] Python dependencies
 └─ requirements.txt       Python dependencies
</pre>

The `verified` directory contains:
* Verified linear benchmarks - to show the extracted invariants are true invariants.
* Verified data mutation - to show we can maintain invariants under data perturbations.

Running the verifier requires [Dafny](https://dafny.org).

### Licensing

* Developments in this repository are licensed under the MIT license.
* The datasets in input/traces are licensed under the CC BY 4.0 license.
* Dɪɢ and TᴀCʟᴇ are submodules and have their own licensing terms.

### About Inputs

* Dataset details and licenses are available at the associated links.
* Function and linear invariants are described in `inputs.yaml`.
* Some problems require user-supplied options, defined in `config.txt`.
* Dɪɢ expects inputs as traces and TᴀCʟᴇ expects input in CSV format.

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
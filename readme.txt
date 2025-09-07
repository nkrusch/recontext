------------------------------------------------------------------------
INTRODUCTION
------------------------------------------------------------------------

The artifact is an experimental setting for dynamic invariant detection.

Invariant detection finds assertions that hold over all instances of
traced values. The environment is pre-configured with two detectors,
Dɪɢ and TᴀCʟᴇ, and many numerical input traces. The analyzers will have
scalability issues with larger inputs. DɪɢUᴘ is a wrapper for Dɪɢ that
partitions the input trace and yields inference results based on the
partitions. Select parts of the development are verified in Dafny.

The artifact includes
* An experimental setup to reproduce paper experiments (§3-4)
* All benchmarks, inputs, and source codes needed for experiments
* The full verification described in (§5)

Evaluation expectations
* Running a smoke test takes about 10 minutes.
* Full evaluation takes about 90 min (on a 8-core Linux host).
* Artifact execution requires Docker and no specialty hardware.

------------------------------------------------------------------------
FUNCTIONAL EVALUATION + SMOKE TEST
------------------------------------------------------------------------

This section contains the steps to perform a functional evaluation.

### Getting Started Guide

Prerequisites
 * Docker - https://docs.docker.com/engine/install
 * Operating system - any Docker-compatible platform
 * Internet - only container setup requires the host to be online
 * Memory - the container size is 1.77GB

① [Choose one] Load or build (~500s) a container

    docker load -i rectx.<arch>.tar

    docker build . -t rectx

② Launch the container

    docker run --rm -v "$(pwd)/results:/rectx/results" -it rectx:latest

The command mounts a shared directory on the container host.
Results of all experiments run inside the container will persist in this
shared directory after exiting the container.

### Source Code Organization

Besides the Python package dependencies, all source code is
included in the artifact.

     .
     ├─ 📁 dig                 Dig source code
     ├─ 📁 digup               source code of our prototype detector
     ├─ 📁 input/traces        all input traces
     ├─ 📁 logs                referential result from our experiments
     ├─ 📁 scripts             helper scripts for running experiments
     ├─ 📁 tacle               TaCle source code
     ├─ 📁 verified            Dafny-verified codes
     ├─ config.txt             input-specific run options
     ├─ Dockerfile             virtual runtime environment setup
     ├─ inputs.yaml            configurations for trace generation
     ├─ LICENSE                software license
     ├─ Makefile               pre-configured commands
     ├─ readme.txt             this readme
     ├─ req.repro.txt          Python dependencies (frozen)
     └─ requirements.txt       Python dependencies

### Step-by-Step Instructions: Reproducing Paper Claims

Which claims or results can be replicated:
- Experiments (Tables 1-4 in §3-4, except 3.4) and verification (§5).

Precisely state the resource requirements you used:
- see `logs/_host.txt` (in short Ubuntu 22.04.5, 8 cores, 64 GB RAM).

Provide a rough estimate of the experiment times:
- The times are based on `logs/_log.txt` and do not
  include containerization overhead.

Regarding tasks that require a large amount of resources:
- The experiment of §3.4s take about 16h.
  Reproduction requires extending the timeout (`make TO=54000`).
  We do not expect the AEC to repeat the experiment, but claim
  that it is in principle reproducible with the artifact
  (the smoke test and full eval do execute the workloads, but
  terminate with a timeout).

### Checking the verification (§5)

The `verified` directory contains
* Data mutation: maintains invariants under perturbations.
* Verified benchmarks to confirm consistency of linear invariants.

Check the data mutation verification by running:

    dafny verify verified/mutation.dfy

This should print "finished with 23 verified, 0 errors."

### Reproducing Experiments (§3-4)

The results, including command logs, are written to `results` directory.
* Tables 1, 3, and 4 will be written to `results/_results.txt`
* Table 2 will be written to `results/_inputs.txt`

#### [~10 min] A Smoke Test

    make TO=60 SZ=25

#### [~70 min] Full Evaluation

    make

The `make` command runs a sequence of other commands.
They generate statistics of traces and host machine,
run all pre-configured experiments, and generate table plots.

To run the same as *individual steps*:

    COMMAND        DESCRIPTION                            DURATION
    ────────────────────────────────────────────────────────────────
    make stats     Gather statistics of traces [Table 2]   < 1 min
    make host      Capture host machine details            < 1 min
    make dig       Run Dig experiments [Tables 1, 3]       ~30 min
    make digup     Run Digup experiments [Table 3]          ~5 min
    make times     Run exec time experiments [Table 4]     ~30 min
    make score     Plot all tables                         < 1 min

Run `make clean` to reset the `results` directory.

Overridable Makefile options

    OPTION       DESCRIPTION                               DEFAULT
    ────────────────────────────────────────────────────────────────
    OUT          Path to results directory                 results
    SZ           Trace sizes for times experiment     25 50 75 100
    TO           Benchmark timeout in seconds                   90

------------------------------------------------------------------------
REUSABLE EVALUATION
------------------------------------------------------------------------

The artifact reusability claims are:
* Documentation and setup facilitate reuse in new environments.
* Dependencies and platform support are documented.
* Artifact enables running experiments on new input traces.

### Native Execution from Sources

Platform support
  * ✔ POSIX - Tested: Linux 22.04, Darwin v11 (Intel), Darwin v15 (arm)
  * Windows compatibility is untested

Software prerequisites
 * bash:   https://www.gnu.org/software/bash/
 * make:   https://www.gnu.org/software/make/
 * Python: https://www.python.org/downloads/   (v3.10 or later)
 * Dafny:  https://dafny.org (v4.7.0 or later)

① [Optional] Create a virtual environment.

    python3 -m venv venv && source venv/bin/activate

For help, see: https://docs.python.org/3/library/venv.html

② Install Python dependencies.

    python3 -m pip install -r requirements.txt

The precise dependency environment that was used in the paper
experiments is documented in `req.repro.txt`.

### Executing Custom Workloads

The command format to run a single experiment is

    make results/[INPUT].[EXT]

* The `[INPUT]` is a benchmark name in `input/traces`.
* The `[EXT]` is the choice invariant detector: dig, digup, or tacle.
* E.g., `make results/l_003.dig` runs the linear problem #3 on Dɪɢ.

### Adding New Inputs: Example

This example can be evaluated in a Docker container on a native host.
The commands correspond to:
① create a comma-separated file,
② convert the CSV to an input trace,
③ run an experiment, and
④ inspect the result.

    echo "varA,varB
    1,7
    75,8
    5,12
    17,-4" > test.csv

    python3 -m scripts -a trace test.csv > input/traces/test.csv
    make results/test.dig
    cat results/test.dig

------------------------------------------------------------------------
📜️  LICENSING
------------------------------------------------------------------------

* Developments in this artifact are licensed under the MIT license.
* The UCI datasets in inputs are licensed under CC BY 4.0.
* The detectors Dig and Tacle have their own licensing terms.

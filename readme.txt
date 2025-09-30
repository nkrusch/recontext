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

Artifact evaluation expectations
 * A smoke test takes about 10 minutes (+ some setup time).
 * Full evaluation takes about 70 min (on an 8-core Linux host).
 * Execution requires Docker (amd or arm).
 * There are no specialty hardware requirements.
 

------------------------------------------------------------------------
SMOKE TEST & FUNCTIONAL EVALUATION
------------------------------------------------------------------------

This section explains how to reproduce the paper claims and complete
a functional evaluation.

The artifact includes:
 * An experimental setup to reproduce paper experiments of §3–4.
 * All benchmarks, inputs, and source codes used in the experiments.
 * The full verification described in §5.


Getting Started Guide
------------------------------------------------------------------------

Prerequisites
 * 🐳 Docker - https://docs.docker.com/engine/install
 * 🖥️ Operating system - any Docker-compatible platform
 * 🌐 Internet - only container build requires the host to be online
 * 🧠 Memory - the container size is about 1.5GB

① [<2 min] Build the container. On some machines you may need sudo.

    docker build . -t rectx

Alternatively, for a pre-built container, run:

    docker load -i [NAME].tar

② Launch the container.

    docker run --rm -v "$(pwd)/rdoc:/rectx/results" -it rectx:latest

The command mounts a shared directory (rdoc) on the host. This way,
the results of all experiments run inside the container will be
immediately visible on the host and persist after container exit.


Source Code Organization
------------------------------------------------------------------------

Except Python packages, all source code is included in the artifact.

     .                          
     ├─ 📁 dig                 Dɪɢ source code
     ├─ 📁 digup               source code of our prototype detector
     ├─ 📁 input/traces        all input traces
     ├─ 📁 logs                referential result from our experiments
     ├─ 📁 scripts             helper scripts for running experiments
     ├─ 📁 tacle               TᴀCʟᴇ source code
     ├─ 📁 verified            Dafny-verified codes
     ├─ Dockerfile             container build script
     ├─ LICENSE                software license (MIT)
     ├─ readme.txt             this readme
     ├─ requirements.txt       Python package dependencies
     └─ *                      other configuration files


Step-by-Step Instructions: Reproducing Paper Claims
------------------------------------------------------------------------

Which claims or results can be replicated:
 * Experiments (Tables 1-4 in §3-4, except §3.4) and verification (§5).

Precisely state the resource requirements you used:
 * see `logs/_host.txt` → Ubuntu 22.04.5, 8 cores, 64GB RAM.

Provide a rough estimate of the experiment times:
 * smoke test 10 min and full evaluation 70 min.
 * The times are based on `logs` and exclude containerization overhead.

Regarding tasks that require a large amount of resources:
 * The experiment of §3.4 takes about 16h. Reproduction requires
   only extending the timeout (`make TO=54000`). We do not expect the
   AEC to repeat the experiment, but claim that it is in principle
   reproducible with the artifact (the evaluations commands do execute
   the workloads, but terminate with a timeout).


Checking The Verification (§5)
------------------------------

The `verified` directory contains:
 * Data mutation algorithm to maintain invariants under perturbations.
 * Verified benchmarks to confirm consistency with linear invariants.

Check the data mutation verification by running:

    dafny verify verified/mutation.dfy

This should print "finished with 18 verified, 0 errors."

To confirm the development matches the paper description, manually
review the following parts of verified/mutation.dfy.
 * Fig. 4 type definitions: L15–28
 * Fig. 5 correctness: L35–48 + L75–79
 * Fig. 6 mutations: L90–105 + L179–192

Some identifiers are changed for paper presentation (paper → code):
 * PreservingMutation → ControlledMutation
 * CorrectTraceMutation → MutableHold
 * VectorMutation → VectMutation
 * MutationCorrect → MutableVecCorrect
 * ImmutableCorrect → ImmutableVecCorrect
 * EnsureImmutable → EnsureImmVector
 * EnsureMutation → EnsureMutVector
 * ψ → mutables-type
 * φ → immutables-type


Reproducing Experiments (§3-4)
------------------------------

[~10 min] A SMOKE TEST

    make TO=60 SZ=25

[~70 min] FULL EVALUATION

    make

The make-command just runs a sequence of other commands.
They generate statistics of traces and host machine, run all
experiments, and generate table plots.

To run the same as individual steps:

    COMMAND        DESCRIPTION                            DURATION
    ────────────────────────────────────────────────────────────────
    make stats     Gather statistics of traces [Table 2]   < 1 min
    make host      Capture host machine details            < 1 min
    make dig       Run Dɪɢ experiments [Tables 1, 3]       ~30 min
    make digup     Run DɪɢUᴘ experiments [Table 3]          ~5 min
    make times     Run exec-time experiments [Table 4]     ~30 min
    make score     Plot all tables                         < 1 min

Run `make clean` to reset `results` directory.

Overridable Makefile options

    OPTION       DESCRIPTION                               DEFAULT
    ────────────────────────────────────────────────────────────────
    OUT          Path to results directory                 results
    SZ           Trace sizes for times experiment     25 50 75 100
    TO           Benchmark timeout in seconds                   90


Matching Experiment Results with Paper (§3-4)
---------------------------------------------

The experiment results are written to `results` directory
(if running in Docker, the directory appears as `rdoc` on the host).

Table 1 (first table in _results.txt)
 * NOTE: There is are transcription issues between the paper and the
   results in logs/_results.txt. The logged result is correct.
   The issue does not affect the main experimental claim (that Dig is
   effective at finding invariants) since passing ✔ cases are the same.
 * Symbol ? means SMT solver could not automatically prove equivalence
   between known and inferred invariants (appears as ✗ in paper).

Table 2 ("Invariant benchmarks" in _inputs.txt)
 * The function benchmarks appear in different order.

Table 3 (second table in _results.txt)
 * First 3 rows should match between paper and artifact.
 * "surveillance" in paper → "ds_blink" in artifact.
 * "intrusion" in paper → "ds_lt-fs-id" in artifact.
 * Last 2 rows (wine/*) will be incomplete (require longer timeout).
 * Variable and record counts are in _inputs.txt in "datasets" table.
 * time values are recorded in _log.txt.

Table 4 (third table in _results.txt)
 * Paper and artifact use different units (min/ms).
 * Exact times will vary by hardware, but the relative pattern should
   be observable, e.g., tacle times increase rapidly with input size.


------------------------------------------------------------------------
REUSABILITY GUIDE
------------------------------------------------------------------------

The artifact is reusable in the sense that it can be extended to
process new inputs, beyond the paper.

The reusability claims are:
 * Documentation and packaging facilitate reuse in new environments.
 * Artifact documents dependencies and platform support.
 * Artifact explains how to adapt the setup to new inputs.


Native Execution from Sources
------------------------------------------------------------------------

Platform support
 * YES for Unix-like operating systems:
   tested on Linux 22.04, macOS v11/Intel, and macOS v15 M1/ARM
 * Windows compatibility is untested

Software prerequisites
 * ◼️ bash   ≥3.2:      https://www.gnu.org/software/bash/
 * ⚒️ make   ≥4:        https://www.gnu.org/software/make/
 * 🐍 Python ≥3.10:     https://www.python.org/downloads/
 * 💛 Dafny  ≥4.7.0:    https://dafny.org

NOTE: Dafny is only needed for verification and not for experiments;
      this guide will work without Dafny.


① [Optional] At the sources root, create a fresh virtual environment.

    python3 -m venv venv && source venv/bin/activate

For help, the guide for creating virtual environments is at
https://docs.python.org/3/library/venv.html.

② Install Python dependencies.

    python3 -m pip install -r requirements.txt

The precise environment we used in the paper experiments is captured in
`req.repro.txt`. It can be used as an alternative source of Python
package installation.


Executing Custom Workloads
------------------------------------------------------------------------

The command format to run an experiment on a single input is

    make results/[INPUT].[EXT]

* [INPUT] is a benchmark name from `input/traces`.
* [EXT] is the choice invariant detector in { dig, digup, tacle }.
* For example `make results/l_003.dig` runs linear problem #3 on Dɪɢ.


Adding New Inputs
------------------------------------------------------------------------

The artifact can be extended to new numeric input traces.

This example can be executed in a Docker container or on a native host.
The commands correspond to:
 ① create a comma-separated value (CSV) file
 ② convert the CSV to a trace
 ③ run an experiment and
 ④ inspect the result.

    echo "varA,varB
    1,7
    75,8
    5,12
    17,-4" > test.csv

    python3 -m scripts -a trace test.csv > input/traces/test.csv
    make results/test.dig
    cat results/test.dig

As output, you should finally observe the invariants extracted from
the test data.

    trace1 (5 invs):
    1. -varB <= 4
    2. varB <= 12
    3. -varA + varB <= 7
    4. -varA - varB <= -8
    5. varA === 1 (mod 2)


------------------------------------------------------------------------
LICENSING
------------------------------------------------------------------------

* The source code introduced in the artifact is licensed under MIT.
* The UCI datasets at input/traces are licensed under CC BY 4.0.
* The Dɪɢ detector is licensed under MIT and TᴀCʟᴇ is unlicensed.

# Invariants

Explorations of finding numerical invariants in (generic) numerical data.

## Running various tools

**Prerequisites.**
[git](https://git-scm.com/downloads), 
[make](https://www.gnu.org/software/make/), and 
[Python](https://www.python.org/downloads/).

**Getting started.**

1. Clone the repository with submodules.

       git clone --recurse-submodules https://github.com/nkrusch/invariants.git

   To pull submodules after clone, run `git submodule update --init`

2. Install dependencies

       pip install -r requirements.txt

**Experiments.** Run all experiments at once.

       make

The results are written to `results`.

To run an individual experiment on `inputs/FILE`
- using DIG: `make results/FILE.dig`
- using TaCle: `make results/FILE.tacle`

## Inputs

| Filename | Invariant(s)    |
|:---------|:----------------|
| `xy`     | `x - y = 0`     |
| `test`   | `2 * x + 3 = y` |

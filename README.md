# Invariants

Explorations of finding numerical invariants in (generic) numerical data.


## Running various tools

**Getting started.**
Clone the repository with submodules.

    git clone --recurse-submodules https://github.com/nkrusch/invariants.git

To pull submodules after clone, run `git submodule update --init`

**Prerequisites** &nbsp;
[Docker 🐳](https://docs.docker.com/engine/install/) or 
[Python 🐍](https://www.python.org/downloads/)


<details>
<summary>🐳 <strong>DIG (Docker)</strong></summary>

Setup

    (cd dig && docker build . -t='dig')
    docker run -v "$(pwd)/inputs:/dig/inputs" -it --rm dig /bin/bash

Experiment

    time ~/miniconda3/bin/python3 -O dig.py -log 3 ../inputs/xy.csv 

</details>
<details><summary>🐍 <strong>DIG (native host)</strong></summary>

Setup   
 
    install sympy z3-solver beartype pycparser

Experiment

    (cd dig/src && time python -O dig.py -noss -nomp -log 3 ../../inputs/xy.csv) 

</details>
<details><summary>🐍 <strong>TaCle</strong></summary>

Setup
 
    (cd tacle && pip install . && pip install numpy==1.23.4)

Experiment

    python taclef.py inputs/xy.csv > temp && time  (cd tacle && python -m tacle ../temp) && rm -rf temp

</details>


## Inputs

| Filename | Invariant(s)    |
|:---------|:----------------|
| `xy`     | `x - y = 0`     |
| `test`   | `2 * x + 3 = y` |

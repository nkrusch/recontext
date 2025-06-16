# invariants

Invariant generation experiments.


## Running Experiments

Requires: [Docker](https://docs.docker.com/engine/install/)

1. Clone the repository with submodules
    
    ```bash
    git clone --recurse-submodules https://github.com/nkrusch/invariants.git
    ```
    
    <small>To pull submodules after clone: `git submodule update --init`</small>

2. Build a container

    ```
    (cd dig && docker build . -t='dig')
    ```

3. Run the container 
    
    ```
    docker run -v "$(pwd)/inputs:/dig/inputs" -it --rm dig /bin/bash
    ```
    
    `inputs` is a shared and mounted directory that can be edited outside the container.

4. Run some experiment, e.g., `test`

    ```
    time ~/miniconda3/bin/python3 -O dig.py  ../inputs/test.csv -log 3
    ```
   

## About inputs

| Filename | Invariant(s)    |
|:---------|:----------------|
| `xy`     | `x - y = 0`     |
| `test`   | `2 * x + 3 = y` |

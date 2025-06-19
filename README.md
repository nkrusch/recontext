# invariants

Invariant generation experiments.


**Inputs**

| Filename | Invariant(s)    |
|:---------|:----------------|
| `xy`     | `x - y = 0`     |
| `test`   | `2 * x + 3 = y` |



## Running Experiments


**Getting started.**
Clone the repository with submodules.
    
```bash
git clone --recurse-submodules https://github.com/nkrusch/invariants.git
```

<small>To pull submodules after clone: `git submodule update --init`</small>


### DIG

Requires: [Docker](https://docs.docker.com/engine/install/)

1. Build and run a container

    ```
    (cd dig && docker build . -t='dig')
    docker run -v "$(pwd)/inputs:/dig/inputs" -it --rm dig /bin/bash
    ```
    
    `inputs` is a shared and mounted directory that can be edited outside the container.

2. Run some experiment, e.g., `test`

    ```
    time ~/miniconda3/bin/python3 -O dig.py  ../inputs/test.csv -log 3
    ```

### TaCle

1. Install Python dependencies
 
   ```
   (cd tacle && pip install . && pip install numpy==1.23.4)
   ```

2. Run some experiment, e.g., `test`

   ```
   python taclef.py inputs/test.csv > temp && time  (cd tacle && python -m tacle ../temp) && rm -rf temp 
   ```


# Invariants

Explorations of finding numerical invariants in (generic) numerical data.


**Inputs**

| Filename | Invariant(s)    |
|:---------|:----------------|
| `xy`     | `x - y = 0`     |
| `test`   | `2 * x + 3 = y` |



## Running various tools


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

2. Run some experiment 

    ```
    time ~/miniconda3/bin/python3 -O dig.py  ../inputs/xy.csv -log 3
    ```

### TaCle

Requires: [Python](https://www.python.org/downloads/)

1. Install Python dependencies
 
   ```
   (cd tacle && pip install . && pip install numpy==1.23.4)
   ```

2. Run some experiment 

   ```
   python taclef.py inputs/xy.csv > temp && time  (cd tacle && python -m tacle ../temp) && rm -rf temp 
   ```

   Some arguments: `-t` shows identified tables

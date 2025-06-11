# invariants

Invariant generation experiments

Clone with submodules

```bash
git clone --recurse-submodules https://github.com/nkrusch/invariants.git
```

<small>Pull submodules after clone: `git submodule update --init`</small>


Build a container

```
(cd dig && docker build . -t='dig')
```

Run the container (`inputs` is a shared & mounted directory) 

```
docker run -v "$(pwd)/inputs:/dig/inputs" -it --rm dig /bin/bash
```

Run some experiment, e.g., `inputs/test.csv`

```
time ~/miniconda3/bin/python3 -O dig.py  ../inputs/test.csv -log 3
```
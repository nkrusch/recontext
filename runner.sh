#  docker run -v "$(pwd)/inputs:/dig/inputs" -it --rm dig /bin/bash
(time ~/miniconda3/bin/python3 -O src/dig.py  inputs/test.csv -log 3)
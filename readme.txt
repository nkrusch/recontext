
    maybe necessary?

    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    docker build . -t inv
    docker run -v "$(pwd)/results:/invariants/results" -it --rm inv

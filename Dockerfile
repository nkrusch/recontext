# export DOCKER_DEFAULT_PLATFORM=linux/amd64
# docker build . -t inv
# docker run -v "$(pwd)/results:/invariants/results" -it --rm inv

FROM python:3.11.9-alpine3.20

ARG HOME="/invariants"
ARG DAFNY_URL="https://github.com/dafny-lang/dafny/releases/download/v4.10.0/dafny-4.10.0-x64-ubuntu-20.04.zip"
ARG DAFNY_ARCH="dafny.zip"
ARG DAFNY_PATH="/usr/lib/"
ENV PATH=/root/.local/bin:$PATH:$DAFNY_PATH/dafny

RUN apk update && \
    apk upgrade apk --no-cache add \
    bash make git dotnet6-sdk unzip nano libc6-compat

RUN mkdir -p $HOME
COPY . $HOME
WORKDIR $HOME

RUN pip3 install -r requirements.txt

ADD --chmod=777 $DAFNY_URL $HOME/$DAFNY_ARCH
RUN unzip $HOME/$DAFNY_ARCH -d $DAFNY_PATH \
    && rm -rf $HOME/$DAFNY_ARCH

ENTRYPOINT ["/bin/sh"]
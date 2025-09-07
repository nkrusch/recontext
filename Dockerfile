FROM python:3.11.9-alpine3.20

LABEL org.opencontainers.image.authors="secret"
LABEL org.opencontainers.image.title="Recontext-artifact"
LABEL org.opencontainers.image.description="Dynamic invariant inference experiments"
LABEL org.opencontainers.image.source="secret"
LABEL org.opencontainers.image.licenses="MIT"

ARG HOME="/rectx"
ENV PATH="$PATH:/usr/local/dotnet:/root/.dotnet/tools:/root/.local/bin"
ARG REQ="req.repro.txt"

RUN apk update  \
    && apk upgrade  \
    && apk --no-cache add bash make perl nano dotnet8-sdk build-base libc6-compat

RUN dotnet tool install --global dafny --version 4.10.0

RUN mkdir -p $HOME
COPY . $HOME
WORKDIR $HOME
RUN pip3 install --no-cache-dir -r $REQ

ENTRYPOINT ["/bin/sh"]
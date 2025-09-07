FROM python:3.11.9-alpine3.20

LABEL org.opencontainers.image.authors="anonymous"
LABEL org.opencontainers.image.title="Recontext-artifact"
LABEL org.opencontainers.image.description="Dynamic invariant detection"
LABEL org.opencontainers.image.source="https://github.com/anonymous/recontext"
LABEL org.opencontainers.image.licenses="MIT"

ARG PROJ="/rectx"
ARG REQ="req.repro.txt"
ARG DAFNY_V="4.10.0"
ENV PATH="${PATH}:/root/.dotnet/tools"

RUN apk update  \
    && apk upgrade  \
    && apk --no-cache add bash make perl nano dotnet8-sdk build-base libc6-compat

RUN dotnet tool install --global dafny --version $DAFNY_V

RUN mkdir -p $PROJ
COPY . $PROJ
WORKDIR $PROJ
RUN pip3 install --no-cache-dir -r $REQ

ENTRYPOINT ["/bin/sh"]
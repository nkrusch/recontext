FROM python:3.11-slim

LABEL org.opencontainers.image.authors="anonymous"
LABEL org.opencontainers.image.title="Recontext-artifact"
LABEL org.opencontainers.image.description="Dynamic invariant detection"
LABEL org.opencontainers.image.source="https://github.com/anonymous/recontext"
LABEL org.opencontainers.image.licenses="MIT"

ARG PROJ="/rectx"
ARG REQ="req.repro.txt"
ARG DAFNY_V="4.10.0"
ENV PATH="${PATH}:/root/.dotnet/tools"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y \
    && apt install -qqy bash make procps wget time \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt update -y \
    && apt install -y dotnet-host \
    && apt install -y dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

RUN dotnet tool install --global dafny --version $DAFNY_V
RUN mkdir -p $PROJ
COPY . $PROJ
WORKDIR $PROJ
RUN pip3 install --no-cache-dir -r $REQ

ENTRYPOINT ["/bin/sh"]
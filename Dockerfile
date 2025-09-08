FROM python:3.11-slim

LABEL org.opencontainers.image.authors="Neea Rusch"
LABEL org.opencontainers.image.title="recontext"
LABEL org.opencontainers.image.description="Dynamic invariant detection"
LABEL org.opencontainers.image.source="https://github.com/nkrusch/recontext"
LABEL org.opencontainers.image.licenses="MIT"

ARG PROJ="/rectx"
ARG REQ="req.repro.txt"
ARG DAFNY_V="4.10.0"
ENV PATH="${PATH}:/root/.dotnet/tools"
ENV DOTNET_ROOT=/root/.dotnet
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -qqy bash make procps wget time libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y \
    && apt-get install -y apt-transport-https ca-certificates gnupg \
    && wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    &&  chmod +x ./dotnet-install.sh \
    && ./dotnet-install.sh --version latest --runtime aspnetcore \
    && ./dotnet-install.sh --channel 8.0 \
    && export PATH="/root/.dotnet/:$PATH" \
    && dotnet tool install --global dafny --version $DAFNY_V

RUN mkdir -p $PROJ
COPY . $PROJ
WORKDIR $PROJ
RUN pip3 install --no-cache-dir -r $REQ

ENTRYPOINT ["/bin/bash"]

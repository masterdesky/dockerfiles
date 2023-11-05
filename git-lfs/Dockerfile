# Base Image
FROM ubuntu:22.04

# Maintainer Information
LABEL maintainer="masterdesky@ELTE"

# Setting the default shell to Bash for string manipulation and 
# advanced scripting
SHELL ["/bin/bash", "-c"]

# Install Git and wget
RUN DEBIAN_FRONTEND=noninteractive \
    && apt update && apt upgrade -y && apt install -y \
      build-essential git curl \
    && rm -rf /var/lib/apt/lists/*
# Install git-lfs
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt install -y git-lfs \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

WORKDIR /app

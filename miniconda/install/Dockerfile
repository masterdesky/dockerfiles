# ---------------------------------------------------------------------
# 
# Manual setup of Miniconda in a base Linux image.
#
# Note: Assumes `bash` as the default shell for the container.
#
# Author: masterdesky @ ELTE (2023)
#
# ---------------------------------------------------------------------
# Base Image
FROM ubuntu:22.04

# Maintainer Information
LABEL maintainer="masterdesky@ELTE"

# Setting the default shell to Bash for string manipulation and 
# advanced scripting
SHELL ["/bin/bash", "-c"]

# Environment variable for the Conda installation path
ENV CONDA_ROOT=/opt/conda

# Install essential tools, clean up APT when done.
RUN DEBIAN_FRONTEND=noninteractive \
    apt update && apt upgrade -y && apt install -y \
      build-essential \
      git \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda to manage Python environments and dependencies
RUN wget -q -P /tmp \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p ${CONDA_ROOT} \
    && rm /tmp/Miniconda3-latest-Linux-x86_64.sh \
    # Adding Conda to .bashrc for interactive shell use
    && echo ". ${CONDA_ROOT}/etc/profile.d/conda.sh" >> ~/.bashrc

# Set working directory for container
WORKDIR /app
# ---------------------------------------------------------------------
# 
# Manual setup of Miniconda in a base Linux image. Additionally setups
# a new conda environment from an `environment.yml` file.
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

# Environment variable for the Conda environment descriptor YAML file
ENV ENV_DEFINE=/app/environment.yml

# Install essential tools, clean up APT when done.
RUN DEBIAN_FRONTEND=noninteractive \
    apt update && apt upgrade -y && apt install -y \
      build-essential \
      git \
      wget \
      awk \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda to manage Python environments and dependencies
RUN wget -q -P /tmp \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p ${CONDA_ROOT} \
    && rm /tmp/Miniconda3-latest-Linux-x86_64.sh \
    # Adding Conda to .bashrc for interactive shell use
    && echo ". ${CONDA_ROOT}/etc/profile.d/conda.sh" >> ~/.bashrc

# Create conda environment, and install additional packages
RUN source ${CONDA_ROOT}/etc/profile.d/conda.sh \
    && conda env create --file ${ENV_DEFINE} && conda clean --all \
    && ENV_NAME=$(grep 'name:' ${ENV_DEFINE} | awk '{print $2}') \
    && conda activate $ENV_NAME \
    && echo "install additional packages here" \
    && conda deactivate

# Set working directory for container
WORKDIR /app
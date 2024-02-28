# ---------------------------------------------------------------------
# 
# Dockerfile setup for ProteinChat, built on v0 of Vicuna Weights.
# The image creates two scripts under the `/app` directory after built,
# called `DOWNLOAD_DATA.sh` and `CONVERT_WEIGHTS.sh`. The first one
# downloads all necessary data to the `/data` directory
#
# Note: Assumes `bash` as the default shell for the container.
#
# Build:
# docker build -t proteinchat . -f Dockerfile
# Run:
# docker run --rm --gpus all -v /path/to/host/data:/data -it proteinchat /bin/bash
#
# Author: masterdesky @ ELTE (2023)
#
# ---------------------------------------------------------------------
# Base Image containing CUDA 11.3 for Ubuntu 20.04
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

# Maintainer Information
LABEL maintainer="masterdesky@ELTE"

# Setting the default shell to Bash for string manipulation and 
# advanced scripting
SHELL ["/bin/bash", "-c"]

# Avoid interactive prompts popping up during package install
ARG DEBIAN_FRONTEND=noninteractive

# Install necessary Linux packages
RUN apt update && apt upgrade -y \
    && apt install -y \
      build-essential git curl wget nano \
      # Needed for libGL.so.1 and libgthread-2.0.so.0
      libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install git-lfs
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt install -y git-lfs \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# Install Miniconda to manage Python environments and dependencies
RUN wget -q -P /tmp \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniconda3-latest-Linux-x86_64.sh \
    # Adding Conda to .bashrc for interactive shell use
    && echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# Clone proteinchat repository and prepare environment yaml
RUN git clone https://github.com/UCSD-AI4H/proteinchat/ /app \
    && sed -i 's\"PATH/TO/VICUNA-13B"\"/data/working-weights"\' /app/minigpt4/configs/models/minigpt4.yaml
# Create conda environment for proteinchat, and install additional packages
RUN source /opt/conda/etc/profile.d/conda.sh \
    # Addig conda-forge
    && conda config --add channels conda-forge \
    && conda config --set channel_priority flexible \
    # Installing proteinchat and extra dependencies
    && conda env create --file /app/environment.yml && conda clean --all \
    && conda activate proteinchat \
    && pip install einops \
    # Necessary for Vicuna weights v0
    pip install git+https://github.com/lm-sys/FastChat.git@v0.1.10 \
    && conda deactivate

# Prepare script to download LLaMA weights and Vicuna weights delta
ENV DL_SCRIPT=/app/DOWNLOAD_DATA.sh
RUN touch ${DL_SCRIPT} \
    # Download LLaMA weights
    && echo "git clone https://huggingface.co/huggyllama/llama-13b /data/llama-13b" >> ${DL_SCRIPT} \
    # Download Vicuna weights
    && echo "git clone https://huggingface.co/lmsys/vicuna-13b-delta-v0/ /data/vicuna-13b-delta-v0" >> ${DL_SCRIPT} \
    && chmod +x ${DL_SCRIPT}

# Prepare script to create the working Vicuna weights for MiniGPT4
ENV CV_SCRIPT=/app/CONVERT_WEIGHTS.sh
RUN touch ${CV_SCRIPT} \
    && echo "source /opt/conda/etc/profile.d/conda.sh" >> ${CV_SCRIPT} \
    && echo "conda activate proteinchat" >> ${CV_SCRIPT} \
    && echo "python -m fastchat.model.apply_delta \\" >> ${CV_SCRIPT} \
    && echo "    --base /data/llama-13b/ \\" >> ${CV_SCRIPT} \
    && echo "    --target /data/working-weights/ \\" >> ${CV_SCRIPT} \
    && echo "    --delta /data/vicuna-13b-delta-v0/" >> ${CV_SCRIPT} \
    && echo "conda deactivate" >> ${CV_SCRIPT} \
    && chmod +x ${CV_SCRIPT}

WORKDIR /app

FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu18.04
ARG UID
ARG GID

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt update && apt install -y \
    sudo build-essential git make nano \
    libc6-dbg gdb valgrind \
    openmpi-bin libopenmpi-dev \
    libhdf5-dev hwloc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid $GID gadget && \
    adduser --uid $UID --gid $GID --disabled-password --gecos "" gadget && \
    echo 'gadget ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
# Set the non-root user as the default user to use OpenMPI with
USER gadget

# Set the working directory
WORKDIR /home/gadget

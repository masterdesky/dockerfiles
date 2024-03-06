FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04
ARG UID
ARG GID

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    sudo build-essential git make nano xterm \
    libc6-dbg gdb valgrind \
    openmpi-bin libopenmpi-dev \
    libhdf5-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid $GID steps && \
    adduser --uid $UID --gid $GID --disabled-password --gecos "" steps && \
    echo 'steps ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
# Set the non-root user as the default user to use OpenMPI with
USER steps

# Clone the software repository from GitHub
RUN git clone https://github.com/eltevo/StePS.git /home/steps/StePS
#RUN chmod -R 755 /home/steps

# Set the working directory
WORKDIR /home/steps/StePS

#!/bin/bash

# Get your host's UID and GID
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# Build the Docker image
docker build --build-arg UID=$HOST_UID --build-arg GID=$HOST_GID -t steps . -f Dockerfile

# Run the Docker container
#docker run -v ~/data:/home/steps/data -it --rm steps /bin/bash

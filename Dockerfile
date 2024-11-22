# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to ensure non-interactive mode for APT
ENV DEBIAN_FRONTEND=noninteractive

COPY . /build
RUN chmod +x /build/bin/build.sh

# Set working dir
WORKDIR /build

# Update package lists, install required packages, and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        curl \
        wget \
        cpio \
        squashfs-tools \
        rsync \
        qemu-user \
        qemu-user-static && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set a default command
CMD ["make", "run"]
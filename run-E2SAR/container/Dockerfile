FROM ubuntu:22.04

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    build-essential \
    python3-pip \
    python3-dev \
    meson \
    ninja-build \
    pkg-config \
    cmake \
    libglib2.0-dev \
    libboost-all-dev \
    libssl-dev \
    libre2-dev \
    pybind11-dev \
    python3-pybind11 \
    autoconf \
    libtool \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Build and install gRPC
RUN git clone --recurse-submodules -b v1.54.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc \
    && cd grpc \
    && mkdir -p cmake/build \
    && cd cmake/build \
    && cmake -DgRPC_INSTALL=ON \
            -DgRPC_BUILD_TESTS=OFF \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            ../.. \
    && make -j$(nproc) \
    && make install \
    && cd ../.. \
    && rm -rf grpc

# Download and install E2SAR dependencies
RUN wget https://github.com/JeffersonLab/E2SAR/releases/download/E2SAR-main-0.1.4-ubuntu-22.04/e2sar-deps_0.1.4_amd64.deb \
    && dpkg -i e2sar-deps_0.1.4_amd64.deb \
    && rm e2sar-deps_0.1.4_amd64.deb

# Install Python packages
RUN pip3 install --no-cache-dir pybind11

# ARG for GitHub token (to be provided at build time)
ARG GITHUB_TOKEN

# Configure git to use HTTPS with token for all operations
RUN git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/" \
    && git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "git@github.com:" \
    && git config --global url."https://".insteadOf "git://"

# Update ldconfig to include /usr/local/lib
RUN ldconfig

# Clone and build E2SAR
RUN git clone --recursive https://github.com/JeffersonLab/E2SAR.git \
    && cd E2SAR \
    # Generate protobuf files first
    && cd udplbd/pkg/pb \
    && protoc --cpp_out=. loadbalancer.proto \
    && protoc --grpc_out=. --plugin=protoc-gen-grpc=`which grpc_cpp_plugin` loadbalancer.proto \
    && mkdir -p ../../../src/grpc \
    && cp loadbalancer.pb.h loadbalancer.pb.cc loadbalancer.grpc.pb.h loadbalancer.grpc.pb.cc ../../../src/grpc/ \
    && cd ../../.. \
    # Now build the project
    && BOOST_ROOT=/usr/local/ LD_LIBRARY_PATH=/usr/local/lib/ PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig \
       meson setup -Dpkg_config_path=/usr/local/lib/pkgconfig/:/usr/lib/lib64/pkgconfig/:/usr/lib/x86_64-linux-gnu/pkgconfig build \
    && cd build \
    && ninja

# Set environment variables
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/app/E2SAR/build/bin:$PATH

# Create separate entry points for sender and receiver
COPY entrypoint-sender.sh /app/
COPY entrypoint-receiver.sh /app/
RUN chmod +x /app/entrypoint-sender.sh /app/entrypoint-receiver.sh
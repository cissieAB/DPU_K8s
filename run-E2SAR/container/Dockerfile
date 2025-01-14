FROM ubuntu:22.04

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    build-essential \
    python3-pip \
    meson \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Download and install E2SAR dependencies
# Replace VERSION and DISTRO with appropriate values
ENV E2SAR_VERSION="E2SAR-main-0.1.4"
ENV DISTRO="ubuntu-22.04"
RUN wget https://github.com/JeffersonLab/E2SAR/releases/download/${E2SAR_VERSION}-${DISTRO}/e2sar-deps_0.1.4_amd64.deb \
    && dpkg -i e2sar-deps_0.1.4_amd64.deb \
    && rm e2sar-deps_0.1.4_amd64.deb

# Clone and build E2SAR
RUN git clone --recurse-submodules --depth 1 -b main https://github.com/JeffersonLab/E2SAR.git \
    && cd E2SAR \
    && BOOST_ROOT=/usr/local/ LD_LIBRARY_PATH=/usr/local/lib/ meson setup -Dpkg_config_path=/usr/local/lib/pkgconfig/:/usr/lib/lib64/pkgconfig/ build \
    && cd build \
    && ninja

# Set environment variables
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/app/E2SAR/build/bin:$PATH

# Create separate entry points for sender and receiver
COPY entrypoint-sender.sh /app/
COPY entrypoint-receiver.sh /app/
RUN chmod +x /app/entrypoint-sender.sh /app/entrypoint-receiver.sh
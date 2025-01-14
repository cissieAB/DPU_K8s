# E2SAR Container Setup

This directory contains the containerized version of E2SAR sender and receiver applications using Docker Compose for easy deployment and configuration.

## Prerequisites

- Docker and Docker Compose installed and running
- The `e2sar-container` image built from the provided Dockerfile

## Building the Container

Build the E2SAR container image from the Dockerfile in the current directory:

```bash
cd container/
docker build -t e2sar-container .
```

The build process will:
1. Use Ubuntu 22.04 as the base image
2. Install required system dependencies
3. Set up the E2SAR environment
4. Copy the entrypoint scripts for both sender and receiver

You only need to build the container once unless you make changes to the Dockerfile or entrypoint scripts.

## Running the Containers

### Basic Usage

1. Create a `.env` file with the required parameters:
```bash
# Required parameters
SENDER_IP=192.168.1.10
RECEIVER_IP=192.168.1.11
LB_IP=192.168.1.100

# Optional parameters (showing defaults)
MTU=9000
RATE=10
LENGTH=1000000
NUM_EVENTS=10000
BUF_SIZE=314572800
DURATION=30
PORT=19522
THREADS=1
```

2. Start the containers:
```bash
docker-compose up -d
```

### Configuration Options

All configuration is done through environment variables, which can be set in the `.env` file or passed directly to docker-compose.

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| SENDER_IP | Sender IP address | localhost |
| RECEIVER_IP | Receiver IP address | localhost |
| LB_IP | Load balancer IP address | localhost |
| MTU | MTU size | 9000 |
| RATE | Send rate | 10 |
| LENGTH | Message length | 1000000 |
| NUM_EVENTS | Number of events | 10000 |
| BUF_SIZE | Buffer size | 314572800 |
| DURATION | Test duration in seconds | 30 |
| PORT | Receiver port | 19522 |
| THREADS | Number of threads | 1 |

### Example Usage

1. Start with custom parameters using environment variables:
```bash
SENDER_IP=192.168.1.10 RECEIVER_IP=192.168.1.11 LB_IP=192.168.1.100 docker-compose up -d
```

2. Start with custom parameters using a .env file:
```bash
# Edit .env file with your parameters
docker-compose up -d
```

## Container Management

### View Container Logs
```bash
# View receiver logs
docker-compose logs receiver

# View sender logs
docker-compose logs sender

# Follow logs
docker-compose logs -f
```

### Stop and Remove Containers
```bash
# Stop containers
docker-compose down

# Stop containers and remove volumes
docker-compose down -v
```

## Network Configuration

The containers run in host network mode, which means they use the host's network stack directly. This is required for optimal performance in network testing scenarios.
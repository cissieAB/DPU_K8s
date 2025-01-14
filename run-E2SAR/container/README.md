 
 # E2SAR Container Setup

This directory contains the containerized version of E2SAR sender and receiver applications. The setup includes a script to easily start both containers with configurable parameters.

## Prerequisites

- Docker installed and running
- The `e2sar-container` image built from the provided Dockerfile

## Quick Start

1. Make the start script executable:
```bash
chmod +x start_containers.sh
```

2. Run the containers with minimum required parameters:
```bash
./start_containers.sh \
  --sender-ip <sender_ip> \
  --receiver-ip <receiver_ip> \
  --lb-ip <load_balancer_ip>
```

## Configuration Options

The `start_containers.sh` script supports the following parameters:

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| --sender-ip | Sender IP address | Required |
| --receiver-ip | Receiver IP address | Required |
| --lb-ip | Load balancer IP address | Required |
| --mtu | MTU size | 9000 |
| --rate | Send rate | 10 |
| --length | Message length | 1000000 |
| --num-events | Number of events | 10000 |
| --buf-size | Buffer size | 314572800 |
| --duration | Test duration in seconds | 30 |
| --port | Receiver port | 19522 |
| --threads | Number of threads | 1 |

## Example Usage

1. Basic usage with only required parameters:
```bash
./start_containers.sh \
  --sender-ip 192.168.1.10 \
  --receiver-ip 192.168.1.11 \
  --lb-ip 192.168.1.100
```

2. Advanced usage with custom parameters:
```bash
./start_containers.sh \
  --sender-ip 192.168.1.10 \
  --receiver-ip 192.168.1.11 \
  --lb-ip 192.168.1.100 \
  --mtu 9000 \
  --rate 20 \
  --length 2000000 \
  --duration 60 \
  --threads 4
```

## Container Management

### View Container Logs
```bash
# View receiver logs
docker logs e2sar-receiver

# View sender logs
docker logs e2sar-sender
```

### Stop and Remove Containers
```bash
# Stop containers
docker stop e2sar-sender e2sar-receiver

# Remove containers
docker rm e2sar-sender e2sar-receiver
```

## Network Configuration

The containers run in host network mode, which means they use the host's network stack directly. This is required for optimal performance in network testing scenarios.
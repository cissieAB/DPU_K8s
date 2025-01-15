# E2SAR Container Setup

This directory contains the containerized version of E2SAR sender and receiver applications. The same container image can be used to run either sender or receiver components on different machines.

## Prerequisites

- Docker installed and running
- Network connectivity between sender, receiver, and load balancer machines

## Building the Container

Build the E2SAR container image from the Dockerfile:

```bash
cd container/
docker build --build-arg GITHUB_TOKEN=your_token_here -t e2sar-container .
```

Note: You'll need a GitHub token with 'repo' permissions to clone the repositories during build.

## Deployment

The `deploy.sh` script provides a convenient way to deploy either sender or receiver components on different machines.

### Basic Usage

1. Make the deployment script executable:
```bash
chmod +x deploy.sh
```

2. Start the sender (on sender machine):
```bash
./deploy.sh sender --lb-ip <load_balancer_ip> --ip <sender_ip>
```

3. Start the receiver (on receiver machine):
```bash
./deploy.sh receiver --lb-ip <load_balancer_ip> --ip <receiver_ip>
```

### Configuration Options

The script supports the following parameters:

| Parameter | Description | Default | Component |
|-----------|-------------|---------|-----------|
| --lb-ip | Load balancer IP address | Required | Both |
| --ip | Local IP address | Required | Both |
| --mtu | MTU size | 9000 | Sender |
| --rate | Send rate | 10 | Sender |
| --length | Message length | 1000000 | Sender |
| --num-events | Number of events | 10000 | Sender |
| --buf-size | Buffer size | 314572800 | Both |
| --duration | Test duration in seconds | 30 | Receiver |
| --port | Receiver port | 19522 | Receiver |
| --threads | Number of threads | 1 | Receiver |

### Example Usage

1. Start sender with custom parameters:
```bash
./deploy.sh sender \
  --lb-ip 192.168.1.100 \
  --ip 192.168.1.10 \
  --rate 20 \
  --length 2000000 \
  --num-events 20000
```

2. Start receiver with custom parameters:
```bash
./deploy.sh receiver \
  --lb-ip 192.168.1.100 \
  --ip 192.168.1.11 \
  --threads 4 \
  --duration 60
```

## Container Management

### View Container Logs
```bash
# View sender logs
docker logs e2sar-sender

# View receiver logs
docker logs e2sar-receiver

# Follow logs
docker logs -f e2sar-sender
docker logs -f e2sar-receiver
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
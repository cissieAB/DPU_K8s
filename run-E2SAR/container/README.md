# E2SAR Container Setup

This directory contains the containerized version of E2SAR sender and receiver applications. The same container image can be used to run either sender or receiver components on different machines.

## Prerequisites

- Docker installed and running
- Network connectivity between sender and receiver machines

## Building the Container

Build the E2SAR container image from the Dockerfile:

```bash
cd container/
docker build --build-arg GITHUB_TOKEN=your_token_here -t e2sar-container .
```

Note: You'll need a GitHub token with 'repo' permissions to clone the repositories during build.

## Deployment

The `deploy.sh` script provides a convenient way to deploy either sender or receiver components on different machines. It supports two modes of operation:
1. Direct mode (peer-to-peer testing without load balancer)
2. Load balancer mode (using E2SAR load balancer)

### Basic Usage

1. Make the deployment script executable:
```bash
chmod +x deploy.sh
```

2. Direct Mode Testing:
   
   Start the receiver (on receiver machine):
   ```bash
   ./deploy.sh receiver --direct --ip <receiver_ip>
   ```

   Start the sender (on sender machine):
   ```bash
   ./deploy.sh sender --direct --ip <sender_ip> --target-ip <receiver_ip>
   ```

3. Load Balancer Mode:
   
   Start the receiver:
   ```bash
   ./deploy.sh receiver --lb-ip <load_balancer_ip> --ip <receiver_ip>
   ```

   Start the sender:
   ```bash
   ./deploy.sh sender --lb-ip <load_balancer_ip> --ip <sender_ip>
   ```

### Configuration Options

The script supports the following parameters:

| Parameter | Description | Default | Component | Mode |
|-----------|-------------|---------|-----------|------|
| --lb-ip | Load balancer IP address | Required | Both | LB mode only |
| --ip | Local IP address | Required | Both | Both |
| --target-ip | Target IP address | Required | Sender | Direct mode only |
| --mtu | MTU size | 9000 | Sender | Both |
| --rate | Send rate (Gbps) | 10 | Sender | Both |
| --length | Message length (bytes) | 1000000 | Sender | Both |
| --num-events | Number of events | 10000 | Sender | Both |
| --buf-size | Buffer size (bytes) | 314572800 | Both | Both |
| --duration | Test duration in seconds | 30 | Receiver | Both |
| --port | Receiver port | 19522 | Receiver | Both |
| --threads | Number of threads | 1 | Receiver | Both |
| --direct | Enable direct mode | false | Both | - |

### Example Usage

1. Direct Mode Testing:
```bash
# On receiver machine
./deploy.sh receiver \
  --direct \
  --ip 192.168.1.11 \
  --threads 4 \
  --duration 60

# On sender machine
./deploy.sh sender \
  --direct \
  --ip 192.168.1.10 \
  --target-ip 192.168.1.11 \
  --rate 20 \
  --length 2000000
```

2. Load Balancer Mode:
```bash
# On receiver machine
./deploy.sh receiver \
  --lb-ip 192.168.1.100 \
  --ip 192.168.1.11 \
  --threads 4

# On sender machine
./deploy.sh sender \
  --lb-ip 192.168.1.100 \
  --ip 192.168.1.10 \
  --rate 20 \
  --length 2000000
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
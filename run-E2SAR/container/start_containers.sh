#!/bin/bash

# Default values
SENDER_IP=""
RECEIVER_IP=""
LB_IP=""
MTU=9000
RATE=10
LENGTH=1000000
NUM_EVENTS=10000
BUF_SIZE=314572800
DURATION=30
RECEIVER_PORT=19522
THREADS=1

# Help function
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --sender-ip IP      Sender IP address (required)"
    echo "  --receiver-ip IP    Receiver IP address (required)"
    echo "  --lb-ip IP         Load balancer IP address (required)"
    echo "  --mtu SIZE         MTU size (default: 9000)"
    echo "  --rate RATE        Send rate (default: 10)"
    echo "  --length LEN       Message length (default: 1000000)"
    echo "  --num-events NUM   Number of events (default: 10000)"
    echo "  --buf-size SIZE    Buffer size (default: 314572800)"
    echo "  --duration SEC     Test duration in seconds (default: 30)"
    echo "  --port PORT        Receiver port (default: 19522)"
    echo "  --threads NUM      Number of threads (default: 1)"
    echo "  -h, --help         Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sender-ip)
            SENDER_IP="$2"
            shift 2
            ;;
        --receiver-ip)
            RECEIVER_IP="$2"
            shift 2
            ;;
        --lb-ip)
            LB_IP="$2"
            shift 2
            ;;
        --mtu)
            MTU="$2"
            shift 2
            ;;
        --rate)
            RATE="$2"
            shift 2
            ;;
        --length)
            LENGTH="$2"
            shift 2
            ;;
        --num-events)
            NUM_EVENTS="$2"
            shift 2
            ;;
        --buf-size)
            BUF_SIZE="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --port)
            RECEIVER_PORT="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SENDER_IP" || -z "$RECEIVER_IP" || -z "$LB_IP" ]]; then
    echo "Error: sender-ip, receiver-ip, and lb-ip are required parameters"
    print_usage
    exit 1
fi

# Start receiver container
echo "Starting receiver container..."
docker run -d \
    --network host \
    --name e2sar-receiver \
    -e URI="ejfats://token@${LB_IP}:18008/" \
    -e DURATION="$DURATION" \
    -e BUF_SIZE="$BUF_SIZE" \
    -e IP="$RECEIVER_IP" \
    -e PORT="$RECEIVER_PORT" \
    -e THREADS="$THREADS" \
    e2sar-container /app/entrypoint-receiver.sh

# Wait a bit for receiver to initialize
sleep 2

# Start sender container
echo "Starting sender container..."
docker run -d \
    --network host \
    --name e2sar-sender \
    -e URI="ejfats://token@${LB_IP}:18008/" \
    -e MTU="$MTU" \
    -e RATE="$RATE" \
    -e LENGTH="$LENGTH" \
    -e NUM_EVENTS="$NUM_EVENTS" \
    -e BUF_SIZE="$BUF_SIZE" \
    -e IP="$SENDER_IP" \
    e2sar-container /app/entrypoint-sender.sh

echo "Containers started!"
echo "To view logs:"
echo "  Receiver: docker logs e2sar-receiver"
echo "  Sender: docker logs e2sar-sender"
echo ""
echo "To stop containers:"
echo "  docker stop e2sar-sender e2sar-receiver"
echo "  docker rm e2sar-sender e2sar-receiver" 
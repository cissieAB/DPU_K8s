#!/bin/bash

# Help function
print_usage() {
    echo "Usage: $0 [sender|receiver] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  sender    Start the E2SAR sender container"
    echo "  receiver  Start the E2SAR receiver container"
    echo ""
    echo "Options:"
    echo "  --lb-ip IP         Load balancer IP address (optional)"
    echo "  --ip IP            Local IP address (required)"
    echo "  --target-ip IP     Target IP address (required for direct mode)"
    echo "  --mtu SIZE         MTU size (sender only, default: 9000)"
    echo "  --rate RATE        Send rate (sender only, default: 10)"
    echo "  --length LEN       Message length (sender only, default: 1000000)"
    echo "  --num-events NUM   Number of events (sender only, default: 10000)"
    echo "  --buf-size SIZE    Buffer size (default: 314572800)"
    echo "  --duration SEC     Test duration (receiver only, default: 30)"
    echo "  --port PORT        Receiver port (receiver only, default: 19522)"
    echo "  --threads NUM      Number of threads (receiver only, default: 1)"
    echo "  --direct          Use direct mode without load balancer"
    echo "  -h, --help         Show this help message"
}

# Default values
MTU=9000
RATE=10
LENGTH=1000000
NUM_EVENTS=10000
BUF_SIZE=314572800
DURATION=30
PORT=19522
THREADS=1
LB_IP=""
IP=""
TARGET_IP=""
DIRECT_MODE=false

# Parse command line arguments
COMMAND=$1
shift

if [[ "$COMMAND" != "sender" && "$COMMAND" != "receiver" ]]; then
    echo "Error: Command must be either 'sender' or 'receiver'"
    print_usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --lb-ip)
            LB_IP="$2"
            shift 2
            ;;
        --ip)
            IP="$2"
            shift 2
            ;;
        --target-ip)
            TARGET_IP="$2"
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
            PORT="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --direct)
            DIRECT_MODE=true
            shift
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
if [[ -z "$IP" ]]; then
    echo "Error: --ip is required"
    print_usage
    exit 1
fi

if [[ "$DIRECT_MODE" == true && -z "$TARGET_IP" ]]; then
    echo "Error: --target-ip is required in direct mode"
    print_usage
    exit 1
fi

if [[ "$DIRECT_MODE" == false && -z "$LB_IP" ]]; then
    echo "Error: --lb-ip is required when not in direct mode"
    print_usage
    exit 1
fi

# Construct URI based on mode
if [[ "$DIRECT_MODE" == true ]]; then
    if [[ "$COMMAND" == "sender" ]]; then
        URI="ejfat://useless@10.10.10.10:1234/lb/1?data=${TARGET_IP}&sync=192.168.77.7:1234"
    else
        URI="ejfat://useless@10.10.10.10:1234/lb/1?data=${IP}&sync=192.168.77.7:1234"
    fi
else
    URI="ejfats://token@${LB_IP}:18008/"
fi

# Start the appropriate container
if [[ "$COMMAND" == "sender" ]]; then
    echo "Starting E2SAR sender..."
    docker run -d \
        --network host \
        --name e2sar-sender \
        -e URI="$URI" \
        -e MTU="$MTU" \
        -e RATE="$RATE" \
        -e LENGTH="$LENGTH" \
        -e NUM_EVENTS="$NUM_EVENTS" \
        -e BUF_SIZE="$BUF_SIZE" \
        -e IP="$IP" \
        -e DIRECT_MODE="$DIRECT_MODE" \
        e2sar-container /app/entrypoint-sender.sh
else
    echo "Starting E2SAR receiver..."
    docker run -d \
        --network host \
        --name e2sar-receiver \
        -e URI="$URI" \
        -e DURATION="$DURATION" \
        -e BUF_SIZE="$BUF_SIZE" \
        -e IP="$IP" \
        -e PORT="$PORT" \
        -e THREADS="$THREADS" \
        -e DIRECT_MODE="$DIRECT_MODE" \
        e2sar-container /app/entrypoint-receiver.sh
fi 
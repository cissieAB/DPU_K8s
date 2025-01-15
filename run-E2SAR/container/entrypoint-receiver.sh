#!/bin/bash

# If DIRECT_MODE is true, don't use control plane
if [ "$DIRECT_MODE" = "true" ]; then
    e2sar_perf -r -u "$URI" -d "$DURATION" -b "$BUF_SIZE" --ip "$IP" --port "$PORT" --threads "$THREADS" -4
else
    e2sar_perf -r -u "$URI" -d "$DURATION" -b "$BUF_SIZE" --ip "$IP" --port "$PORT" --threads "$THREADS" --withcp -4
fi
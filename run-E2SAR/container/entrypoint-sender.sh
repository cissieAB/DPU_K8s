#!/bin/bash

# If DIRECT_MODE is true, don't use control plane
if [ "$DIRECT_MODE" = "true" ]; then
    e2sar_perf -s -u "$URI" --mtu "$MTU" --rate "$RATE" --length "$LENGTH" -n "$NUM_EVENTS" -b "$BUF_SIZE" --ip "$IP" -4
else
    e2sar_perf -s -u "$URI" --mtu "$MTU" --rate "$RATE" --length "$LENGTH" -n "$NUM_EVENTS" -b "$BUF_SIZE" --ip "$IP" --withcp -4
fi
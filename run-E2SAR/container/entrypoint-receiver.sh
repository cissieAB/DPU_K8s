#!/bin/bash
e2sar_perf -r -u "$URI" -d "$DURATION" -b "$BUF_SIZE" --ip "$IP" --port "$PORT" --withcp -4 --threads "$THREADS"
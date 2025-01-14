#!/bin/bash
e2sar_perf -s -u "$URI" --mtu "$MTU" --rate "$RATE" --length "$LENGTH" -n "$NUM_EVENTS" -b "$BUF_SIZE" --ip "$IP" --withcp -4
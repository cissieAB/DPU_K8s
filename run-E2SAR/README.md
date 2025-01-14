# E2SAR Load Balancer Testing on FABRIC

This directory contains two Jupyter notebooks for setting up and testing the E2SAR Load Balancer on FABRIC's testbed:

1. `E2SAR-U280-lb.ipynb`: Sets up a FABRIC node with a U280 FPGA for running the Load Balancer
2. `E2SAR-fabric-lb-tester.ipynb`: Creates sender and receiver nodes to test the Load Balancer

## Quick Start Guide

### Step 1: Set Up the Load Balancer

1. Open `E2SAR-U280-lb.ipynb`
2. Configure the site selection (recommended sites: LOSA, KANS, WASH)
3. Run the notebook cells sequentially to:
   - Create a slice with a U280 FPGA node
   - Set up the Load Balancer environment
   - Start the Load Balancer service

Note the Load Balancer's IP address and control plane port (default: 18008) - you'll need these for the tester.

### Step 2: Run the Tester

1. Open `E2SAR-fabric-lb-tester.ipynb`
2. Configure the following parameters in the notebook:
   - `lb_node_ip`: IP address of your Load Balancer node
   - `lb_cp_port`: Control plane port (default: 18008)
   - `lb_admin_token`: Admin token from the Load Balancer setup
   - `number_of_workers`: Number of receiver nodes (default: 3)

3. Run the notebook cells sequentially to:
   - Create sender and receiver nodes
   - Configure the testing environment
   - Run the test cases

## Simple Data Transfer Test

To run a basic test of sending data:

1. After both notebooks are running, the sender node will automatically connect to the Load Balancer
2. The receiver nodes will register themselves with the Load Balancer
3. Data transfer will begin automatically using the E2SAR protocol
4. Monitor the results in the tester notebook's output cells

## Requirements

- FABRIC account with FPGA permissions
- Python environment with FABRIC API access
- Access to FABRIC sites with U280 FPGAs (LOSA, KANS, or WASH recommended)

## Notes

- The Load Balancer requires a U280 FPGA-equipped node
- For best results, choose sites with good network connectivity
- Default configuration supports up to 3 receiver nodes
- Monitor system logs for any errors or performance issues 
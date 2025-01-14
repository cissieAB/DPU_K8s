# DPU_K8s
Resources for hosting Kubernetes (K8s) on Data Processing Units (DPUs) in JLab testbeds. This repository is part of LDRD 2513.

## Project Overview
This project explores the deployment and management of Kubernetes clusters utilizing Data Processing Units (DPUs) in Jefferson Lab testbeds.

## Repository Structure

### [FabricPortal_tests](./FabricPortal_tests)
Contains scripts and configurations for setting up a 2-node Kubernetes system on the [FABRIC](https://portal.fabric-testbed.net/) testbed. Key features include:
- Control plane and worker node configuration scripts
- Step-by-step deployment instructions
- Troubleshooting guides and best practices
- Known issues and their solutions

### [run-E2SAR](./run-E2SAR)
Contains Jupyter notebooks for testing the E2SAR Load Balancer on FABRIC testbed with U280 FPGAs. Features include:
- Load Balancer setup on U280 FPGA nodes
- Sender and receiver node configuration
- Automated data transfer testing
- Performance monitoring and evaluation tools
- Containerized sender and receiver components

## Prerequisites
- Access to JLab testbeds
- FABRIC account and portal access (for FabricPortal_tests)
- FABRIC account with FPGA permissions (for run-E2SAR tests)
- Basic understanding of Kubernetes and DPUs
- Docker installed (for running containerized components)

## Getting Started
1. Choose the appropriate testbed directory based on your needs:
   - Use `FabricPortal_tests` for Kubernetes deployment
   - Use `run-E2SAR` for Load Balancer testing
2. Follow the README instructions in the specific directory
3. Configure and deploy according to the provided scripts
4. For E2SAR testing:
   - Build and use Docker containers for sender/receiver components
   - Follow container-specific instructions in run-E2SAR/container/

## Contributing
For questions or contributions, please contact the project maintainers.

## License
This project is part of LDRD 2513 at Jefferson Lab.

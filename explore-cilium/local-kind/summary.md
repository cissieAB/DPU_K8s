# CNI Performance Test Summary
## Cilium vs Default CNI (kindnet) Comparison

**Test Date:** June 17-18, 2025  
**Test Environment:** Kind cluster with 2 worker nodes + 1 control plane  
**Kernel Version:** 5.15.0-140-generic  
**Cilium Version:** 1.15.3  

---

## Test Overview

This test demonstrates the deployment and execution of comprehensive network performance testing comparing Cilium CNI against the default Kind CNI (kindnet) on a multi-node Kubernetes cluster. The tests were conducted using cross-node communication to simulate real-world Kubernetes networking scenarios across multiple performance benchmarks.

## Infrastructure Setup

### Local Kind Cluster Configuration
- **Cluster Type**: Kind (Kubernetes in Docker)
- **Kubernetes Version**: v1.29.2
- **Node Architecture**: 1 control-plane + 2 worker nodes
- **Container Runtime**: Docker
- **Host OS**: Linux 5.15.0-140-generic

### Node Architecture
The test uses a 3-node Kubernetes cluster:
1. **Control Plane Node**: 
   - Hosts the Kubernetes control plane components
   - Runs etcd, kube-apiserver, kube-controller-manager, kube-scheduler
   - Manages cluster orchestration and scheduling

2. **Worker Node 1**:
   - Dedicated server node for performance testing
   - Runs nginx HTTP server and iperf3 server
   - Hosts test applications for cross-node communication

3. **Worker Node 2**:
   - Dedicated client node for performance testing
   - Runs Apache Benchmark (ab), iperf3 client, and wrk load testing tools
   - Generates test traffic to measure network performance

### Network Configuration
- **Pod Subnet**: 10.244.0.0/16
- **Service Subnet**: 10.96.0.0/12
- **CNI Comparison**: Default CNI (kindnet) vs Cilium CNI
- **Cross-node Communication**: All tests performed between different worker nodes

## Kubernetes Cluster Deployment

### Default CNI Cluster Setup
- Uses standard Kind configuration with default CNI (kindnet)
- Automatic CNI installation and configuration
- Standard pod networking without additional features

### Cilium CNI Cluster Setup
- Disables default CNI during cluster creation
- Installs Cilium via Helm with version 1.15.3
- Configures eBPF-based networking with advanced features
- Enables Hubble observability and Prometheus metrics

### Cluster Verification
- All system pods running successfully
- CNI components deployed and operational
- Cross-node pod communication verified
- Service discovery working correctly

## Performance Test Configuration

### Test Architecture
The performance testing consists of three main test scenarios deployed as Kubernetes pods:

1. **HTTP Performance Test (Apache Benchmark)**:
   - Server: nginx deployment on Worker Node 1
   - Client: Apache Benchmark pod on Worker Node 2
   - Test Parameters: 50,000 requests, 10 concurrent connections, 30-second duration
   - Metrics: Requests/sec, response times, throughput

2. **Network Throughput Test (iperf3)**:
   - Server: iperf3 server pod on Worker Node 1
   - Client: iperf3 client pod on Worker Node 2
   - Test Parameters: 30-second TCP stream test
   - Metrics: Bandwidth, retransmissions, connection stability

3. **High-Load Performance Test (wrk)**:
   - Server: nginx deployment on Worker Node 1
   - Client: wrk load testing pod on Worker Node 2
   - Test Parameters: 30-second test, 1,000 concurrent connections, 8 threads
   - Metrics: Requests/sec, latency, transfer rates

### Test Parameters
- **HTTP Test**: 50,000 requests, 10 concurrent connections
- **Network Test**: 30-second TCP stream, cross-node communication
- **Load Test**: 1,000 concurrent connections, 8 threads, 30-second duration
- **Cross-node Communication**: All tests performed between different worker nodes

### Network Configuration
- **Service Discovery**: ClusterIP services for server endpoints
- **Pod-to-Pod Communication**: Direct pod IP communication
- **Load Balancing**: Kubernetes service load balancing
- **Network Policies**: Standard Kubernetes networking

## Test Results

### 1. HTTP Performance Test Results

**Default CNI Performance:**
- **Requests/sec**: 10,720.05
- **Average Response Time**: 0.933ms
- **99th Percentile**: 1ms
- **Max Response Time**: 13ms
- **Failed Requests**: 0
- **Transfer Rate**: 8,877.54 Kbytes/sec
- **Status**: ✅ Excellent performance

**Cilium CNI Performance:**
- **Requests/sec**: 5,672.90
- **Average Response Time**: 1.763ms
- **99th Percentile**: 4ms
- **Max Response Time**: 18ms
- **Failed Requests**: 0
- **Transfer Rate**: 4,697.87 Kbytes/sec
- **Status**: ✅ Good performance with higher latency

**Performance Comparison:**
- **Throughput Advantage**: Default CNI 89% faster
- **Latency Advantage**: Default CNI 47% faster
- **Reliability**: Both CNIs achieved 100% success rate

### 2. Network Throughput Test Results

**Default CNI Performance:**
- **Average Throughput**: 34.7 Gbits/sec
- **Max Throughput**: 35.4 Gbits/sec
- **Retransmissions**: 471 total
- **Connection Stability**: Variable (0-457 retransmissions per interval)
- **Status**: ✅ High throughput with some instability

**Cilium CNI Performance:**
- **Average Throughput**: 19.2 Gbits/sec
- **Max Throughput**: 19.5 Gbits/sec
- **Retransmissions**: 1 total
- **Connection Stability**: Excellent (0-1 retransmissions per interval)
- **Status**: ✅ Consistent performance with excellent stability

**Performance Comparison:**
- **Throughput Advantage**: Default CNI 81% faster
- **Stability Advantage**: Cilium 99.8% fewer retransmissions
- **Reliability**: Cilium provides much more stable connections

### 3. High-Load Performance Test Results

**Default CNI Performance:**
- **Requests/sec**: 81,318.61
- **Average Latency**: 12.34ms
- **Max Latency**: 96.79ms
- **Total Requests**: 2,447,240
- **Transfer Rate**: 66.15MB/s
- **Status**: ✅ Excellent high-load performance

**Cilium CNI Performance:**
- **Requests/sec**: 57,965.77
- **Average Latency**: 16.23ms
- **Max Latency**: 116.12ms
- **Total Requests**: 1,743,496
- **Transfer Rate**: 47.15MB/s
- **Status**: ✅ Good high-load performance

**Performance Comparison:**
- **Throughput Advantage**: Default CNI 40% faster
- **Latency Advantage**: Default CNI 24% faster
- **Request Processing**: Default CNI processed 40% more requests

## Technical Analysis

### Performance Characteristics

**Default CNI (kindnet) Strengths:**
1. **Higher Raw Performance**: Consistently achieved higher throughput across all tests
2. **Lower Latency**: Better response times in HTTP and load testing scenarios
3. **Better Resource Utilization**: More efficient processing under high load conditions
4. **Simplicity**: Minimal overhead from basic networking implementation

**Cilium CNI Strengths:**
1. **Connection Stability**: Significantly fewer retransmissions and more reliable connections
2. **Consistent Performance**: More predictable performance characteristics
3. **Advanced Features**: Built-in support for network policies, observability, and security
4. **Modern Architecture**: eBPF-based networking with enhanced capabilities

### Performance Metrics Analysis

**Throughput Performance:**
- Default CNI achieved 89% higher HTTP throughput
- Default CNI achieved 81% higher network throughput
- Default CNI achieved 40% higher load test throughput

**Latency Performance:**
- Default CNI showed 47% lower HTTP response times
- Default CNI showed 24% lower load test latency
- Both CNIs maintained acceptable latency under normal conditions

**Reliability Performance:**
- Cilium showed 99.8% fewer network retransmissions
- Both CNIs achieved 100% HTTP request success rates
- Cilium provided more stable connection characteristics

### Factors Affecting Performance

1. **Test Environment Limitations:**
   - Running in nested virtualization (Kind on Linux)
   - Limited CPU resources compared to bare metal
   - Network overhead from containerization layers

2. **Cilium Configuration:**
   - Default Cilium installation without performance tuning
   - No eBPF host-routing or kube-proxy replacement enabled
   - Standard configuration without optimization

3. **Workload Characteristics:**
   - Synthetic benchmarks may not reflect real-world usage patterns
   - High-concurrency tests may not represent typical microservices workloads
   - Test environment constraints affecting absolute performance numbers

## Technical Challenges Identified

### Performance Limitations
- Cilium showed lower raw performance compared to default CNI
- Default CNI exhibited higher retransmission rates under load
- Performance differences more pronounced under high-concurrency conditions

### Infrastructure Constraints
- Kind cluster resource limitations affecting absolute performance
- Nested virtualization overhead impacting network performance
- Container resource limits affecting throughput capabilities

### Configuration Optimization Opportunities
- Cilium performance could be improved with proper tuning
- eBPF host-routing and kube-proxy replacement not enabled
- Network policy and security features adding overhead

## Cleanup and Resource Management

### Automatic Cleanup
- Test scripts automatically clean up pods and services after completion
- Temporary YAML files removed after test execution
- Cluster contexts properly managed and cleaned

### Manual Cleanup
- Kind clusters can be deleted with `kind delete clusters --all`
- Kubernetes contexts can be cleaned up manually
- Docker resources automatically cleaned when clusters deleted

## Lessons Learned

1. **Performance vs Features Trade-off**: Default CNI provides better raw performance while Cilium offers advanced features
2. **Environment Impact**: Test environment significantly affects absolute performance numbers
3. **Configuration Importance**: Cilium performance can be optimized with proper configuration
4. **Stability vs Speed**: Cilium provides better connection stability despite lower throughput
5. **Use Case Considerations**: Choice between CNIs should be based on specific requirements
6. **Testing Methodology**: Cross-node communication provides realistic performance insights

## Recommendations

### For Production Environments

1. **Choose Default CNI when:**
   - Maximum raw performance is the primary requirement
   - Simple networking without advanced features is sufficient
   - Running on resource-constrained environments
   - High-throughput workloads are critical

2. **Choose Cilium CNI when:**
   - Network security and observability are important
   - Advanced networking features are required
   - Connection reliability is critical
   - Planning to use network policies or service mesh
   - Modern eBPF-based networking is desired

### Performance Optimization

1. **For Cilium:**
   - Enable eBPF host-routing for better performance
   - Configure kube-proxy replacement
   - Tune eBPF map sizes and memory limits
   - Use a modern kernel (>=5.10) for optimal eBPF performance
   - Optimize network policy configurations

2. **For Default CNI:**
   - Monitor for connection stability issues under load
   - Consider implementing additional monitoring for network reliability
   - Evaluate if advanced networking features are needed
   - Implement custom monitoring for network performance

### Testing Strategy
1. **Environment Selection**: Use production-like environments for accurate performance testing
2. **Configuration Testing**: Test different CNI configurations and optimizations
3. **Workload Diversity**: Test with various workload patterns and traffic types
4. **Long-term Monitoring**: Implement continuous performance monitoring
5. **Documentation**: Maintain detailed configuration and performance documentation

## Conclusion

The CNI performance test successfully demonstrated the deployment of multi-node Kubernetes clusters with different CNI implementations and comprehensive performance benchmarking. **The test revealed that Default CNI (kindnet) provides superior raw performance with 40-89% higher throughput across all test scenarios, while Cilium CNI offers better connection stability with 99.8% fewer retransmissions and advanced networking features.**

The choice between CNIs should be based on specific requirements:
- **Performance-focused workloads**: Default CNI provides better throughput and lower latency
- **Feature-rich, production environments**: Cilium CNI offers advanced features, better stability, and modern eBPF-based networking

It's important to note that these results are specific to the test environment and may not reflect performance in production deployments with different hardware, network configurations, or workload patterns. The test provided valuable insights into the performance characteristics and trade-offs between different CNI implementations in Kubernetes environments.

---

## Appendix A: Detailed Test Results

### Raw Test Output Files

The complete raw test outputs are available in the following files:
- `http_results_cilium_c10.txt` - Cilium HTTP performance test results
- `http_results_default_c10.txt` - Default CNI HTTP performance test results
- `iperf3_results_cilium.txt` - Cilium network throughput test results
- `iperf3_results_default.txt` - Default CNI network throughput test results
- `wrk_results_cilium_c1000_t8.txt` - Cilium high-load test results
- `wrk_results_default_c1000_t8.txt` - Default CNI high-load test results

### Key Observations from Raw Output

1. **HTTP Performance**: Default CNI completed 50,000 requests in 4.664 seconds vs Cilium's 8.814 seconds
2. **Network Stability**: Cilium showed only 1 retransmission vs Default CNI's 471 retransmissions
3. **Load Testing**: Default CNI processed 2,447,240 requests vs Cilium's 1,743,496 requests
4. **Consistency**: Both CNIs maintained consistent performance throughout test duration
5. **Reliability**: All tests completed successfully with no failed requests

### Performance Timeline Analysis

- **Phase 1**: Cluster setup and application deployment
- **Phase 2**: Test execution with cross-node communication
- **Phase 3**: Performance data collection and analysis
- **Phase 4**: Resource cleanup and result compilation

This detailed output provides valuable insights into the real-time behavior of different CNI implementations and demonstrates the successful operation of comprehensive performance testing infrastructure in Kubernetes environments.

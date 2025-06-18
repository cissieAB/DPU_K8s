# CNI Performance Test Summary
## Cilium vs Default CNI (kindnet) Comparison

**Test Date:** June 17-18, 2025  
**Test Environment:** Kind cluster with 2 worker nodes + 1 control plane  
**Kernel Version:** 5.15.0-140-generic  
**Cilium Version:** 1.15.3  

---

## Executive Summary

This document summarizes performance test results comparing Cilium CNI against the default Kind CNI (kindnet) across multiple test scenarios. The tests were conducted using cross-node communication to simulate real-world Kubernetes networking scenarios.

### Key Findings

- **Default CNI (kindnet)** showed better performance in high-concurrency scenarios
- **Cilium CNI** demonstrated consistent performance with lower retransmission rates
- Both CNIs handled the test load successfully with no failed requests
- Performance differences were more pronounced under high load conditions

---

## Test Results Summary

### 1. HTTP Performance Test (Apache Benchmark)
**Test Parameters:** 50,000 requests, 10 concurrent connections, 30-second duration

| Metric | Default CNI | Cilium CNI | Difference |
|--------|-------------|------------|------------|
| **Requests/sec** | 10,720.05 | 5,672.90 | Default 89% faster |
| **Avg Response Time** | 0.933ms | 1.763ms | Default 47% faster |
| **99th Percentile** | 1ms | 4ms | Default 75% faster |
| **Max Response Time** | 13ms | 18ms | Default 28% faster |
| **Failed Requests** | 0 | 0 | Equal |

**Analysis:** Default CNI significantly outperformed Cilium in this HTTP workload test, showing nearly 2x better throughput and significantly lower latency.

### 2. Network Throughput Test (iperf3)
**Test Parameters:** 30-second TCP stream test, cross-node communication

| Metric | Default CNI | Cilium CNI | Difference |
|--------|-------------|------------|------------|
| **Average Throughput** | 34.7 Gbits/sec | 19.2 Gbits/sec | Default 81% faster |
| **Retransmissions** | 471 | 1 | Cilium 99.8% fewer |
| **Connection Stability** | Variable | Consistent | Cilium more stable |
| **Max Throughput** | 35.4 Gbits/sec | 19.5 Gbits/sec | Default 82% faster |

**Analysis:** While Default CNI achieved higher throughput, Cilium showed much better connection stability with minimal retransmissions, indicating more reliable network processing.

### 3. High-Load Performance Test (wrk)
**Test Parameters:** 30-second test, 1,000 concurrent connections, 8 threads

| Metric | Default CNI | Cilium CNI | Difference |
|--------|-------------|------------|------------|
| **Requests/sec** | 81,318.61 | 57,965.77 | Default 40% faster |
| **Avg Latency** | 12.34ms | 16.23ms | Default 24% faster |
| **Max Latency** | 96.79ms | 116.12ms | Default 17% faster |
| **Total Requests** | 2,447,240 | 1,743,496 | Default 40% more |
| **Transfer Rate** | 66.15MB/s | 47.15MB/s | Default 40% faster |

**Analysis:** Default CNI maintained its performance advantage even under high-concurrency conditions, processing 40% more requests with lower latency.

---

## Detailed Test Results

### HTTP Performance Test Details

**Default CNI Results:**
- Server: nginx/1.27.5
- Time taken: 4.664 seconds
- Complete requests: 50,000
- Failed requests: 0
- Transfer rate: 8,877.54 Kbytes/sec
- 99th percentile response time: 1ms

**Cilium CNI Results:**
- Server: nginx/1.27.5
- Time taken: 8.814 seconds
- Complete requests: 50,000
- Failed requests: 0
- Transfer rate: 4,697.87 Kbytes/sec
- 99th percentile response time: 4ms

### Network Throughput Test Details

**Default CNI Results:**
- Average throughput: 34.7 Gbits/sec
- Total retransmissions: 471
- Connection stability: Variable (0-457 retransmissions per interval)
- Peak performance: 35.4 Gbits/sec

**Cilium CNI Results:**
- Average throughput: 19.2 Gbits/sec
- Total retransmissions: 1
- Connection stability: Excellent (0-1 retransmissions per interval)
- Peak performance: 19.5 Gbits/sec

### High-Load Test Details

**Default CNI Results:**
- Thread statistics: 10.28k ± 1.13k requests/sec per thread
- Latency distribution: 79.25% within ±1 standard deviation
- Memory usage: 1.94GB transferred
- Performance consistency: Good

**Cilium CNI Results:**
- Thread statistics: 7.34k ± 1.45k requests/sec per thread
- Latency distribution: 75.23% within ±1 standard deviation
- Memory usage: 1.39GB transferred
- Performance consistency: Good

---

## Performance Analysis

### Default CNI (kindnet) Strengths
1. **Higher Throughput:** Consistently achieved higher request rates and network throughput
2. **Lower Latency:** Better response times across all test scenarios
3. **Better Resource Utilization:** More efficient processing under high load

### Cilium CNI Strengths
1. **Connection Stability:** Significantly fewer retransmissions and more reliable connections
2. **Consistent Performance:** More predictable performance characteristics
3. **Advanced Features:** Built-in support for network policies, observability, and security features

### Factors Affecting Performance

1. **Test Environment Limitations:**
   - Running in nested virtualization (Kind on Linux)
   - Limited CPU resources compared to bare metal
   - Network overhead from containerization

2. **Cilium Configuration:**
   - Default Cilium installation without performance tuning
   - No eBPF host-routing or kube-proxy replacement enabled
   - Standard configuration without optimization

3. **Workload Characteristics:**
   - Synthetic benchmarks may not reflect real-world usage patterns
   - High-concurrency tests may not represent typical microservices workloads

---

## Recommendations

### For Production Environments

1. **Choose Default CNI when:**
   - Maximum raw performance is the primary requirement
   - Simple networking without advanced features is sufficient
   - Running on resource-constrained environments

2. **Choose Cilium CNI when:**
   - Network security and observability are important
   - Advanced networking features are required
   - Connection reliability is critical
   - Planning to use network policies or service mesh

### Performance Optimization

1. **For Cilium:**
   - Enable eBPF host-routing for better performance
   - Configure kube-proxy replacement
   - Tune eBPF map sizes and memory limits
   - Use a modern kernel (>=5.10) for optimal eBPF performance

2. **For Default CNI:**
   - Monitor for connection stability issues under load
   - Consider implementing additional monitoring for network reliability
   - Evaluate if advanced networking features are needed

---

## Conclusion

The test results show that Default CNI (kindnet) provides better raw performance in the current test environment, while Cilium offers better connection stability and advanced features. The choice between them should be based on specific requirements:

- **Performance-focused workloads:** Default CNI
- **Feature-rich, production environments:** Cilium CNI

It's important to note that these results are specific to the test environment and may not reflect performance in production deployments with different hardware, network configurations, or workload patterns.

---

**Test Files Referenced:**
- `http_results_cilium_c10.txt`
- `http_results_default_c10.txt`
- `iperf3_results_cilium.txt`
- `iperf3_results_default.txt`
- `wrk_results_cilium_c1000_t8.txt`
- `wrk_results_default_c1000_t8.txt` 
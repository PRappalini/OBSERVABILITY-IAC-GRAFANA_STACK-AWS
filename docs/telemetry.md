# Multi-Layer Observability & Telemetry

To ensure high availability and prevent silent failures in production, the stack implements a **3-tier observability model** covering the entire execution lifecycle.

---

## 🏗️ The 3-Tier Observability Model

```text
┌────────────────────────────────────────────────────────────────────────┐
│  Tier 3: Application Engine Metrics (/metrics: 9090, 3100, 3200, 3000) │
│  - Ingestion rates, compaction status, query latency, span throughput  │
├────────────────────────────────────────────────────────────────────────┤
│  Tier 2: Container Runtime Metrics (cAdvisor: 8080)                    │
│  - Per-container CPU throttling, memory limits, OOM kills              │
├────────────────────────────────────────────────────────────────────────┤
│  Tier 1: Host / OS Metrics (Node Exporter: 9100)                       │
│  - EBS disk capacity exhaustion, kernel memory, CPU load, I/O rates    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📡 Tier Breakdown

### 1. Host / OS Telemetry (`node_exporter` - Port `9100`)

Every EC2 instance runs `prom/node-exporter:v1.9.0` with root filesystem mount (`/host:ro,rslave`):

- **EBS Disk Capacity Alerts**: Logs (Loki) and traces (Tempo) generate continuous disk writes. Monitoring disk usage prevents silent disk exhaustion crashes.
- **System Memory & Swap**: Identifies memory pressure before the Linux kernel OOM killer terminates core services.
- **CPU & Load Average**: Detects CPU saturation caused by heavy LogQL/PromQL queries or high ingestion bursts.
- **Network I/O**: Tracks network bandwidth consumption between workload collectors and the observability nodes.

### 2. Container Telemetry (`cadvisor` - Port `8080`)

Every EC2 instance runs `gcr.io/cadvisor/cadvisor:v0.49.2` with read-only mounts into `/var/run/docker.sock`, `/sys`, and `/var/lib/docker`:

- **Per-Container Memory Allocation**: Pinpoints exact memory consumption inside each Docker container, isolating memory leaks.
- **cgroup CPU Throttling**: Detects if container CPU limits are restricting ingestion or query execution speeds.
- **Container Health & Restarts**: Real-time visibility into container crash loops and exit codes.

### 3. Application Engine Telemetry (Native `/metrics` Endpoints)

Prometheus scrapes the internal metrics exposed by all four core engines:

- **Loki Engine (`:3100/metrics`)**: Monitored for chunk memtable sizes, log ingestion rate (bytes/sec), compaction cycle durations, and query error rates.
- **Tempo Engine (`:3200/metrics`)**: Tracks span ingestion throughput, live trace buffer status, block flushes, and search query latencies.
- **Grafana Engine (`:3000/metrics`)**: Monitors active dashboard sessions, datasource query performance, alert evaluation timings, and API latency.
- **Prometheus Engine (`:9090/metrics`)**: Observes TSDB head series cardinality, chunk compaction, scrape interval delays, and WAL write latency.

---

## 🔄 Prometheus Scrape Matrix

Prometheus is centrally configured via [`docker/prometheus/prometheus.yml`](https://github.com/PRappalini/OBSERVABILITY-IAC-GRAFANA_STACK-AWS/blob/master/docker/prometheus/prometheus.yml) to scrape all 4 nodes across all 3 tiers:

```yaml
scrape_configs:
  # Tier 1: Host OS Metrics
  - job_name: "node-exporter"
    scrape_interval: 15s
    static_configs:
      - targets:
          - "10.20.10.10:9100"  # Prometheus host
          - "10.20.10.11:9100"  # Loki host
          - "10.20.10.12:9100"  # Tempo host
          - "10.20.10.13:9100"  # Grafana host

  # Tier 2: Container Runtime Metrics
  - job_name: "cadvisor"
    scrape_interval: 15s
    static_configs:
      - targets:
          - "10.20.10.10:8080"
          - "10.20.10.11:8080"
          - "10.20.10.12:8080"
          - "10.20.10.13:8080"

  # Tier 3: Core Application Engines
  - job_name: "prometheus"
    scrape_interval: 15s
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "loki"
    scrape_interval: 15s
    static_configs:
      - targets: ["10.20.10.11:3100"]

  - job_name: "tempo"
    scrape_interval: 15s
    static_configs:
      - targets: ["10.20.10.12:3200"]

  - job_name: "grafana"
    scrape_interval: 15s
    static_configs:
      - targets: ["10.20.10.13:3000"]
```

---

## 🔗 Telemetry Correlation

Grafana datasources are auto-provisioned to seamlessly link telemetry pillars:

1. **Traces to Logs (`jsonData.tracesToLogsV2`)**:
   When viewing a trace in Tempo, clicking on a span automatically searches Loki logs for the matching service, trace ID, and time window.

2. **Service Map (`jsonData.serviceMap`)**:
   Tempo generates dependency maps and request flow diagrams backed by Prometheus metrics.

# Grafana Observability Stack on AWS (IaC)

A modular, automated, production-ready Infrastructure as Code (IaC) solution using **Terraform** to provision a complete 4-pillar observability platform (**Metrics, Logs, Traces, and Dashboards**) on **Amazon Web Services (AWS)** using **Docker Compose** on dedicated Amazon Linux 2023 EC2 instances.

---

## ⚡ Quick Highlights

- **4 Core Pillars**: Grafana (UI/Dashboards), Prometheus (Metrics/TSDB), Loki (Logs/LogQL), Tempo (Distributed Tracing/OTLP).
- **3-Tier Multi-Layer Observability**: Host OS metrics (`node-exporter`), Container runtime metrics (`cAdvisor`), and native application engine `/metrics`.
- **Zero-Key Administration**: Full management via **AWS Systems Manager (SSM)** without opening SSH port 22.
- **Least-Privilege Network Mesh**: Security Groups restrict ingestion, scraping, and queries strictly to authorized peer instances and CIDR blocks.
- **Deterministic Private Networking**: Hardened VPC with deterministic private IPs (`cidrhost`) preventing Terraform cyclic dependency graphs.
- **Direct Host Storage**: Container volumes bind-mounted to `/opt/observability/data` with dedicated UID/GID ownership for straightforward backup and snapshot routines.

---

## 📊 High-Level Architecture

![Grafana Observability Stack Architecture](architecture.png)

/// tip | Diagram Formats Available
- 🌐 [Interactive HTML Render](architecture.html){ target="_blank" }
- 🖼️ [High-Resolution PNG](architecture.png){ target="_blank" }
- 📐 [Draw.io Editable Source](architecture.drawio){ target="_blank" }
///

---

## 🛠️ Stack Components & Specifications

| Component | Docker Image | Listening Port(s) | Storage / Retention | Deployment Scope | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grafana** | `grafana/grafana:11.5.2` | `3000` | 20 GB gp3 EBS | Dedicated Node | Visualization platform with auto-provisioned, linked datasources. |
| **Prometheus** | `prom/prometheus:v3.2.1` | `9090` | 30 GB gp3 EBS (15d retention) | Dedicated Node | Time-series metrics engine and TSDB storage. |
| **Loki** | `grafana/loki:3.4.2` | `3100` | 30 GB gp3 EBS (TSDB v13) | Dedicated Node | Log aggregation and query engine (LogQL). |
| **Tempo** | `grafana/tempo:2.7.1` | `3200`, `4317`, `4318` | 30 GB gp3 EBS (48h retention) | Dedicated Node | Distributed tracing backend supporting OTLP gRPC/HTTP. |
| **Node Exporter** | `prom/node-exporter:v1.9.0` | `9100` | N/A (Host metrics) | **All 4 Nodes** | Host CPU, memory, disk I/O, filesystem, and network collector. |
| **cAdvisor** | `gcr.io/cadvisor/cadvisor:v0.49.2` | `8080` | N/A (Container metrics) | **All 4 Nodes** | Container resource usage, memory limits, and CPU throttling. |

---

## 🚀 Navigation Guide

- [Architecture Overview](architecture.md): Deep-dive into AWS VPC, topology, and flow arrows.
- [Multi-Layer Telemetry](telemetry.md): 3-tier scraping strategy and metrics exposure.
- [Security & Networking](security.md): Least-privilege SG matrix, SSM, and IMDSv2.
- [Deployment Guide](deployment.md): Step-by-step Terraform provisioning and post-deployment validation.
- [Technical Reference](Internal-Documentation.md): Comprehensive architectural analysis, design decisions, and roadmap.

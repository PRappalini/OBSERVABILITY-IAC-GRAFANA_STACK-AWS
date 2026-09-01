# Security & Networking

The infrastructure follows AWS Well-Architected Security Pillar best practices, establishing an isolated network perimeter with strict least-privilege rules.

---

## 🔒 Security Group Ingress / Egress Matrix

| Security Group | Inbound Ports | Allowed Source | Description |
| :--- | :--- | :--- | :--- |
| **`sg_grafana`** | `3000` | `var.grafana_allowed_cidrs` | Public web UI access for authorized operators. |
| | `3000`, `8080`, `9100` | `sg_prometheus` | Scraping of Grafana engine, cAdvisor, and Node Exporter. |
| | `22` *(optional)* | `var.ssh_allowed_cidrs` | SSH management (only if key pair specified). |
| **`sg_prometheus`** | `9090` | `sg_grafana` | PromQL query engine access from Grafana. |
| | `8080`, `9100` | `sg_prometheus` | Local scraping of Prometheus host and cAdvisor. |
| | `22` *(optional)* | `var.ssh_allowed_cidrs` | SSH management. |
| **`sg_loki`** | `3100` | `sg_grafana` | LogQL query engine access from Grafana. |
| | `3100`, `8080`, `9100` | `sg_prometheus` | Scraping of Loki engine, cAdvisor, and Node Exporter. |
| | `22` *(optional)* | `var.ssh_allowed_cidrs` | SSH management. |
| **`sg_tempo`** | `3200` | `sg_grafana` | TraceQL query engine access from Grafana. |
| | `3200`, `8080`, `9100` | `sg_prometheus` | Scraping of Tempo engine, cAdvisor, and Node Exporter. |
| | `4317`, `4318` | VPC / Workload CIDRs | OTLP gRPC & HTTP trace ingestion. |
| | `22` *(optional)* | `var.ssh_allowed_cidrs` | SSH management. |

---

## 🛡️ Zero-Key SSH Administration (AWS Systems Manager)

All EC2 instances are attached to an IAM Instance Profile containing the AWS-managed policy `AmazonSSMManagedInstanceCore`.

### Benefits:
- **No Open Port 22**: Eliminates brute-force SSH attacks and Internet-facing attack surfaces.
- **Audit Logging**: Every session and command is logged to AWS CloudTrail.
- **Centralized IAM Authentication**: Access is governed by AWS IAM policies, MFA, and SSO rather than static private SSH keys.

### Connecting via AWS CLI:
```bash
# Connect to Grafana EC2 instance
aws ssm start-session --target <GRAFANA_INSTANCE_ID>

# Connect to Prometheus EC2 instance
aws ssm start-session --target <PROMETHEUS_INSTANCE_ID>
```

---

## ⚙️ Host & Storage Hardening

1. **IMDSv2 Enforced**:
   - `http_tokens = "required"` is mandated on all EC2 instances to neutralize Server-Side Request Forgery (SSRF) vulnerabilities.
   - Hop limit configured appropriately for Docker bridge network integration.

2. **Encrypted EBS Storage**:
   - All root volumes utilize `gp3` storage with hardware encryption at rest (`encrypted = true`).
   - IOPS (3000) and throughput (125 MB/s) configured for high-performance TSDB and log indexing operations.

3. **Linux UID/GID Isolation**:
   - Dedicated Linux UIDs ensure containerized services cannot escalate privileges on the host filesystem:
     - Grafana: `472:472`
     - Prometheus: `65534:65534` (`nobody:nogroup`)
     - Loki / Tempo: `10001:10001`

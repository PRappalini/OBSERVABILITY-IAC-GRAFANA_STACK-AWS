# Architecture & Topology

Each core observability component runs isolated on its own EC2 instance within a dedicated AWS VPC. Every node runs **Node Exporter** and **cAdvisor** alongside the core service, providing 360-degree observability across host OS, container runtime, and application engine layers.

---

## 🏛️ Topology Diagram

```mermaid
flowchart TD
    subgraph Internet ["🌐 Internet"]
        User["👨‍💻 DevOps / Engineer"]
    end

    subgraph AWS_VPC ["AWS VPC: 10.20.0.0/16"]
        IGW["Internet Gateway"]

        subgraph Public_Subnet ["Public Subnet: 10.20.10.0/24"]
            
            subgraph Node_Grafana ["EC2: Grafana (t3.small - 10.20.10.13)"]
                Grafana["Grafana v11.5.2 (:3000)"]
                NodeExp_Grafana["Node Exporter (:9100)"]
                cAdvisor_Grafana["cAdvisor (:8080)"]
                SG_Grafana["SG: Ingress :3000 (User CIDRs)<br/>:3000, :8080, :9100 (Prometheus SG)"]
            end

            subgraph Node_Prometheus ["EC2: Prometheus (t3.small - 10.20.10.10)"]
                Prometheus["Prometheus v3.2.1 (:9090)"]
                NodeExp_Prom["Node Exporter (:9100)"]
                cAdvisor_Prom["cAdvisor (:8080)"]
                SG_Prometheus["SG: Ingress :9090 (Grafana SG Only)"]
            end

            subgraph Node_Loki ["EC2: Loki (t3.small - 10.20.10.11)"]
                Loki["Loki v3.4.2 (:3100)"]
                NodeExp_Loki["Node Exporter (:9100)"]
                cAdvisor_Loki["cAdvisor (:8080)"]
                SG_Loki["SG: Ingress :3100 (Grafana SG)<br/>:3100, :8080, :9100 (Prometheus SG)"]
            end

            subgraph Node_Tempo ["EC2: Tempo (t3.small - 10.20.10.12)"]
                Tempo["Tempo v2.7.1 (:3200 / :4317 / :4318)"]
                NodeExp_Tempo["Node Exporter (:9100)"]
                cAdvisor_Tempo["cAdvisor (:8080)"]
                SG_Tempo["SG: Ingress :3200 (Grafana SG)<br/>:3200, :8080, :9100 (Prometheus SG)"]
            end
        end
    end

    User -->|"HTTP :3000 (UI)"| IGW
    IGW --> SG_Grafana
    SG_Grafana --> Grafana

    Grafana -->|"Query :9090"| SG_Prometheus
    SG_Prometheus --> Prometheus

    Grafana -->|"Query :3100"| SG_Loki
    SG_Loki --> Loki

    Grafana -->|"Query :3200"| SG_Tempo
    SG_Tempo --> Tempo

    Prometheus -.->|"Scrape :9100, :8080, :3000"| SG_Grafana
    Prometheus -.->|"Scrape :9100, :8080, :3100"| SG_Loki
    Prometheus -.->|"Scrape :9100, :8080, :3200"| SG_Tempo
    Prometheus -.->|"Local Scrape :9100, :8080, :9090"| NodeExp_Prom
```

---

## 🎨 Interactive Architecture Visualizer

Below is the standalone HTML render of the full architecture map:

<iframe src="../architecture.html" class="architecture-frame" title="Architecture Diagram"></iframe>

/// note | Diagram Files
- **Standalone Full-Screen HTML**: [Open `architecture.html`](architecture.html){ target="_blank" }
- **Static High-Res PNG**: [Download `architecture.png`](architecture.png){ target="_blank" }
- **Editable Source**: [Download `architecture.drawio`](architecture.drawio){ target="_blank" }
///

---

## 🌐 Private Networking & Deterministic Addressing

The infrastructure uses deterministic static IP calculation via Terraform's `cidrhost()` function within the subnet `10.20.10.0/24`:

| Node Name | Instance Type | Private IP | Hostname / Role |
| :--- | :--- | :--- | :--- |
| **Prometheus** | `t3.small` | `10.20.10.10` | Time-series metrics engine & scraper |
| **Loki** | `t3.small` | `10.20.10.11` | Log aggregation & TSDB v13 indexer |
| **Tempo** | `t3.small` | `10.20.10.12` | Distributed tracing & OTLP receiver |
| **Grafana** | `t3.small` | `10.20.10.13` | Web UI & unified visualization console |

---

## 💾 Host Storage Architecture (`/opt/observability/data`)

Instead of Docker-managed named volumes, each instance mounts host directories directly with explicit UID/GID ownership:

```text
/opt/observability/
└── data/                   <--- Bind mounted to container engine storage
```

| Service | Container Mount Point | Host Directory | Required Ownership (UID:GID) |
| :--- | :--- | :--- | :--- |
| **Grafana** | `/var/lib/grafana` | `/opt/observability/data` | `472:472` (`grafana`) |
| **Prometheus** | `/prometheus` | `/opt/observability/data` | `65534:65534` (`nobody`) |
| **Loki** | `/loki` | `/opt/observability/data` | `10001:10001` (`loki`) |
| **Tempo** | `/var/tempo` | `/opt/observability/data` | `10001:10001` (`tempo`) |

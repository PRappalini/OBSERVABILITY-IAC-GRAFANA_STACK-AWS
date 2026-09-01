# Deployment Guide

This guide details the step-by-step process to provision and validate the Grafana Observability Stack on AWS using Terraform.

---

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Terraform** >= 1.5.0 installed (`terraform --version`) or **OpenTofu**.
2. **AWS CLI** configured with administrator or appropriate IAM credentials (`aws sts get-caller-identity`).
3. Your local workstation's public IP address to restrict Grafana UI ingress:
   ```bash
   curl -s https://checkip.amazonaws.com
   ```

---

## 🚀 Step-by-Step Provisioning

### 1. Clone Repository & Enter Terraform Directory

```bash
git clone https://github.com/PRappalini/OBSERVABILITY-IAC-GRAFANA_STACK-AWS.git
cd OBSERVABILITY-IAC-GRAFANA_STACK-AWS/terraform
```

### 2. Configure Variables

Copy the example variables file to create `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region        = "us-east-1"
availability_zone = "us-east-1a"

# Set your public IP address (CIDR /32)
grafana_allowed_cidrs = ["YOUR_PUBLIC_IP/32"]

# Optional SSH access (Leave empty to rely purely on AWS SSM)
ssh_allowed_cidrs     = []
# key_name            = "my-ec2-key"

grafana_admin_password = "YourSecurePasswordHere123!"
```

### 3. Initialize & Plan

```bash
terraform init
terraform plan -out=tfplan
```

Review the planned resources (VPC, Subnet, IGW, 4 Security Groups, 4 EC2 instances, IAM role & policies).

### 4. Apply Infrastructure

```bash
terraform apply tfplan
```

Provisioning completes in approximately **2 to 3 minutes**.

---

## ✅ Post-Deployment Verification

### 1. View Terraform Outputs

```bash
terraform output
```

You will see:
- `grafana_url`: Public HTTP endpoint for Grafana UI (`http://<EC2_PUBLIC_IP>:3000`).
- `private_ips`: Deterministic private IP addresses (`10.20.10.10` to `10.20.10.13`).

### 2. Access Grafana

1. Open `http://<GRAFANA_PUBLIC_IP>:3000` in your browser.
2. Sign in with username `admin` and your configured `grafana_admin_password`.
3. Navigate to **Connections ➔ Data Sources**:
   - **Prometheus** (Default): Green status connected to `http://10.20.10.10:9090`.
   - **Loki**: Green status connected to `http://10.20.10.11:3100`.
   - **Tempo**: Green status connected to `http://10.20.10.12:3200`.

### 3. Check Prometheus Scraping Targets

1. Connect to Prometheus node via SSM:
   ```bash
   aws ssm start-session --target <PROMETHEUS_INSTANCE_ID>
   ```
2. Inspect Prometheus targets status via curl:
   ```bash
   curl -s http://localhost:9090/api/v1/targets | jq .data.activeTargets[].scrapeUrl
   ```
   All scrape endpoints for Node Exporter (`:9100`), cAdvisor (`:8080`), and app engines (`:9090`, `:3100`, `:3200`, `:3000`) should be active and healthy.

---

## 🧹 Infrastructure Teardown

To destroy all provisioned resources and prevent ongoing AWS charges:

```bash
terraform destroy -auto-approve
```

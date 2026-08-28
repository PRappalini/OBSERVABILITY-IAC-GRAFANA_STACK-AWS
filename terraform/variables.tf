variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "name" {
  type    = string
  default = "grafana-observability"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.20.10.0/24"
}

variable "prometheus_instance_type" {
  type    = string
  default = "t3.small"
}

variable "grafana_instance_type" {
  type    = string
  default = "t3.small"
}

variable "loki_instance_type" {
  type    = string
  default = "t3.small"
}

variable "tempo_instance_type" {
  type    = string
  default = "t3.small"
}

variable "prometheus_volume_size_gb" {
  type    = number
  default = 30
}

variable "grafana_volume_size_gb" {
  type    = number
  default = 20
}

variable "loki_volume_size_gb" {
  type    = number
  default = 30
}

variable "tempo_volume_size_gb" {
  type    = number
  default = 30
}

variable "key_name" {
  type     = string
  default  = null
  nullable = true
}

variable "grafana_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = []
}

variable "grafana_admin_user" {
  type    = string
  default = "admin"
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "grafana-observability"
  }
}

resource "aws_security_group" "grafana" {
  name_prefix = "${var.name}-grafana-"
  vpc_id      = aws_vpc.this.id
  description = "Public Grafana endpoint and metric scraping"

  ingress {
    description = "Grafana Web UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.grafana_allowed_cidrs
  }

  dynamic "ingress" {
    for_each = [3000, 8080, 9100]
    content {
      description     = "Prometheus scraping (metrics, cadvisor, node-exporter)"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.prometheus.id]
    }
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-grafana" })
}

resource "aws_security_group" "prometheus" {
  name_prefix = "${var.name}-prometheus-"
  vpc_id      = aws_vpc.this.id
  description = "Prometheus endpoint accessible from Grafana"

  ingress {
    description     = "Grafana queries Prometheus"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-prometheus" })
}

resource "aws_security_group" "loki" {
  name_prefix = "${var.name}-loki-"
  vpc_id      = aws_vpc.this.id
  description = "Loki endpoint accessible from Grafana and Prometheus"

  ingress {
    description     = "Grafana queries Loki"
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  dynamic "ingress" {
    for_each = [3100, 8080, 9100]
    content {
      description     = "Prometheus scraping (loki metrics, cadvisor, node-exporter)"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.prometheus.id]
    }
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-loki" })
}

resource "aws_security_group" "tempo" {
  name_prefix = "${var.name}-tempo-"
  vpc_id      = aws_vpc.this.id
  description = "Tempo endpoint accessible from Grafana and Prometheus"

  ingress {
    description     = "Grafana queries Tempo"
    from_port       = 3200
    to_port         = 3200
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  dynamic "ingress" {
    for_each = [3200, 8080, 9100]
    content {
      description     = "Prometheus scraping (tempo metrics, cadvisor, node-exporter)"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.prometheus.id]
    }
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-tempo" })
}

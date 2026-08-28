locals {
  backends = {
    prometheus = {
      port        = 9090
      description = "Grafana queries Prometheus"
    }
    loki = {
      port        = 3100
      description = "Grafana queries Loki"
    }
    tempo = {
      port        = 3200
      description = "Grafana queries Tempo"
    }
  }
}

resource "aws_security_group" "grafana" {
  name_prefix = "${var.name}-grafana-"
  vpc_id      = aws_vpc.this.id
  description = "Public Grafana endpoint"

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.grafana_allowed_cidrs
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
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

resource "aws_security_group" "backend" {
  for_each = local.backends

  name_prefix = "${var.name}-${each.key}-"
  vpc_id      = aws_vpc.this.id
  description = "${each.key} endpoint accessible only from Grafana"

  ingress {
    description     = each.value.description
    from_port       = each.value.port
    to_port         = each.value.port
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
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

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

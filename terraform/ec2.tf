data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  docker_root           = "${path.module}/../docker"
  prometheus_private_ip = cidrhost(var.public_subnet_cidr, 10)
  loki_private_ip       = cidrhost(var.public_subnet_cidr, 11)
  tempo_private_ip      = cidrhost(var.public_subnet_cidr, 12)
  grafana_private_ip    = cidrhost(var.public_subnet_cidr, 13)
}

resource "aws_instance" "prometheus" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.prometheus_instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = local.prometheus_private_ip
  vpc_security_group_ids      = [aws_security_group.prometheus.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.prometheus_volume_size_gb
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/bootstrap-prometheus.sh.tftpl", {
    compose_file      = base64encode(file("${local.docker_root}/prometheus/docker-compose.yml"))
    prometheus_config = base64encode(file("${local.docker_root}/prometheus/prometheus.yml"))
    loki_ip           = local.loki_private_ip
    tempo_ip          = local.tempo_private_ip
    grafana_ip        = local.grafana_private_ip
  })

  metadata_options { http_tokens = "required" }
  tags = merge(var.tags, { Name = "${var.name}-prometheus" })
}

resource "aws_instance" "loki" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.loki_instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = local.loki_private_ip
  vpc_security_group_ids      = [aws_security_group.loki.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.loki_volume_size_gb
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/bootstrap-loki.sh.tftpl", {
    compose_file = base64encode(file("${local.docker_root}/loki/docker-compose.yml"))
    loki_config  = base64encode(file("${local.docker_root}/loki/loki-config.yml"))
  })

  metadata_options { http_tokens = "required" }
  tags = merge(var.tags, { Name = "${var.name}-loki" })
}

resource "aws_instance" "tempo" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.tempo_instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = local.tempo_private_ip
  vpc_security_group_ids      = [aws_security_group.tempo.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.tempo_volume_size_gb
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/bootstrap-tempo.sh.tftpl", {
    compose_file = base64encode(file("${local.docker_root}/tempo/docker-compose.yml"))
    tempo_config = base64encode(file("${local.docker_root}/tempo/tempo.yml"))
  })

  metadata_options { http_tokens = "required" }
  tags = merge(var.tags, { Name = "${var.name}-tempo" })
}

resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.grafana_instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = local.grafana_private_ip
  vpc_security_group_ids      = [aws_security_group.grafana.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.grafana_volume_size_gb
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/bootstrap-grafana.sh.tftpl", {
    compose_file           = base64encode(file("${local.docker_root}/grafana/docker-compose.yml"))
    datasource_config      = base64encode(file("${local.docker_root}/grafana/provisioning/datasources/datasources.yml"))
    prometheus_ip          = local.prometheus_private_ip
    loki_ip                = local.loki_private_ip
    tempo_ip               = local.tempo_private_ip
    grafana_admin_user     = var.grafana_admin_user
    grafana_admin_password = var.grafana_admin_password
  })

  metadata_options { http_tokens = "required" }
  tags = merge(var.tags, { Name = "${var.name}-grafana" })
}

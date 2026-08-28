output "grafana_url" {
  value = "http://${aws_instance.grafana.public_dns}:3000"
}

output "prometheus_private_ip" {
  value = aws_instance.prometheus.private_ip
}

output "loki_private_ip" {
  value = aws_instance.loki.private_ip
}

output "tempo_private_ip" {
  value = aws_instance.tempo.private_ip
}

output "prometheus_instance_id" {
  value = aws_instance.prometheus.id
}

output "grafana_instance_id" {
  value = aws_instance.grafana.id
}

output "loki_instance_id" {
  value = aws_instance.loki.id
}

output "tempo_instance_id" {
  value = aws_instance.tempo.id
}

output "private dns" {
  value = "`${join(",", aws_instance.consul.private-dns)}`"
}

output "private ips" {
  value = "`${join(",", aws_instance.consul.private-ip)}`"
}

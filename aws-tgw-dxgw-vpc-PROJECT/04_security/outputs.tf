output "workload_inbound_sg_id" {
  value = aws_security_group.workload_inbound.id
}

output "workload_nacl_id" {
  value = aws_network_acl.workload_nacl.id
}

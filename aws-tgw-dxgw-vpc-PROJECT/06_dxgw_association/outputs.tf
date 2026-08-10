output "dxgw_association_id" {
  description = "DX Gateway association ID (TGW <-> DXGW)"
  value       = aws_dx_gateway_association.tgw_dxgw_assoc.id
}

output "dxgw_association_state" {
  value = aws_dx_gateway_association.tgw_dxgw_assoc.dx_gateway_association_id
}

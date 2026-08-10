output "tgw_route_table_id" {
  value = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
}

output "dxgw_association_id" {
  value = data.terraform_remote_state.dxgw_assoc.outputs.dxgw_association_id
}

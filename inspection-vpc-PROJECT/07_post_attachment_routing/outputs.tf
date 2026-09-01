output "spoke_route_table_id" {
  description = "TGW route table ID shared by the Prod and Dev attachments"
  value       = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_spoke_id
}

output "inspection_route_table_id" {
  description = "TGW route table ID associated with the Inspection attachment"
  value       = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_inspection_id
}

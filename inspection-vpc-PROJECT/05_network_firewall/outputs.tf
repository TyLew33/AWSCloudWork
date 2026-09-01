output "firewall_arn" {
  description = "AWS Network Firewall ARN"
  value       = aws_networkfirewall_firewall.main.arn
}

output "firewall_policy_arn" {
  description = "Firewall policy ARN"
  value       = aws_networkfirewall_firewall_policy.main.arn
}

output "alert_log_group_name" {
  description = "CloudWatch Logs group receiving firewall ALERT logs (rule matches, including drops)"
  value       = aws_cloudwatch_log_group.alert.name
}

output "flow_log_group_name" {
  description = "CloudWatch Logs group receiving firewall FLOW logs (every connection seen)"
  value       = aws_cloudwatch_log_group.flow.name
}

output "firewall_endpoint_id" {
  description = "VPC endpoint ID for the firewall in the lab's single AZ - used as a route target"
  # sync_states is a set (no index), so it has to be converted to a list
  # first - safe here since this lab only ever has one AZ / one sync state.
  value = tolist(aws_networkfirewall_firewall.main.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
}

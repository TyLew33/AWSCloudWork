output "plan_role_arn" {
  description = "Set as repository variable AWS_INSPECTION_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Set as repository variable AWS_INSPECTION_APPLY_ROLE_ARN"
  value       = aws_iam_role.apply.arn
}

output "oidc_provider_arn" {
  description = "Reuse this if you add more roles later; only one per account"
  value       = aws_iam_openid_connect_provider.github.arn
}
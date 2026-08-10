output "resolver_rule_association_ids" {
  description = "Map of resolver rule key to association ID"
  value       = { for k, v in aws_route53_resolver_rule_association.shared_resolvers : k => v.id }
}

output "resolver_rule_association_names" {
  value = [for v in aws_route53_resolver_rule_association.shared_resolvers : v.name]
}

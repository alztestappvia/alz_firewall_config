output "ip_groups" {
  description = "IP Groups for all external services"
  value       = local.ip_groups
}

output "services" {
  description = "External services"
  value       = local.services
}

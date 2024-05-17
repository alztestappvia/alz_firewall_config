output "ip_groups" {
  description = "IP Groups for all on-premise services"
  value       = local.ip_groups
}

output "services" {
  description = "On-premise services"
  value       = local.services
}

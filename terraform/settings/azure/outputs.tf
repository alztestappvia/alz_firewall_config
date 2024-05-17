output "ip_groups" {
  description = "IP Groups for all Azure hosted services"
  value       = local.ip_groups
}

output "services" {
  description = "Azure hosted services"
  value       = local.services
}

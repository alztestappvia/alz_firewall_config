output "base_policy_name" {
  description = "The name of the Firewall Policy."
  value       = azurerm_firewall_policy.firewall_policy.name
}

output "base_policy_id" {
  description = "The ID of the Firewall Policy."
  value       = azurerm_firewall_policy.firewall_policy.id
}

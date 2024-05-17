variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the resources"
}

variable "sku" {
  type        = string
  description = "SKU of the Firewall Policy"
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Set tags to apply to the Resource Group"
  default = {
    WorkloadName        = "ALZ.FirewallConfiguration"
    DataClassification  = "General"
    BusinessCriticality = "Mission-critical"
    BusinessUnit        = "Platform Operations"
    OperationsTeam      = "Platform Operations"
  }
}

variable "use_oidc" {
  type        = bool
  description = "Use OpenID Connect to authenticate to AzureRM"
  default     = false
}

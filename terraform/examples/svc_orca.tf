locals {
  azure_orca = {
    ip_groups = {
      azure_orca_all = {
        cidrs = ["10.30.144.0/20"]
      }
      azure_orca_aks = {
        cidrs = ["10.30.148.0/24", "10.30.149.0/24"]
      },
    },
    rule_collection_group = {
      priority                     = 30000 # Must be unique across all defined services
      application_rule_collections = [{}]
      network_rule_collections     = [{}]
    }
  }
}

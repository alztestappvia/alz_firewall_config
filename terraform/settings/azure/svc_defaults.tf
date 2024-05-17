locals {
  azure_defaults = {
    ip_groups = {
      azure_defaults_all = {
        cidrs = [
          "172.28.0.0/16",
        ]
      },
    },
    rule_collection_group = {
      priority                     = 60000
      application_rule_collections = []
      network_rule_collections = [
        {
          name     = "allow_egress_azure_active_directory"
          priority = 1000
          action   = "Allow"
          rules = [{
            name                  = "allow_egress_azure_active_directory"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_defaults_all"]
            destination_addresses = ["AzureActiveDirectory"]
            destination_ports     = ["443"]
          }]
        },
        {
          name     = "allow_egress_azure_monitor"
          priority = 1010
          action   = "Allow"
          rules = [{
            name                  = "allow_egress_azure_monitor"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_defaults_all"]
            destination_addresses = ["AzureMonitor"]
            destination_ports     = ["443"]
          }]
        },
        {
          name     = "allow_egress_azure_update_delivery"
          priority = 1020
          action   = "Allow"
          rules = [{
            name                  = "allow_egress_azure_update_delivery"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_defaults_all"]
            destination_addresses = ["AzureUpdateDelivery"]
            destination_ports     = ["443"]
          }]
        },
        {
          name     = "allow_egress_azure_frontdoor"
          priority = 1030
          action   = "Allow"
          rules = [{
            name                  = "allow_egress_azure_frontdoor"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_defaults_all"]
            destination_addresses = ["AzureFrontDoor.FirstParty"]
            destination_ports     = ["80"]
          }]
        },
        {
          name     = "allow_egress_azure_guest_hybrid_mgmt"
          priority = 1040
          action   = "Allow"
          rules = [{
            name                  = "allow_egress_azure_guest_hybrid_mgmt"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_defaults_all"]
            destination_addresses = ["GuestAndHybridManagement"]
            destination_ports     = ["443"]
          }]
        },
        {
          name     = "allow_egress_kms"
          priority = 1050
          action   = "Allow"
          rules = [{
            name                  = "allow_egress_kms"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_defaults_all"]
            destination_ip_groups = ["external_kms"]
            destination_ports     = ["1688"]
          }]
        }
      ]
    }



  }
}

module "azure_settings" {
  source = "./settings/azure"
}

module "external_settings" {
  source = "./settings/external"
}

module "onprem_settings" {
  source = "./settings/onprem"
}

locals {
  ip_groups = merge([
    module.azure_settings.ip_groups,
    module.external_settings.ip_groups,
    module.onprem_settings.ip_groups
  ]...)

  services = merge([
    module.azure_settings.services,
    module.external_settings.services,
    module.onprem_settings.services
  ]...)
}

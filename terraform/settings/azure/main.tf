locals {
  ip_groups = merge([
    for k, v in local.services :
    { for sk, sv in v.ip_groups : sk => sv }
  ]...)

  services = {
    azure_defaults   = local.azure_defaults,
    azure_agentpools = local.azure_agentpools
  }
}

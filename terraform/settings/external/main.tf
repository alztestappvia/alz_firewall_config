locals {
  ip_groups = merge([
    for k, v in local.services :
    { for sk, sv in v.ip_groups : sk => sv }
  ]...)

  services = {
    external_github = local.external_github
    external_kms    = local.external_kms
  }
}
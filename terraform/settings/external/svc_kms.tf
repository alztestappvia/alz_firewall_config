locals {
  external_kms = {
    ip_groups = {
      external_kms = {
        cidrs = [
          "23.102.135.246/32"
        ]
      },
    }
  }
}
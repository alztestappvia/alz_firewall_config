terraform {
  required_version = ">= 1.3.1"

  backend "azurerm" {
    use_oidc         = true ### This is required for GitHub Actions
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.65.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.23"
    }
  }
}

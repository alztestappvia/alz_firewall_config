locals {
  azure_agentpools = {
    ip_groups = {
      azure_agentpools_all = {
        cidrs = [
          "172.28.4.0/25",
        ],
        tags = {
          OpsTeam = "Technology Operations"
        }
      },
    },
    rule_collection_group = {
      priority = 10000
      application_rule_collections = [
        {
          name     = "allow_egress_devops_agents_http"
          priority = 1000
          action   = "Allow"
          rules = [{
            name             = "allow_egress_devops_agents_http"
            description      = "Allow DevOps agents egress HTTP traffic"
            source_ip_groups = ["azure_agentpools_all"]
            destination_fqdns = [
              "azure.archive.ubuntu.com",
              "ctldl.windowsupdate.com",
              "www.msftconnecttest.com",
              ### CRLs ###
              "ocsp.digicert.com",
              "crl3.digicert.com",
              "crl4.digicert.com",
            ]
            protocols = [{
              type = "Http"
              port = 80
            }]
          }]
        },
        {
          name     = "allow_egress_devops_agents_https"
          priority = 1100
          action   = "Allow"
          rules = [{
            name             = "allow_egress_devops_agents_https"
            description      = "Allow Azure DevOps agents egress HTTPS traffic"
            source_ip_groups = ["azure_agentpools_all"]
            destination_fqdns = [
              "agentsvc.azure-automation.net",
              "api.snapcraft.io",
              "config.edge.skype.com",
              "entropy.ubuntu.com",
              "esm.ubuntu.com",
              "go.microsoft.com",
              "motd.ubuntu.com",
              "msedge.api.cdp.microsoft.com",
              "ne-jobruntimedata-prod-su1.azure-automation.net",
              "settings-win.data.microsoft.com",
              "slscr.update.microsoft.com",
              "v10.events.data.microsoft.com",
              "wdcp.microsoft.com",
              "wdcpalt.microsoft.com",
              "clientconfig.passport.net",
              "validation-v2.sls.microsoft.com",
              "fe2cr.update.microsoft.com",
              "fe3cr.delivery.mp.microsoft.com",
              "packages.microsoft.com",
              "*.prod.do.dsp.mp.microsoft.com",
              ### Github ###
              "github.com",
              "api.github.com",
              "raw.github.com",
              "raw.githubusercontent.com",
              "objects.githubusercontent.com",
              "github-releases.githubusercontent.com",
              "*.actions.githubusercontent.com",
              "codeload.github.com",
              "results-receiver.actions.githubusercontent.com",
              "actions-results-receiver-production.githubapp.com",
              "*.blob.core.windows.net",
              "objects-origin.githubusercontent.com",
              "github-registry-files.githubusercontent.com",
              "*.pkg.github.com",
              ### Docker ###
              "auth.docker.io",
              "registry-1.docker.io",
              "index.docker.io",
              "dseasb33srnrn.cloudfront.net",
              "production.cloudflare.docker.com",
              "mcr.microsoft.com",
              "*.data.mcr.microsoft.com",
              ### Azure DevOps ###
              "ppa.launchpadcontent.net",
              "*.visualstudio.com",
              "*.artifacts.visualstudio.com",
              "*.pkgs.visualstudio.com",
              "*.services.visualstudio.com",
              "*.vssps.visualstudio.com",
              "*.vsblob.visualstudio.com",
              "*.vsrm.visualstudio.com",
              "*.vstmr.visualstudio.com",
              "*.vsassets.io",
              "*.dev.azure.com",
              "dev.azure.com",
              "vstsagentpackage.azureedge.net",
              ### Go lang ###
              "proxy.golang.org",
              "sum.golang.org",
              ### PyPI ###
              "pypi.org",
              "files.pythonhosted.org",
              ### Google storage ###
              "storage.googleapis.com",
              ### Checkov ###
              "www.bridgecrew.cloud",
              ### Terraform ###
              "checkpoint-api.hashicorp.com",
              "*.terraform.io",
              "releases.hashicorp.com",
              ### Azure ###
              "management.azure.com",
              "azure.microsoft.com",
              "management.core.windows.net",
              ### Powershell ###
              "*.powershellgallery.com",
              "psg-prod-eastus.azureedge.net",
              "devopsgallerystorage.blob.core.windows.net"
            ]
            protocols = [{
              type = "Https"
              port = 443
            }]
          }]
        }
      ]
      network_rule_collections = [{
        name     = "allow_egress_devops_agents"
        priority = 1200
        action   = "Allow"
        rules = [{
          name                  = "allow_egress_devops_agents"
          protocols             = ["TCP"]
          source_ip_groups      = ["azure_agentpools_all"]
          destination_addresses = ["Storage", "AzureDevOps", "AzureMonitor"]
          destination_ports     = ["443"]
          },
          {
            name                  = "allow_devops_agents_egress_https"
            protocols             = ["TCP"]
            source_ip_groups      = ["azure_agentpools_all"]
            destination_ip_groups = ["azure_defaults_all"]
            destination_ports     = ["443"]
          },
          {
            name             = "allow_devops_agents_egress_azkms"
            protocols        = ["TCP"]
            source_ip_groups = ["azure_agentpools_all"]
            destination_addresses = [
              "20.118.99.224",
              "23.102.135.246",
              "40.83.235.53",
            ]
            destination_ports = ["1688"]
          }
        ]
      }]
    }
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_firewall_policy" "firewall_policy" {
  name                     = "fwpolicy-base"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  sku                      = var.sku
  threat_intelligence_mode = "Alert"

  dns {
    proxy_enabled = true
    servers       = []
  }

  tags = var.tags
}

resource "azurerm_ip_group" "group" {
  for_each = local.ip_groups

  name                = "ipgr-${each.key}"
  cidrs               = each.value.cidrs
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = merge(var.tags, lookup(each.value, "tags", {}))
}

resource "azurerm_firewall_policy_rule_collection_group" "rcg" {
  for_each = { for k, v in local.services : k => v.rule_collection_group if can(v.rule_collection_group) }

  name               = "rcg-${each.key}"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = each.value.priority

  dynamic "application_rule_collection" {
    for_each = lookup(each.value, "application_rule_collections", [])

    content {
      name     = application_rule_collection.value.name
      action   = application_rule_collection.value.action
      priority = application_rule_collection.value.priority

      dynamic "rule" {
        for_each = application_rule_collection.value.rules

        content {
          name                  = rule.value.name
          description           = rule.value.description
          destination_addresses = lookup(rule.value, "destination_addresses", null)
          destination_fqdn_tags = lookup(rule.value, "destination_fqdn_tags", null)
          destination_fqdns     = lookup(rule.value, "destination_fqdns", null)
          destination_urls      = lookup(rule.value, "destination_urls", null)
          source_addresses      = lookup(rule.value, "source_addresses", null)
          source_ip_groups      = can(rule.value.source_ip_groups) ? tolist([[for k, v in rule.value.source_ip_groups : azurerm_ip_group.group[v].id]]...) : null

          dynamic "protocols" {
            for_each = lookup(rule.value, "protocols", [])

            content {
              port = protocols.value.port
              type = protocols.value.type
            }
          }
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = lookup(each.value, "network_rule_collections", [])

    content {
      name     = network_rule_collection.value.name
      action   = network_rule_collection.value.action
      priority = network_rule_collection.value.priority

      dynamic "rule" {
        for_each = network_rule_collection.value.rules

        content {
          name                  = rule.value.name
          destination_addresses = lookup(rule.value, "destination_addresses", null)
          destination_fqdns     = lookup(rule.value, "destination_fqdns", null)
          destination_ip_groups = can(rule.value.destination_ip_groups) ? tolist([[for k, v in rule.value.destination_ip_groups : azurerm_ip_group.group[v].id]]...) : null
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
          source_addresses      = lookup(rule.value, "source_addresses", null)
          source_ip_groups      = can(rule.value.source_ip_groups) ? tolist([[for k, v in rule.value.source_ip_groups : azurerm_ip_group.group[v].id]]...) : null
        }
      }
    }
  }
}

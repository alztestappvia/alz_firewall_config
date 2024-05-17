<!-- BEGIN_TF_DOCS -->
# ALZ.FirewallConfiguration

This project creates a Firewall Policy within an existing Resource Group (provisioned by ALZ.Bootstrap), which the Azure Firewall (provisioned by ALZ.Connectivity) will then use for its configuration.

## Updating Docs

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:
1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject terraform/`

## Setup

In order to ease maintenance of Firewall Rule Collections as more services are onboarded and rules expanded, the services are split into three distinct groups:
- **"azure":** Any services hosted within Azure and exist within the new ALZ setup will have their IP Groups and Rule Collections defined here.
- **"external":** Any services that are entirely external (for example Github, Docker Hub, Microsoft Container Registry, etc) are defined here.
- **"onprem":** Any services hosted on the on-premise network are defined here.

For the latter two (external and onprem) only IP Groups are expected to be defined, which can then be referred to within the Application and Network Rules for other services hosted within Azure.

## Updating Rules

When adding a new service, the following should be done:
1. Create a new file for the service within the `settings/<group>` directory (e.g. `settings/azure`), following a naming pattern of `svc_<name>.tf` (e.g. `svc_orca.tf`)
2. Define the IP Groups and/or Firewall Rules appropriate for the service, using the group as the prefix for the service, for example:
```hcl
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
```
3. Modify the `settings/<group>/main.tf` to include the new service in the list, with the group prefix, e.g.:
```hcl
locals {
  services = {
    azure_defaults = local.azure_defaults,
    azure_orca     = local.azure_orca
  }
}
```

## Viewing Logs

Firewall logs can be analysed by running custom queries against a particular instance, as follows:
1. Navigate to the Azure Portal
2. Go to `Firewalls`
3. Select the Firewall you wish to view logs for
4. Under `Monitoring`, select `Logs`
5. Either select an example query from the list, or create a new query using the below snippet:
```sql
// Azure Firewall log data 
// Start from this query if you want to parse the logs from network rules, application rules, NAT rules, IDS, threat intelligence and more to understand why certain traffic was allowed or denied. This query will show the last 100 log records but by adding simple filter statements at the end of the query the results can be tweaked. 
// Parses the azure firewall rule log data. 
// Includes network rules, application rules, threat intelligence, ips/ids, ...
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule" or Category == "AzureFirewallApplicationRule"
//optionally apply filters to only look at a certain type of log data
//| where OperationName == "AzureFirewallNetworkRuleLog"
//| where OperationName == "AzureFirewallNatRuleLog"
//| where OperationName == "AzureFirewallApplicationRuleLog"
//| where OperationName == "AzureFirewallIDSLog"
//| where OperationName == "AzureFirewallThreatIntelLog"
| extend msg_original = msg_s
// normalize data so it's eassier to parse later
| extend msg_s = replace(@'. Action: Deny. Reason: SNI TLS extension was missing.', @' to no_data:no_data. Action: Deny. Rule Collection: default behavior. Rule: SNI TLS extension missing', msg_s)
| extend msg_s = replace(@'No rule matched. Proceeding with default action', @'Rule Collection: default behavior. Rule: no rule matched', msg_s)
// extract web category, then remove it from further parsing
| parse msg_s with * " Web Category: " WebCategory
| extend msg_s = replace(@'(. Web Category:).*','', msg_s)
// extract RuleCollection and Rule information, then remove it from further parsing
| parse msg_s with * ". Rule Collection: " RuleCollection ". Rule: " Rule
| extend msg_s = replace(@'(. Rule Collection:).*','', msg_s)
// extract Rule Collection Group information, then remove it from further parsing
| parse msg_s with * ". Rule Collection Group: " RuleCollectionGroup
| extend msg_s = replace(@'(. Rule Collection Group:).*','', msg_s)
// extract Policy information, then remove it from further parsing
| parse msg_s with * ". Policy: " Policy
| extend msg_s = replace(@'(. Policy:).*','', msg_s)
// extract IDS fields, for now it's always add the end, then remove it from further parsing
| parse msg_s with * ". Signature: " IDSSignatureIDInt ". IDS: " IDSSignatureDescription ". Priority: " IDSPriorityInt ". Classification: " IDSClassification
| extend msg_s = replace(@'(. Signature:).*','', msg_s)
// extra NAT info, then remove it from further parsing
| parse msg_s with * " was DNAT'ed to " NatDestination
| extend msg_s = replace(@"( was DNAT'ed to ).*",". Action: DNAT", msg_s)
// extract Threat Intellingence info, then remove it from further parsing
| parse msg_s with * ". ThreatIntel: " ThreatIntel
| extend msg_s = replace(@'(. ThreatIntel:).*','', msg_s)
// extract URL, then remove it from further parsing
| extend URL = extract(@"(Url: )(.*)(\. Action)",2,msg_s)
| extend msg_s=replace(@"(Url: .*)(Action)",@"\2",msg_s)
// parse remaining "simple" fields
| parse msg_s with Protocol " request from " SourceIP " to " Target ". Action: " Action
| extend 
    SourceIP = iif(SourceIP contains ":",strcat_array(split(SourceIP,":",0),""),SourceIP),
    SourcePort = iif(SourceIP contains ":",strcat_array(split(SourceIP,":",1),""),""),
    Target = iif(Target contains ":",strcat_array(split(Target,":",0),""),Target),
    TargetPort = iif(SourceIP contains ":",strcat_array(split(Target,":",1),""),""),
    Action = iif(Action contains ".",strcat_array(split(Action,".",0),""),Action),
    Policy = case(RuleCollection contains ":", split(RuleCollection, ":")[0] ,Policy),
    RuleCollectionGroup = case(RuleCollection contains ":", split(RuleCollection, ":")[1], RuleCollectionGroup),
    RuleCollection = case(RuleCollection contains ":", split(RuleCollection, ":")[2], RuleCollection),
    IDSSignatureID = tostring(IDSSignatureIDInt),
    IDSPriority = tostring(IDSPriorityInt)
| project msg_original,TimeGenerated,Protocol,SourceIP,SourcePort,Target,TargetPort,URL,Action, NatDestination, OperationName,ThreatIntel,IDSSignatureID,IDSSignatureDescription,IDSPriority,IDSClassification,Policy,RuleCollectionGroup,RuleCollection,Rule,WebCategory
| order by TimeGenerated
//| where Action contains_cs "Deny"
//| where SourceIP contains_cs "10.176.96"
```

This query can be modified easily, for example to show only Denied requests remove the comment for `| where Action contains_cs "Deny"`.

## Important Notes

1. Any generic "wildcard" rules or large IP Groups for Azure should be defined in the `settings/azure/svc_defaults.tf` file.
2. Priorities must be unique across Services at the top level (Rule Collection Groups). Priorities for individual Application or Network Rule Collections are scoped within its own Rule Collection Group.
3. There is currently a fixed upper limit of [100 IP Groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-firewall-limits) that can be associated with a single Firewall, and up to 5000 individual IP addresses or IP prefixes per each IP Group.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the resources | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | SKU of the Firewall Policy | `string` | `"Standard"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Set tags to apply to the Resource Group | `map(string)` | <pre>{<br>  "BusinessCriticality": "Mission-critical",<br>  "BusinessUnit": "Platform Operations",<br>  "DataClassification": "General",<br>  "OperationsTeam": "Platform Operations",<br>  "WorkloadName": "ALZ.FirewallConfiguration"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_base_policy_id"></a> [base\_policy\_id](#output\_base\_policy\_id) | The ID of the Firewall Policy. |
| <a name="output_base_policy_name"></a> [base\_policy\_name](#output\_base\_policy\_name) | The name of the Firewall Policy. |
<!-- END_TF_DOCS -->
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
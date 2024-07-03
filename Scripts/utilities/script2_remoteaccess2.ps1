Install-WindowsFeature -Name Routing -IncludeManagementTools - IncludeAllSubFeature

Install-WindowsFeature -Name "RSAT-RemoteAccess-PowerShell"

Install-RemoteAccess -Vpntype RoutingOnly

Get-NetAdapter | Set-NetIPInterface -Forwarding Enabled
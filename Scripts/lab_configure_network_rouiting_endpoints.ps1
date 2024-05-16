#Interactive lab
#Author:    Jesus Lopez Mesia
#Linkedin:  https://www.linkedin.com/in/susejzepol/
#Date:      May-15-2024
#Lab:       https://learn.microsoft.com/en-us/training/modules/configure-network-routing-endpoints/7-simulation-routing

[CmdletBinding()]
param (
    
    #JLopez: Resource group name to deploy the resources in the current azure subscription.
    [Parameter(Mandatory=$true, HelpMessage="Resource group name to deploy the resources in the current azure subscription.")]
    [string]$resourcegroupname,
    
    #JLopez: Location to deploy resources in the subscription.
    [Parameter(Mandatory=$true, HelpMessage="Location to deploy resources in the subscription.")]
    [string]$Location,

    #JLopez: Virtual nework name
    [Parameter(Mandatory=$true, HelpMessage="Virtual nework name.")]
    [string]$vnetName,

    #JLopez: User for the virtual machine.
    [Parameter(Mandatory=$true, HelpMessage="User for the virtual machine.")]
    [string]$vnUserName,

    #JLopez: Password for the virtual machine.
    [Parameter(Mandatory=$true, HelpMessage="Password for the virtual machine.")]
    [SecureString]$vnPassword
)

#JLopez: Print variables entered
Write-Host "Resource group:         $resourcegroupname"
Write-Host "Location:               $Location"
Write-Host "Vnet Name:              $vnetName"
Write-Host "User Name:              $vnUserName"


# 1. Create and configure a virtual network in Azure.
# 2. Deploy two virtual machines into different subnets of the virtual network.
# 3. Ensure the virtual machines have public IP addresses that won’t change over time.
# 4. Protect the virtual machine public endpoints from being accessible from the internet.
# 5. Ensure internal Azure virtual machines names and IP addresses can be resolved.
# 6. Ensure a publicly available domain name can be resolved by external queries.
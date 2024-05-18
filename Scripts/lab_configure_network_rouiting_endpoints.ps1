#Interactive lab
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      May-15-2024
#Modified date:     May-18-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-network-routing-endpoints/7-simulation-routing

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
    [string]$vmUserName,

    #JLopez: Password for the virtual machine.
    [Parameter(Mandatory=$true, HelpMessage="Password for the virtual machine.")]
    [string]$vmPassword
)

#JLopez: Print variables entered
Write-Host "Resource group:         $resourcegroupname"
Write-Host "Location:               $Location"
Write-Host "Vnet Name:              $vnetName"
Write-Host "User Name:              $vmUserName"


# 1. Create and configure a virtual network in Azure.
az group create --location $Location --resource-group $resourcegroupname

# 2. Deploy two virtual machines into different subnets of the virtual network.
az network vnet create --name $vnetName --resource-group $resourcegroupname --address-prefixes 10.40.0.0/20 --subnets '[{"name":"Subnet0","addressPrefix":"10.40.0.0/24"},{"name":"Subnet1","addressPrefix":"10.40.1.0/24"}]'

az vm create --name "az104-04-vm0" --resource-group $resourcegroupname --vnet-name $vnetName --subnet "Subnet0" --admin-username $vmUserName --admin-password $vmPassword --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

az vm create --name "az104-04-vm1" --resource-group $resourcegroupname --vnet-name $vnetName --subnet "Subnet1" --admin-username $vmUserName --admin-password $vmPassword --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

# 3. Ensure the virtual machines have public IP addresses that won’t change over time.
# 4. Protect the virtual machine public endpoints from being accessible from the internet.
# 5. Ensure internal Azure virtual machines names and IP addresses can be resolved.
# 6. Ensure a publicly available domain name can be resolved by external queries.
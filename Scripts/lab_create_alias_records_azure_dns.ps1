#Interactive lab 03
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-07-2024
#Modified date:     August-07-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/host-domain-azure-dns/6-exercise-create-alias-records

[CmdletBinding()]
param (
    #JLopez-20240807: Location
    [Parameter(Mandatory=$true)]
    [string]$l,

    #JLopez-20240807: Resource group name
    [Parameter(Mandatory=$true)]
    [string]$rg,

    #JLopez-20240807: Subscription name
    [Parameter(Mandatory=$true)]
    [string]$subscription
)

date

#JLopez-20240807: Local variables
$vnet       = "bePortalVnet"
$subnet     = "bePortalSubnet"
$nsg        = "bePortalNSG"

#JLopez-20240807: Creating a virtual network
Write-Host "Creating a virtual network" -BackgroundColor DarkGreen
az network vnet create `
    --resource-group $rg `
    --location $l `
    --name $vnet `
    --subnet-name $subnet

#JLopez-20240807: Creating a network security group
Write-Host "Creating a network security group" -BackgroundColor DarkGreen
az network nsg create `
    --resource-group $rg `
    --location $l `
    --name $nsg

az network nsg rule create `
    --resource-group $rg `
    --nsg-name $nsg `
    --name "AllowAll80" `
    --priority 101 `
    --source-address-prefixes 'Internet' `
    --source-port-ranges '*' `
    --destination-address-prefixes '*'`
    --destination-port-ranges 80 `
    --access Allow `
    --protocol Tcp `
    --description "Allow all port 80 traffic"
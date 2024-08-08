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
$aset       = "portalAvailabilitySet"

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

#JLopez-20240807: Creating web NICs
Write-Host "Creating web NICs" -BackgroundColor DarkGreen
for ($i = 0; $i -lt 2; $i++) {
    $vmNIC      = "webNIC"   + $i
    Write-Host "Creating the NIC $vmNIC" -BackgroundColor DarkGreen
    az network nic create `
        --resource-group $rg `
        --name $vmNIC `
        --vnet-name $vnet `
        --subnet $subnet `
        --network-security-group $nsg `
        --location $l
}

#JLopez-20240807: Creating an web availability set
Write-Host "Creating an web availability set" -BackgroundColor DarkGreen
az vm availability-set create `
    --resource-group $rg `
    --name $aset


#JLopez-20240807: Creating each virtual machine
Write-Host "Creating each virtual machine" -BackgroundColor DarkGreen
for ($i = 0; $i -lt 2; $i++) {
    
    $vmName     = "webVM"    + $i
    $vmNIC      = "webNIC"   + $i

    Write-Host "Creating the virtual machine $vmName" -BackgroundColor DarkGreen
    az vm create `
        --admin-username azureuser `
        --resource-group $rg `
        --name $vmName `
        --nics $vmNIC `
        --location $l `
        --image Ubuntu2204 `
        --availability-set $aset `
        --generate-ssh-keys `
        --custom-data utilities\cloud-init.txt

}
Write-Host "Virtual machines setup completed!" -BackgroundColor DarkGreen
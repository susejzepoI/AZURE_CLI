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
    [string]$vmPassword,

    #JLopez: DNS name (private and public)
    [Parameter(Mandatory=$true, HelpMessage="DNS name (private and public).")]
    [string]$dnsName
)

#JLopez: Print variables entered
Write-Host "Resource group:         $resourcegroupname"
Write-Host "Location:               $Location"
Write-Host "Vnet Name:              $vnetName"
Write-Host "User Name:              $vmUserName"
Write-Host "DNS Name:               $dnsName"


# 1. Create and configure a virtual network in Azure.
az group create --location $Location --resource-group $resourcegroupname

# 2. Deploy two virtual machines into different subnets of the virtual network.
az network vnet create --name $vnetName --resource-group $resourcegroupname --address-prefixes 10.40.0.0/20 --subnets '[{"name":"Subnet0","addressPrefix":"10.40.0.0/24"},{"name":"Subnet1","addressPrefix":"10.40.1.0/24"}]'

az vm create --name "az104-04-vm0" --resource-group $resourcegroupname --vnet-name $vnetName --subnet "Subnet0" --admin-username $vmUserName --admin-password $vmPassword --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

az vm create --name "az104-04-vm1" --resource-group $resourcegroupname --vnet-name $vnetName --subnet "Subnet1" --admin-username $vmUserName --admin-password $vmPassword --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

# 3. Ensure the virtual machines have public IP addresses that won’t change over time.
    #JLopez-18052024: Capturing the ID's for each public IP in each NIC
    $public_ip_id_vm0 = $(az network nic show --name "az104-04-vm0VMNic" --resource-group $rgn --query "ipConfigurations[0].publicIPAddress.id" --output tsv)
    $public_ip_id_vm1 = $(az network nic show --name "az104-04-vm1VMNic" --resource-group $rgn --query "ipConfigurations[0].publicIPAddress.id" --output tsv)

    az network public-ip update --ids $public_ip_id_vm0 --allocation-method Static
    az network public-ip update --ids $public_ip_id_vm1 --allocation-method Static

# 4. Protect the virtual machine public endpoints from being accessible from the internet (network security group).
    #JLopez-18052024: This was created within each virtual machine.

# 5. Ensure internal Azure virtual machines names and IP addresses can be resolved.
az network private-dns zone create --name $dnsname--resource-group $resourcegroupname
az network private-dns link vnet create --name "az104-04-vnet-link" --registration-enabled true --resource-group $resourcegroupname --virtual-network $vnetName --zone-name "contoso.org"

# 6. Ensure a publicly available domain name can be resolved by external queries.
$currentDate = Get-Date -Format "ddMMyy"
$publicdnsname = "az104-04-{0}-{1}" -f $currentDate, $dnsname 

az network dns zone create --name $publicdnsname --resource-group $resourcegroupname

    #JLopez-18052024: Seek dynamically the public IP Address of each virtual machine.
    $public_ip_vm0 = $(az network public-ip show --id $public_ip_id_vm0 --query "ipAddress" --output tsv)
    $public_ip_vm1 = $(az network public-ip show --id $public_ip_id_vm1 --query "ipAddress" --output tsv)

    #JLopez-18052024: Create the record set for each virtual machine
    az network dns record-set a add-record --zone-name $publicdnsname --resource-group $resourcegroupname --record-set-name "az104-04-vm0-rset" --ipv4-address $public_ip_vm0
    az network dns record-set a add-record --zone-name $publicdnsname --resource-group $resourcegroupname --record-set-name "az104-04-vm1-rset" --ipv4-address $public_ip_vm1
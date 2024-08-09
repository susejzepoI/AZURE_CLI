#Interactive lab 03
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-07-2024
#Modified date:     August-08-2024
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

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "      Starting Virtual machines deploy" -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

date

#JLopez-20240807: Local variables
$vnet       = "bePortalVnet"
$subnet     = "bePortalSubnet"
$nsg        = "bePortalNSG"
$aset       = "portalAvailabilitySet"
$pIP        = "myPublicIP"
$lb         = "myLoadBalancer"
$hp         = "myHealthProbe"
$rule       = "myHTTPRule"
$fIP        = "myFrontEndPool"
$bIP        = "myBackEndPool"

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
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "     virtual machines setup completed!" -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 15; $i++) {
    Write-Host "." -BackgroundColor DarkGreen
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "      Starting Load Balancer Deploy" -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez-20240808: Creating the Public IP address.
Write-Host "Creating the Public IP address." -BackgroundColor DarkGreen
az network public-ip create `
    --resource-group $rg `
    --location $l `
    --allocation-method "Static" `
    --name $pIP `
    --sku "Standard"

#JLopez-20240808: Creating the Load Balancer configurations.
Write-Host "Creating the Load Balancer configurations." -BackgroundColor DarkGreen
az network lb create `
    --resource-group $rg `
    --name $lb `
    --public-ip-address $pIP `
    --frontend-ip-name $fIP `
    --backend-pool-name $bIP `
    --sku "Standard"

az network lb probe create `
    --resource-group $rg `
    --lb-name $lb `
    --name $hp `
    --protocol "Tcp" `
    --port 80

az network lb rule create `
    --resource-group $rg `
    --lb-name $lb `
    --name $rule `
    --protocol "Tcp" `
    --frontend-port 80 `
    --backend-port 80 `
    --frontend-ip-name $fIP `
    --backend-pool-name $bIP 

#JLopez-20240808: Adding the Load balancer to each NIC.
Write-Host "Adding the Load balancer to each NIC." -BackgroundColor DarkGreen
for ($i = 0; $i -lt 2; $i++) {
    
    $vmNIC      = "webNIC"   + $i

    az network nic ip-config update `
        --resource-group $rg `
        --nic-name $vmNIC `
        --name ipconfig1 `
        --lb-name $lb `
        --lb-address-pools $bIP

}

az network public-ip show `
    --resource-group $rg `
    --name $pIP `
    --query "[ipAddress]" `
    --output tsv

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "            Load Balancer deployed." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
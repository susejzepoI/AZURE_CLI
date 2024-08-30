#Interactive lab 
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-28-2024
#Modified date:     August-30-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/improve-app-scalability-resiliency-with-load-balancer/4-exercise-configure-public-load-balancer?pivots=bash

[CmdletBinding()]
param (
    [string]$rg = "az10420240824",
    [string]$l  = "West US",
    [string]$s  = "Suscripción de Plataformas de MSDN"
)
#JLopez: Internal Parameters
$vnet_name      = "bePortalVnet"
$subnet_name    = "bePortalSubnet"
$nsg_name       = "bePortalNSG"
$vm_name        = "VM"
$aset           = "portalAvailabilitySet"
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "      Validation of the resource group." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez: Check if the current resource group exists
$check_rg = -not [bool]::Parse($(az group exists --name $rg))

#JLopez: If the resource group not exists.
if ($check_rg) {
    Write-Host "The resource group $rg doesn't exists." -BackgroundColor DarkGreen
    #JLopez: Then create the resource group.
    Write-Host "Creating the resource group [$rg]" -BackgroundColor DarkGreen
    az group create `
        --name $rg `
        --subscription $s `
        --location $l `
        --tags Project=az104Test
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "      Resource group validation done!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "       Virtual network creation." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

az network vnet create `
    --resource-group $rg `
    --name $vnet_name `
    --subnet-name $subnet_name `
    --tags Project=az104Test

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "          Virtual network Deployed." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "       Network Security group creation." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

az network nsg create `
    --resource-group $rg `
    --name $nsg_name `
    --tags Project=az104Test

az network nsg rule create `
    --resource-group $rg `
    --nsg-name $nsg_name `
    --name "Allow 80 Inbound" `
    --priority 110 `
    --source-address-prefixes "*" `
    --source-port-ranges "*" `
    --destination-address-prefixes "*" `
    --destination-port-ranges 80 `
    --access "Allow" `
    --protocol "Tcp" `
    --direction "Inbound" `
    --description "Allow inbound on port 80"

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "       Network Security group deployed." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "            Virtual machines creation." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 2; $i++) {
    $vmNIC      = "webNIC"   + $i
    Write-Host "Creating the NIC $vmNIC" -BackgroundColor DarkGreen
    az network nic create `
        --resource-group $rg `
        --name $vmNIC `
        --vnet-name $vnet_name `
        --subnet $subnet_name `
        --network-security-group $nsg_name `
        --location $l
}

Write-Host "Creating an web availability set" -BackgroundColor DarkGreen
az vm availability-set create `
    --resource-group $rg `
    --name $aset `
    --location $l `
    --tags Project=az104Test


#JLopez-20240807: Creating each virtual machine
Write-Host "Creating each virtual machine" -BackgroundColor DarkGreen
for ($i = 0; $i -lt 2; $i++) {
    
    $vmName     = $vm_name   + $i
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
        --custom-data utilities\cloud-init.txt `
        --tags Project=az104Test
        

}
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "     virtual machines setup completed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

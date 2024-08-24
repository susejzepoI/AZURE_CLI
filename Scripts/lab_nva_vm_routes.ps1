#Interactive lab 
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-21-2024
#Modified date:     August-24-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/control-network-traffic-flow-with-routes/5-exercise-create-nva-vm

[CmdletBinding()]
param (
    [string]$rg = "az10420240824",
    [string]$l  = "West US",
    [string]$s  = "Suscripción de Plataformas de MSDN"
)

#JLopez: Internal variables
$route_table    = "publicTable"
$vnet           = "vnet"
$prodSubnet     = "productionsubnet"
$pubSubnet      = "publicsubnet"
$privSubnet     = "privSubnet"
$dmzSubnet      = "dmzSubnet"

#JLopez: Check if the current resource group exists
$check_rg = $(az group exists --name $rg)

#JLopez: If the resource group not exists.
if (!$check_rg) {
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
Write-Host "         Creating the virtual network." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez: Creating the virtual network and the first subnet
az network vnet create `
    --name $vnet `
    --resource-group $rg `
    --address-prefix 10.0.0.0/16 `
    --subnet-name $pubSubnet `
    --subnet-prefixes 10.0.0.0/24 `
    --tags Project=az104Test

#JLopez: Creating the second subnet.
Write-Host "Creating the second subnet $privSubnet." -BackgroundColor DarkGreen
az network vnet subnet create `
    --name $privSubnet `
    --vnet-name $vnet `
    --resource-group $rg `
    --address-prefixes 10.0.1.0/24

#JLopez: Creating the second subnet.
Write-Host "Creating the third subnet $privSubnet." -BackgroundColor DarkGreen
az network vnet subnet create `
    --name $dmzSubnet `
    --vnet-name $vnet `
    --resource-group $rg `
    --address-prefixes 10.0.2.0/24

Write-Host "The following subnets networks were created."
az network vnet subnet list `
    --resource-group $rg `
    --vnet-name $vnet `
    --output table


Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "        Virtual network was deployed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "         Creating the route table." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez: Creating the route table
az network route-table create `
    --name $route_table `
    --resource-group $rg `
    --disable-bgp-route-propagation false

#JLopez: Creating the custom route
Write-Host "Creating the custom route." -BackgroundColor DarkGreen
az network route-table route create `
    --route-table-name $route_table `
    --resource-group $rg `
    --name $prodSubnet `
    --address-prefix 10.0.1.0/24 `
    --next-hop-type VirtualAppliance `
    --next-hop-ip-address 10.0.2.4

#JLopez: Updating the public subnet to add the route table.
Write-Host "Updating the public subnet to add the route table." -BackgroundColor DarkGreen
az network vnet subnet update `
    --name $pubSubnet `
    --vnet-name $vnet `
    --resource-group $rg `
    --route-table $route_table

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "            Route table deployed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
    
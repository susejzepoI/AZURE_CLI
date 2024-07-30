#Interactive lab 04
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      July-28-2024
#Modified date:     July-29-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/design-ip-addressing-for-azure/5-exercise-implement-vnets
#Note:              This lab uses a sandbox, the resource group was created by default with the name "learn-95b80900-4065-4559-b217-fda84ce36388".

$rgname                 = "learn-09edd69f-90ff-4d76-83cc-74dc5f23781d" #JLopez: replace this value with your resource group name.
$vnetCore               = "CoreServicesVnet"
$vnetManufactoring      = "ManufacturingVnet"
$vnetResearch           = "ResearchVnet"

$regionCore             = "West US"
$regionManufactoring    = "Norht Europe"
$regionResearch         = "West India"

#JLopez-28072024: Creating the CoreServices Vnet
az network vnet create `
    --resource-group $rgname `
    --name $vnetCore `
    --address-prefixes 10.20.0.0/16 `
    --subnets '[{"name":"GatewaySubnet","addressPrefix":"10.20.0.0/27"},{"name":"SharedServicesSubnet","addressPrefix":"10.20.10.0/24"},{"name":"DatabaseSubnet","addressPrefix":"10.20.20.0/24"},{"name":"PublicWebServiceSubnet","addressPrefix":"10.20.30.0/24"}]' `
    --location $regionCore

#JLopez-29072024: List all subnets for the first virtual network
az network vnet subnet list `
    --resource-group $rgname `
    --vnet-name $vnetCore `
    --output table
#Interactive lab 04
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      July-28-2024
#Modified date:     July-28-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/design-ip-addressing-for-azure/5-exercise-implement-vnets
#Note:              This lab uses a sandbox, the resource group was created by default with the name "learn-95b80900-4065-4559-b217-fda84ce36388".

$rgname                 = "learn-95b80900-4065-4559-b217-fda84ce36388" #JLopez: replace this value with your resource group name.
$vnetCore               = "CoreServicesVnet"
$vnetManufactoring      = "ManufacturingVnet"
$vnetResearch           = "ResearchVnet"

$regionCore             = "West US"
$regionManufactoring    = "Norht Europe"
$regionResearch         = "West India"

#Creating the CoreServices Vnet
az network vnet create `
    --resource-group $rgname `
    --name $vnetCore `
    --address-prefixes 10.20.0.0/16 `
    --location $regionCore

#Creating the subnets in CoreServices Vnet
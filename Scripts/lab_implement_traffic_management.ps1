#Interactive lab 03
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      June-03-2024
#Modified date:     June-03-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/9-simulation-load-balancer



[CmdletBinding()]
param(
    #JLopez: Location to deploy resources in the subscription.
    [Parameter(Mandatory=$true, HelpMessage="Location to deploy resources in the subscription.")]
    [string]$Location,

    #JLopez: Resource group names to deploy the resources in the current azure subscription.
    [Parameter(Mandatory=$true, HelpMessage="Name of the first resource group (this rg contains 4 virtual machines and 3 vnets + peering) to deploy.")]
    [string]$resourcegroup1name,

    [Parameter(Mandatory=$true, HelpMessage="Name of the second resource group (this rg contains the first gateway with a public IP) to deploy.")]
    [string]$resourcegroup2name,

    [Parameter(Mandatory=$true, HelpMessage="Name of the third resource group (this rg contains the second gateway with a public IP) to deploy.")]
    [string]$resourcegroup3name,

    #JLopez: Virtuals nework names
    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 1 name (this vnet contains the first 2 virtual machines).")]
    [string]$vnet1Name,

    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 2 name (this vnet contains the third virtual machine + peering to the vnet 1).")]
    [string]$vnet2Name,

    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 2 name (this vnet contains the fourth virtual machine + peering to the vnet 1).")]
    [string]$vnet3Name

)

#JLopez: Print variables entered
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "********************************************"
Write-Host "   #Author:            Jesus Lopez Mesia"
Write-Host "   #Modified date:     June-03-2024"
Write-Host "********************************************"
Write-Host ""


$msg = "Location: $Location"
Write-Host $msg
$msg = "Resource groups: {0}, {1}, {2}." -f $resourcegroup1name, $resourcegroup2name, $resourcegroup3name
Write-Host $msg 
$msg = "Vnets Names: {0}, {1}, {2}." -f $vnet1Name, $vnet2Name, $vnet3Name
Write-Host $msg 

$msg = "Starting to create the 3 resource groups in the same region ({0})." -f $Location
Write-Host $msg

az group create --location $Location `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03

az group create --location $Location `
    --resource-group $resourcegroup2name `
    --tags project=az104lab03

az group create --location $Location `
    --resource-group $resourcegroup3name `
    --tags project=az104lab03

$msg = "Creating the 3 virtual networks in the same region ({0})." -f $Location
Write-Host $msg

az network vnet create --name $vnet1Name `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03 `
    --location $Location `
    --address-prefixes 10.60.0.0/22 `
    --subnets '[{"name":"subnet0","addressPrefix":"10.60.0.0/24"},{"name":"subnet1","addressPrefix":"10.60.1.0/24"},{"name":"subnet-appgw","addressPrefix":"10.60.3.224/27"}]'

az network vnet create --name $vnet2Name `
    --resource-group $resourcegroup2name `
    --tags project=az104lab03 `
    --location $Location `
    --address-prefixes 10.62.0.0/22 `
    --subnet-name "Subnet0" `
    --subnet-prefixes 10.62.0.0/24

az network vnet create --name $vnet3Name `
    --resource-group $resourcegroup3name `
    --tags project=az104lab03 `
    --location $Location `
    --address-prefixes 10.63.0.0/22 `
    --subnet-name "Subnet0" `
    --subnet-prefixes 10.63.0.0/24
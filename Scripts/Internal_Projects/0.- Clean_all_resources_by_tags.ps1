#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   January-08-2025
#Modified date  :   January-16-2025
#Script Purpose :   This script delete all the resources deployed in resources
#                   groups with an specif tag.

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,HelpMessage="Subscripton name.")]
    [string]$subscriptionName,
    [Parameter(Mandatory=$true,HelpMessage="Tag name to search for the resources to delete.")]
    [string]$tagName,
    [Parameter(Mandatory=$true,HelpMessage="Tag value to search for the resources to delete.")]
    [string]$tagValue
)

#JLopez: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}elseif ($pwd.path -like "*Internal_projects") {
    $root = ".."
}else {
    $root = ".\Scripts"
}
Import-Module  "$root\utilities\print-message-custom-v1.psm1"

Write-Host "$(get-date)" -BackgroundColor DarkGreen

#JLopez: Check if the subscription name exists.
$subscriptionNameExists = $(az account list --query "[?name=='$subscriptionName'].name" -o tsv) 

if (-not $subscriptionNameExists) {
    Write-Host "The subscription ($subscriptionName) does not exists." -BackgroundColor DarkRed
} else {
    printMyMessage -message "Looking for all the resource groups with the tag value ($tagValue)." -c 0
        
        Write-Host "Setting the subscription context to ($subscriptionName)." -BackgroundColor DarkYellow
        # Set the subscription context
        az account set --subscription $subscriptionName
        # Get all resource groups with the specified tag value
        $resourceGroups = $(az group list --query "[?tags.$tagName=='$tagValue'].name" -o tsv)

        if(-not $resourceGroups){
            write-host "No resource groups found with the tag value ($tagValue)." -BackgroundColor DarkRed
            exit
        }

        foreach ($rg in $resourceGroups) {
            Write-Host "Resource group found: $rg" -BackgroundColor DarkYellow
        }
        
    printMyMessage -message "Resource groups validations already done." 

        $response = Read-Host "Do you want to delete all the resource groups found? (y/n)"
        $response = $response.ToLower()

        if ($response -ne 'y') {
            Write-Host "Operation cancelled by the user." -BackgroundColor DarkRed
            exit
        }

    printMyMessage -message "Deleting all resource groups with the tag value ($tagValue)." 

        foreach ($rg in $resourceGroups) {
            printMyMessage -message "Deleting resource group: $rg" -c 0
            az group delete --name $rg --yes --no-wait
        }

    printMyMessage -message "All resources groups were delete in the subscription ($subscriptionName)."
}
#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   November-20-2024
#Modified date  :   November-21-2024
#script Purpose :   Manage storage account lifecycle rules, Encryption and immutable storage polices.

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

#JLopez: Internal variables
$date                   = $(get-date -format "MMdd")
$project                = "IP3_1_" + $date
$location1              = "South Central US"
$location2              = "East US"
$rg                     = "rg_" + $project 
$vnet                   = "vnet_" + $Project

#JLopez-20241121:   The storage account name must be unique across all existing storage account names in Azure. 
#                   It must be 3 to 24 characters long, and can contain only lowercase letters and numbers.
$storage_account1       = "sa1" + $project.Replace("_","").ToLower()
$storage_account2       = "sa2" + $project.Replace("_","").ToLower()
$storage_account3       = "sadata" + $project.Replace("_","").ToLower()
$storage_account4       = "sareplica_" + $project.Replace("_","").ToLower()

printMyMessage -message "Starting with the resource group validation." -c 0

checkMyResourceGroup -rg $rg -l $location1 -t Project=$project

Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
az configure --defaults group=$rg

printMyMessage -message "Resource group validation done!."

printMyMessage -message "Deploying the ($storage_account1) storage account." -c 0

az storage account create `
    --name $storage_account1 `
    --sku 'Standard_LRS' `
    --location $location1 `
    --enable-alw true #Jlopez: this option enable both versioning and Version-Level Immutability Support option for the storage account.

printMyMessage -message "($storage_account1) was deployed!."
#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   November-20-2024
#Modified date  :   December-03-2024
#Script Purpose :   Manage storage account lifecycle rules, Encryption, Immutable blob storage and Stored access polices.

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
$project                = "IP3_2_"      + $date
$location1              = "South Central US"
$location2              = "East US"
$rg                     = "rg_"         + $project 
$vnet                   = "vnet_"       + $Project
$subnet                 = "subnet1_"    + $project
#JLopez-20241121: The storage account name must be unique across all existing storage account names in Azure. 
#JLopez-20241203: The storage account and vault name must be 3 to 24 characters long, and can contain only lowercase letters and numbers.
$key_vault              = "vault"      + $project.Replace("_","").ToLower()
$key1                   = "key"         + $project.Replace("_","").ToLower()
$storage_account1       = "sa1"         + $project.Replace("_","").ToLower()
$storage_account2       = "sa2"         + $project.Replace("_","").ToLower()
$storage_account3       = "sadata"      + $project.Replace("_","").ToLower()
$storage_account4       = "sareplica"   + $project.Replace("_","").ToLower()

printMyMessage -message "Starting with the resource group validation." -c 0

checkMyResourceGroup -rg $rg -l $location1 -t Project=$project

Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
az configure --defaults group=$rg

printMyMessage -message "Resource group validation done!."

printMyMessage -message "Deploying the ($storage_account1) virtual network." -c 0

az network vnet create `
    --name $vnet `
    --subnet-name $subnet `
    --location $location1 `
    --tags Project=$project

Write-Host "Enabling service endpoint for the subnet1." -BackgroundColor DarkGreen
#JLopez-20241126: This must be enabled in order to add the virtual network to the storage account.
az network vnet subnet update `
    --vnet-name $vnet `
    --name $subnet `
    --service-endpoints Microsoft.Storage

Write-Host "(Microsoft.Storage) service endpoint was added in the subnet1." -BackgroundColor DarkGreen

printMyMessage -message "Virtual network deplyed!."

printMyMessage -message "Deploying the ($storage_account1) storage account." -c 0


az storage account show --name $storage_account1 --output none 2>$null

if ($LASTEXITCODE -ne 0 ) {
    Write-Host "Creating the storage account ($storage_account1)." -BackgroundColor DarkGreen
    az storage account create `
        --name $storage_account1 `
        --sku 'Standard_LRS' `
        --location $location1 `
        --tags Project=$Project `
        --vnet-name $vnet `
        --subnet $subnet `
        --enable-alw true #Jlopez: this option enable both versioning and Version-Level Immutability Support option for the storage account.

    Write-Host "Creating the (backups) container." -BackgroundColor DarkGreen
    az storage container create `
        --name "backups" `
        --account-name $storage_account1

    Write-Host "Creating the (auditlogs) container." -BackgroundColor DarkGreen
    az storage container create `
        --name "auditlogs" `
        --account-name $storage_account1

    Write-Host "Creating the (dev) container." -BackgroundColor DarkGreen
    az storage container create `
        --name "dev" `
        --account-name $storage_account1

    Write-Host "Adding the immutability policy in the container until $expiration_time." -BackgroundColor DarkGreen
    az storage container immutability-policy create `
        --account-name $storage_account1 `
        --container-name "auditlogs" `
        --period 1

    Write-Host "The maximum number of immutable policies is one per container." -BackgroundColor DarkYellow
    Write-Host "The immutability policy can't not be removed until it reaches the expiration date, it can only be extended." -BackgroundColor DarkYellow

    Write-Host "Adding the access policy (read-list) in the (dev) container". -BackgroundColor DarkGreen
    az storage container policy create `
        --container-name "dev" `
        --name "read-list" `
        --account-name $storage_account1 `
        --permissions rl

    Write-Host "Adding the access policy (add-create-write) in the (dev) container". -BackgroundColor DarkGreen
    az storage container policy create `
        --container-name "dev" `
        --name "add-create-write" `
        --account-name $storage_account1 `
        --permissions acw

    Write-Host "Adding the access policy (delete) in the (dev) container". -BackgroundColor DarkGreen
    az storage container policy create `
        --container-name "dev" `
        --name "delete" `
        --account-name $storage_account1 `
        --permissions d

    Write-Host "Adding the access policy (read) in the (dev) container". -BackgroundColor DarkGreen
    az storage container policy create `
        --container-name "dev" `
        --name "read" `
        --account-name $storage_account1 `
        --permissions r

    Write-Host "Adding the access policy (full-access) in the (dev) container". -BackgroundColor DarkGreen
    az storage container policy create `
        --container-name "dev" `
        --name "full-access" `
        --account-name $storage_account1 `
        --permissions racwdl
    #JLopez-20241125: The maximum number of access policies are fine per container until the time of writing this.
    Write-Host "The maximum number of access policies are five per container." -BackgroundColor DarkYellow

    Write-Host "Adding the lifecycle management rule to the (backups) container." -BackgroundColor DarkGreen
    az storage account management-policy create `
        --account-name $storage_account1 `
        --policy  ".\Utilities\3.1.-Lifecycle_management_rule.json"
}else{
    Write-Host "The storage account ($storage_account1) already exists, no further action is required." -BackgroundColor DarkYellow
}

printMyMessage -message "($storage_account1) was deployed!."

printMyMessage -message "Deploying the ($storage_account2) storage account." -c 0


az storage account show --name $storage_account2 --output none 2>$null

if ($LASTEXITCODE -ne 0 ) {

    Write-Host "Creating the storage account ($storage_account2)." -BackgroundColor DarkGreen
    az storage account create `
        --name $storage_account2 `
        --sku 'Standard_LRS' `
        --location $location2 `
        --tags Project=$Project

    Write-Host "Creating the (images) container." -BackgroundColor DarkGreen
    az storage container create `
        --name "images" `
        --account-name $storage_account2

    Write-Host "Creating the key vault ($key_vault)." -BackgroundColor DarkGreen
    az keyvault create `
        --name $key_vault `
        --location $location2 `
        --tags Project=$project `
        --enable-rbac-authorization false ` #JLopez: to force vault access policies.

    Write-Host "Creating a new key ($key1) in the ($key_vault) vault." -BackgroundColor DarkGreen
    az keyvault key create `
        --vault-name $key_vault `
        --name $key1 `
        --protection software `
        --kty RSA `
        --size 4096 `

    
}else{
    Write-Host "The storage account ($storage_account2) already exists, no further action is required." -BackgroundColor DarkYellow
}

printMyMessage -message "($storage_account2) was deployed!."
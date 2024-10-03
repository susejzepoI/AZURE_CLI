#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      September-17-2024
#Modified date:     October-03-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-storage-security/8-simulation-storage

[CmdletBinding()]
param (
    [string]$l = "West US",
    [string]$s = "Suscripción de Plataformas de MSDN"
)

#JLopez-20240909: Import the module "print-message-custom-v1.psm1".
Import-Module ".\Scripts\utilities\print-message-custom-v1.psm1"

Write-Host "$(get-date)" -BackgroundColor DarkGreen

#JLopez-20240918: Internal variables
$day                = $(get-date -format "yyyyMMdd")
$lab                = "lab00012" + $day
$rg1                = $lab + "az10401"
$rg2                = $lab + "az10402"
$vnet               = $lab + "Vnet"
$subnet             = $lab + "Subnet"
$nsg                = $lab + "NSG"
$vm                 = "lab00012VM01"
$public_ip          = $lab + "PubIP"
$nic                = $vm  + "NIC" 
$storage_account    = $lab + "storage"
$storage_container  = $lab + "container"
$blob_name          = "Images/my_dog.JPEG"
printMyMessage -message "Starting with the resource group validation." -c 0

checkMyResourceGroup -rg $rg1 -s $s -l $l -t Project=$lab
checkMyResourceGroup -rg $rg2 -s $s -l $l -t Project=$lab

printMyMessage -message "Resource group validation done!."

Write-Host "Setting the default resource group to $rg1." -BackgroundColor DarkGreen
az configure --defaults group=$rg1

printMyMessage -message "Starting the virtual network creation." -c 0

az network vnet create `
    --name $vnet `
    --subnet-name $subnet `
    --tags Project=$lab

printMyMessage -message "Virtual network Deployed."

printMyMessage -message "Network Security group creation." -c 0

az network nsg create `
    --name $nsg `
    --tags Project=$lab

az network nsg rule create `
    --nsg-name $nsg `
    --name "default-rdp"`
    --priority 110 `
    --source-address-prefixes "*" `
    --source-port-ranges "*" `
    --destination-address-prefixes "*" `
    --destination-port-ranges 3389 `
    --access "Allow" `
    --protocol "Tcp" `
    --direction "Inbound" `
    --description "Allow rdp connections on 3389 port (for testing only)."

printMyMessage -message "Network security group deployed!."

printMyMessage -message "Starting the virtual machine ($vm) creation." -c 0

Write-Host "Creating the public IP for the NIC ($nic)." -BackgroundColor DarkGreen
az network public-ip create `
    --allocation-method "Static" `
    --name $public_ip

Write-Host "Creating the NIC ($nic) for the virtual machine ($vm)."
az network nic create `
    --name $nic `
    --vnet-name $vnet `
    --subnet $subnet `
    --network-security-group $nsg `
    --public-ip-address $public_ip `
    --location $l

#JLopez-20240918: Here I used the "2>$null" to discard any error message produced by the command. 
az vm show --name $vm --resource-group $rg1 --output none 2>$null

#JLopez-20240918: If the above command executed correctly, the $LASTEXITCODE will be zero. Otherwise, it will be a non-zero value.
if($LASTEXITCODE -ne 0){
    Write-Host "The virtual machine ($vm) does not exists. Creating a new one." -BackgroundColor DarkGreen
    az vm create `
    --name $vm `
    --admin-username azureuser `
    --nics $nic `
    --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" `
    --no-wait `
    --tags Project=$lab
}else{
    Write-Host "The virtual machine ($vm) exists. No further action is needed." -BackgroundColor DarkGreen
}


printMyMessage -message "virtual machines setup completed!."

Write-Host "Setting the default resource group to $rg2." -BackgroundColor DarkGreen
az configure --defaults group=$rg2

printMyMessage -mesage "Starting with the storage account creation." -c 0

az storage account create `
    --name $storage_account `
    --access-tier "Cool" `
    --allow-blob-public-access false `
    --sku "Standard_LRS" `
    --min-tls-version "TLS1_2" `
    --tags Project=$lab

Write-Host "Adding the account to the Storage Blob Data Owner role." -BackgroundColor DarkGreen

$PrincipalName = $(az ad user list --query "[].{UserPrincipalName:userPrincipalName}" --output tsv)
$Principalid = $(az ad user show --id $PrincipalName --query id --output tsv)
$StorageID = $(az storage account show --name $storage_account --query "id" --output tsv)

az role assignment create `
    --assignee $Principalid `
    --role "Storage Blob Data Owner" `
    --scope $StorageID

Write-Host "The account was added to the Storage Blob Data Owner role!." -BackgroundColor DarkGreen

az storage container create `
    --name $storage_container `
    --account-name $storage_account `
    --auth-mode login

Write-Host "Uploading a blob into container $storage_container." -BackgroundColor DarkGreen
az storage blob copy start `
    --account-name $storage_account `
    --destination-container $storage_container `
    --source-uri "https://raw.githubusercontent.com/susejzepoI/AZURE_CLI/main/Scripts/files/IMG_0652.JPEG" `
    --destination-blob $blob_name `
    --auth-mode login `
    --tier "Hot" `
    --tags Project=$lab
# az storage blob upload `
#     --account-name $storage_account `
#     --container-name $storage_container `
#     --file ".\Scripts\files\IMG_0652.JPEG" `
#     --name $blob_name `
#     --tier "Hot" `
#     --auth-mode login `
#     --tags Project=$lab 

$end = (Get-Date).AddMinutes(30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:00Z")
Write-Host "Generating the SAS Token for the blob ($blob_name) until ($end)." -BackgroundColor DarkGreen
$SASToken = (
                az storage blob generate-sas `
                --account-name $storage_account `
                --container-name $storage_container `
                --name $blob_name `
                --permissions r `
                --expiry $end `
                --https-only `
                --as-user `
                --auth-mode login `
                --output tsv 
            )
$BlobURL = "https://$storage_account.blob.core.windows.net/$storage_container/$blob_name"+"?"+"$SASToken"

Write-Host "Blob URL: $BlobURL" -BackgroundColor DarkGreen

printMyMessage -message "Azure storage account deployed!."

printMyMessage -message "All set!." -c 0
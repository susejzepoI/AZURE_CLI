#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      September-17-2024
#Modified date:     October-12-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-storage-security/8-simulation-storage

[CmdletBinding()]
param (
    [string]$l = "West US",
    [string]$s = "Suscripción de Plataformas de MSDN"
)

#JLopez-20241010: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}else {
    $root = ".\Scripts"
}
Import-Module  "$root\utilities\print-message-custom-v1.psm1"

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
$file_share         = $lab + "fileshared"
printMyMessage -message "Starting with the resource group validation." -c 0

checkMyResourceGroup -rg $rg1 -s $s -l $l -t Project=$lab
checkMyResourceGroup -rg $rg2 -s $s -l $l -t Project=$lab

printMyMessage -message "Resource group validation done!."

Write-Host "Setting the default resource group to $rg1." -BackgroundColor DarkGreen
az configure --defaults group=$rg1

#JLopez-20240918: Here I used the "2>$null" to discard any error message produced by the command. 
az vm show --name $vm --resource-group $rg1 --output none 2>$null

#JLopez-20240918: If the above command executed correctly, the $LASTEXITCODE will be zero. Otherwise, it will be a non-zero value.
if($LASTEXITCODE -ne 0){

    printMyMessage -message "Starting the virtual network creation." -c 0

    az network vnet create `
        --name $vnet `
        --subnet-name $subnet `
        --location $l `
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

        az network nsg rule create `
        --nsg-name $nsg `
        --name "AllowVnet80InBound"`
        --priority 120 `
        --source-address-prefixes "*" `
        --source-port-ranges "*" `
        --destination-address-prefixes "*" `
        --destination-port-ranges 80 `
        --access "Allow" `
        --protocol "Tcp" `
        --direction "Inbound" `
        --description "Allow inbound on 80 port."

    printMyMessage -message "Network security group deployed!."

    printMyMessage -message "Starting the virtual machine ($vm) creation." -c 0

    Write-Host "Creating the public IP for the NIC ($nic)." -BackgroundColor DarkGreen
    az network public-ip create `
        --allocation-method "Static" `
        --location $l `
        --name $public_ip

    Write-Host "Creating the NIC ($nic) for the virtual machine ($vm)."
    az network nic create `
        --name $nic `
        --vnet-name $vnet `
        --subnet $subnet `
        --network-security-group $nsg `
        --public-ip-address $public_ip `
        --location $l

    Write-Host "The virtual machine ($vm) does not exists. Creating a new one." -BackgroundColor DarkGreen
    az vm create `
    --name $vm `
    --admin-username azureuser `
    --admin-password "3000@UserAzure" `
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

#JLopez-20241003: Here I used the "2>$null" to discard any error message produced by the command. 
az storage account show --name $storage_account --output none 2>$null

#JLopez-20241003: If the above command executed correctly, the $LASTEXITCODE will be zero. Otherwise, it will be a non-zero value.
if ($LASTEXITCODE -ne 0)
{
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

}else{
    Write-Host "The storage account ($storage_account) exists. No further action is needed." -BackgroundColor DarkGreen
}

az storage blob show --account-name $storage_account --container-name $storage_container --name $blob_name --output none 2>$null

if($LASTEXITCODE -ne 0){

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
    

}else{
    Write-Host "The blob ($blob_name) exists. No further action is needed." -BackgroundColor DarkGreen
}

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

printMyMessage -message "Creating the File share ($file_share) in the account ($storage_account)." -c 0

Write-Host "Retriving the key for the storage ($storage_account)." -BackgroundColor DarkGreen
$StorageKey = $(az storage account keys list --account-name $storage_account --query "[0].value" --output tsv)

az storage share create `
    --account-name $storage_account `
    --name $file_share `
    --account-key $StorageKey `
    --metadata Project=$lab `
    --quota 1

Write-Host "Connecting the virtual machine ($vm) with the share file ($file_share)." -BackgroundColor DarkGreen

# $VMPowerState = $(
#                     az vm show `
#                         --resource-group $rg1 `
#                         --name $vm `
#                         --show-details `
#                         --query 'powerState' `
#                         --output tsv
#                 )

#JLopez-20241012: This command does not work as expected.
#                 It seems that the user running the azure extension does not have the privileges to
#                 add a new drive in the virtual machine. If you run the script manully it works. Because,
#                 you're logged with your account.

# while ($VMPowerState -ne "VM running"){
#     Write-Host "Waiting until the virtual machine start running, vm current state: $VMPowerState." -BackgroundColor DarkGreen
# }

# az vm extension set `
#     --resource-group $rg1 `
#     --vm-name $vm `
#     --name CustomScriptExtension `
#     --publisher Microsoft.Compute `
#     --version 1.10 `
#     --settings "{'fileUris':['https://raw.githubusercontent.com/susejzepoI/AZURE_CLI/Testing/Scripts/utilities/00012-cloud-init-windows.ps1'],'commandToExecute':'powershell -ExecutionPolicy RemoteSigned -File 00012-cloud-init-windows.ps1 -account $storage_account -shared $file_share -key $StorageKey -drive Z:'}" `

printMyMessage -message "The file share ($file_share) was deployed and connected in the ($vm) machine." -c 0
printMyMessage -message "All set!." -c 0
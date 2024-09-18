#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      September-17-2024
#Modified date:     September-18-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-storage-security/8-simulation-storage

[CmdletBinding()]
param (
    [string]$l = "West US",
    [string]$s = "Suscripción de Plataformas de MSDN"
)

#JLopez-20240909: Import the module "print-message-custom-v1.psm1".
Import-Module ".\Scripts\utilities\print-message-custom-v1.psm1"

#JLopez-20240918: Internal variables
$lab                = "lab00012"
$rg1                = $lab + "az10401"
$rg2                = $lab + "az10402"
$vnet               = $lab + "Vnet"
$subnet             = $lab + "Subnet"
$nsg                = $lab + "NSG"
$vm                 = $lab + "VM01"
$public_ip          = $lab + "PubIP"
$nic                = $vm  + "NIC" 
$storage_account    = $lab + "storage"

printMyMessage -message "Starting with the resource group validation." -c 0

checkMyResourceGroup -rg $rg1 -s $s -l $l -t Project=$lab
checkMyResourceGroup -rg $rg2 -s $s -l $l -t Project=$lab

printMyMessage -message "Resource group validation done!."

printMyMessage -message "Starting the virtual network creation." -c 0

az network vnet create `
    --resource-group $rg1 `
    --name $vnet `
    --subnet-name $subnet `
    --tags Project=$lab

printMyMessage -message "Virtual network Deployed."

printMyMessage -message "Network Security group creation." -c 0

az network nsg create `
    --resource-group $rg1 `
    --name $nsg `
    --tags Project=$lab

az network nsg rule create `
    --resource-group $rg1 `
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
    --resource-group $rg1 `
    --allocation-method "Static" `
    --name $public_ip

Write-Host "Creating the NIC ($nic) for the virtual machine ($vm)."
az network nic create `
    --resource-group $rg1 `
    --name $nic `
    --vnet-name $vnet `
    --subnet $subnet `
    --network-security-group $nsg `
    --public-ip-address $public_ip `
    --location $l

#JLopez-20240918: Here I used the "2>$null" to discard any error message produced by the command. 
az vm show --name $vm --resource-group $rg --output none 2>$null

#JLopez-20240918: If the above command executed correctly, the $LASTEXITCODE will be zero. Otherwise, it will be a non-zero value.
if($LASTEXITCODE -ne 0){
    Write-Host "The virtual machine ($vm) does not exists. Creating a new one." -BackgroundColor DarkGreen
    az vm create `
    --name $vm `
    --resource-group $rg1 `
    --admin-username azureuser `
    --nics $nic `
    --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" `
    --no-wait `
    --tags Project=$lab
}else{
    Write-Host "The virtual machine ($vm) does exists. No further action is needed." -BackgroundColor DarkGreen
}


printMyMessage -message "virtual machines setup completed!."

printMyMessage -mesage "Starting with the storage account creation." -c 0

az storage account create `
    --name $storage_account `
    --resource-group $rg2 `
    --access-tier "Cool" `
    --allow-blob-public-access false `
    --sku "Standard_LRS" `
    --tags Project=$lab

printMyMessage -message "Azure storage account deployed!."

printMyMessage -message "All set!." -c 0
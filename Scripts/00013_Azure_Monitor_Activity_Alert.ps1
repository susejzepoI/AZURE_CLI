#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      October-23-2024
#Modified date:     October-23-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/incident-response-with-alerting-on-azure/8-exercise-activity-log-alerts

[CmdletBinding()]
param (
    [string]$l = "West US",
    [string]$s = "Suscripción de Plataformas de MSDN"
)

#JLopez: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}else {
    $root = ".`Scripts"
}
Import-Module  "$root`utilities`print-message-custom-v1.psm1"

Write-Host "$(get-date)" -BackgroundColor DarkGreen

#JLopez: Internal variables
$day                = $(get-date -format "yyyyMMdd")
$lab                = "lab00013" + $day
$rg1                = $lab + "az10401"
$vnet               = $lab + "Vnet"
$subnet             = $lab + "Subnet"
$nsg                = $lab + "NSG"
$vm                 = "lab00013VM0"
$nic                = $lab + "NICaz10401"

printMyMessage -message "Starting with the resource group validation." -c 0
checkMyResourceGroup -rg $rg1 -s $s -l $l -t Project=$lab
printMyMessage -message "Resource group validation done!."

Write-Host "Setting the default resource group to $rg1." -BackgroundColor DarkGreen
az configure --defaults group=$rg1

#JLopez: Here I used the "2>$null" to discard any error message produced by the command. 
az vm show --name $vm --resource-group $rg1 --output none 2>$null

#JLopez: If the above command executed correctly, the $LASTEXITCODE will be zero. Otherwise, it will be a non-zero value.
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

    printMyMessage -message "Network security group deployed!."

    printMyMessage -message "Starting the virtual machine ($vm) creation." -c 0

    for ($i = 0; $i -lt 2; $i++) {

        $public_ip  = "$vm_public_$i"
        $vm         = $vm + $i
        $nic        = $nic + $i

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
    }
   
    
}else{
    Write-Host "The virtual machine ($vm) exists. No further action is needed." -BackgroundColor DarkGreen
}

    printMyMessage -message "virtual machines setup completed!."


printMyMessage -message "Alerts creation for the virtual machines." -c 0

az monitor metrics alert create `
    -n "Cpu80PercentAlert" `
    --resource-group "[sandbox resource group name]" `
    --scopes $VMID `
    --condition "max percentage CPU > 80" `
    --description "Virtual machine is running at or greater than 80% CPU utilization" `
    --evaluation-frequency 1m `
    --window-size 1m `
    --severity 3


    printMyMessage -message "Alerts Deployed!." -c 0
#Interactive lab 
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-28-2024
#Modified date:     September-09-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/improve-app-scalability-resiliency-with-load-balancer/4-exercise-configure-public-load-balancer?pivots=bash

[CmdletBinding()]
param (
    [string]$rg = "az10420240909",
    [string]$l  = "West US",
    [string]$s  = "Suscripción de Plataformas de MSDN"
)

#JLopez-20240909: Import the module "print-message-custom-v1.psm1".
Import-Module ".\Scripts\utilities\print-message-custom-v1.psm1"

#JLopez: Internal Parameters
$vnet_name              = "bePortalVnet"
$subnet_name            = "bePortalSubnet"
$nsg_name               = "bePortalNSG"
$vm_name                = "VM"
$aset                   = "portalAvailabilitySet"
$public_ip              = "myPublicIP"
$load_balancer          = "myLoadBalancer"
$frontend_pool          = "myFrontEndPool"
$backend_pool           = "myBackEndPool"
$health_probe           = "myHealthProbe"
$load_balancer_rule     = "myHTTPRule"

printMyMessage -message "Validation of the resource group."

#JLopez: Check if the current resource group exists
$check_rg = -not [bool]::Parse($(az group exists --name $rg))

#JLopez: If the resource group not exists.
if ($check_rg) {
    Write-Host "The resource group $rg doesn't exists." -BackgroundColor DarkGreen
    #JLopez: Then create the resource group.
    Write-Host "Creating the resource group [$rg]" -BackgroundColor DarkGreen
    az group create `
        --name $rg `
        --subscription $s `
        --location $l `
        --tags Project=az104Test
}

printMyMessage -message "Resource group validation done!."

printMyMessage -message "Virtual network creation." -c 0

az network vnet create `
    --resource-group $rg `
    --name $vnet_name `
    --subnet-name $subnet_name `
    --tags Project=az104Test

printMyMessage -message "Virtual network Deployed."

printMyMessage -message "Network Security group creation." -c 0

az network nsg create `
    --resource-group $rg `
    --name $nsg_name `
    --tags Project=az104Test

az network nsg rule create `
    --resource-group $rg `
    --nsg-name $nsg_name `
    --name "AllowVnet80InBound" `
    --priority 110 `
    --source-address-prefixes "*" `
    --source-port-ranges "*" `
    --destination-address-prefixes "*" `
    --destination-port-ranges 80 `
    --access "Allow" `
    --protocol "Tcp" `
    --direction "Inbound" `
    --description "Allow inbound on port 80"

printMyMessage -message "Network Security group deployed."

printMyMessage -message "Virtual machines creation." -c 0

for ($i = 0; $i -lt 4; $i++) {
    $NIC      = "webNIC"   + $i
    Write-Host "Creating the NIC ($NIC)." -BackgroundColor DarkGreen
    az network nic create `
        --resource-group $rg `
        --name $NIC `
        --vnet-name $vnet_name `
        --subnet $subnet_name `
        --network-security-group $nsg_name `
        --location $l
}

#JLopez-20240807: Creating an web availability set
Write-Host "Creating an web availability set ($aset)." -BackgroundColor DarkGreen
az vm availability-set create `
    --resource-group $rg `
    --name $aset `
    --location $l `
    --tags Project=az104Test


#JLopez-20240807: Creating each virtual machine
Write-Host "Creating each virtual machine." -BackgroundColor DarkGreen
for ($i = 0; $i -lt 4; $i++) {
    
    $vm       = $vm_name   + $i
    $NIC      = "webNIC"   + $i

    #JLopez-20240905: Adding a condition to verify if the $i value is odd or even.
    if($i % 2 -eq 0 ){
        Write-Host "Creating the virtual machine ($vm)." -BackgroundColor DarkGreen
        az vm create `
            --admin-username azureuser `
            --resource-group $rg `
            --name $vm `
            --nics $NIC `
            --location $l `
            --image Ubuntu2204 `
            --availability-set $aset `
            --generate-ssh-keys `
            --custom-data utilities\cloud-init.txt `
            --tags Project=az104Test
    }else{
        #JLopez-20240905: Creating windows server machines.
        Write-Host "Creating the virtual machine ($vm)."  -BackgroundColor DarkGreen
        az vm create `
            --admin-username azureuser `
            --resource-group $rg `
            --name $vm `
            --nics $NIC `
            --location $l `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"`
            --availability-set $aset `
            --generate-ssh-keys `
            --tags Project=az104Test
    
        Write-Host "Adding configurations for the ($vm)."  -BackgroundColor DarkGreen
        az vm extension set `
            --publisher Microsoft.Compute `
            --version 1.9 `
            --name CustomScriptExtension `
            --vm-name $vm `
            --resource-group $rg `
            --settings "{'fileUris':['https://raw.githubusercontent.com/susejzepoI/AZURE_CLI/Testing/Scripts/utilities/cloud-init-windows.ps1'],'commandToExecute':'powershell -ExecutionPolicy Unrestricted -File cloud-init-windows.ps1'}" `
            --no-wait
    }


}

printMyMessage -message "virtual machines setup completed!."

printMyMessage -message "Load balancer creation." -c 0

#JLopez: Creating the public IP
Write-Host "Creating the public IP ($public_ip)." -BackgroundColor DarkGreen
az network public-ip create `
    --resource-group $rg `
    --allocation-method "Static" `
    --name $public_ip

#JLopez: Creating the load balancer
Write-Host "Creating the load balancer ($load_balancer)." -BackgroundColor DarkGreen
az network lb create `
    --resource-group $rg `
    --name $load_balancer `
    --public-ip-address $public_ip `
    --frontend-ip-name $frontend_pool `
    --backend-pool-name $backend_pool `
    --tags Project=az104Test

#JLopez: Creating the load balancer health probe
Write-Host "Creating the load balancer health probe ($health_probe)." -BackgroundColor DarkGreen
az network lb probe create `
    --resource-group $rg `
    --lb-name $load_balancer `
    --name $health_probe `
    --protocol "Tcp" `
    --port 80


#JLopez: Creating the load balancer rule
Write-Host "Creating the load balancer rule  ($load_balancer_rule)." -BackgroundColor DarkGreen
az network lb rule create `
    --resource-group $rg `
    --lb-name $load_balancer `
    --name $load_balancer_rule `
    --protocol "Tcp" `
    --frontend-port 80 `
    --backend-port 80 `
    --frontend-ip-name $frontend_pool `
    --backend-pool-name $backend_pool `
    --probe-name $health_probe

#JLopez: Updating the virtual machines NIC.
for ($i = 0; $i -lt 4; $i++) {
    $NIC = "webNIC" + $i

    Write-Host "Updating the configuration for the ($NIC) NIC." -BackgroundColor DarkGreen
    az network nic ip-config update `
        --resource-group $rg `
        --nic-name $NIC `
        --name "ipconfig1" `
        --lb-name $load_balancer `
        --lb-address-pools $backend_pool
}

printMyMessage -message "Load balancer deployed!." -c 0

$message = "http://" + $(
                            az network public-ip show `
                                --resource-group $rg `
                                --name $public_ip `
                                --query ipAddress `
                                --output tsv
                        )

Write-Host $message -BackgroundColor DarkGreen
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      October-23-2024
#Modified date:     November-03-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/incident-response-with-alerting-on-azure/8-exercise-activity-log-alerts

[CmdletBinding()]
param (
    [string]$l = "West US",
    [string]$s = "Suscripción de Plataformas de MSDN",
    [Parameter(Mandatory= $true, HelpMessage="First Email to be used in the action group.")]
    [string]$e1,
    [Parameter(Mandatory= $true, HelpMessage="Backup Email to be used in the action group.")]
    [string]$e2
)

#JLopez: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}else {
    $root = ".\Scripts"
}
Import-Module  "$root\utilities\print-message-custom-v1.psm1"

Write-Host "$(get-date)" -BackgroundColor DarkGreen

#JLopez: Internal variables
$day                    = $(get-date -format "MMdd")
$lab                    = "lab00013" + $day
$rg1                    = $lab + "az104"
$vnet                   = $lab + "Vnet"
$subnet                 = $lab + "Subnet"
$nsg                    = $lab + "NSG"
$vm                     = "lab00013VM"
$nic                    = $lab + "NIC1az104"
$action_group1          = $lab + "1ag"
$action_group2          = $lab + "2ag"
$activity_log_alert     = "VMDeletionAlert"
$metric_alert           = "Cpu80PercentAlert"
$analytics_workspace    = "defaultaz104"

printMyMessage -message "Starting with the resource group validation." -c 0
checkMyResourceGroup -rg $rg1 -s $s -l $l -t Project=$lab
printMyMessage -message "Resource group validation done!."

Write-Host "Setting the default resource group to $rg1." -BackgroundColor DarkGreen
az configure --defaults group=$rg1

$vm1_name = $vm + "1"
$vm2_name = $vm + "2"
$vm3_name = $vm + "3"

#JLopez: Here I used the "2>$null" to discard any error message produced by the command. 
az vm show --name $vm1_name --output none 2>$null

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

    az monitor log-analytics workspace create `
        --workspace-name $analytics_workspace `
        --location $l

    printMyMessage -message "Starting the virtual machines creation." -c 0

    for ($i = 1; $i -le 3; $i++) {

        $public_ip  = "publicIP" + $i
        $pvm         = $vm + $i
        $pnic        = $nic + $i

        Write-Host "Creating the public IP for the NIC ($nic)." -BackgroundColor DarkGreen
        az network public-ip create `
            --allocation-method "Static" `
            --location $l `
            --name $public_ip
    
        Write-Host "Creating the NIC ($pnic) for the virtual machine ($pvm)." -BackgroundColor DarkGreen
        az network nic create `
            --name  $pnic `
            --vnet-name $vnet `
            --subnet $subnet `
            --network-security-group $nsg `
            --public-ip-address $public_ip `
            --location $l
    
        Write-Host "The virtual machine ( $pvm ) does not exists. Creating a new one." -BackgroundColor DarkGreen
        az vm create `
        --name  $pvm  `
        --admin-username azureuser `
        --admin-password "3000@UserAzure" `
        --nics  $pnic `
        --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" `
        --no-wait `
        --tags Project=$lab

    }
    
}else{
    Write-Host "The virtual machines exist. No further action is needed." -BackgroundColor DarkGreen
}
printMyMessage -message "virtual machines setup completed!."


printMyMessage -message "Enabling monitor diagnosis for each virtual machine!" -c 0
do {
        $VMPowerState = $(
                            az vm show `
                                --resource-group $rg1 `
                                --name $vm1_name  `
                                --show-details `
                                --query 'powerState' `
                                --output tsv
                        )
        
        Write-Host "Waiting until the virtual machine start running, vm current state: $VMPowerState." -BackgroundColor DarkGreen

}while ($VMPowerState -ne "VM running")

for ($i = 1; $i -le 3; $i++) {

    $pvm         = $vm + $i
    $vm_id = $(az vm show --name $pvm --query "id" --output tsv)
    $name_diagnosis_log ="checkMy_" + $pvm

    az monitor diagnostic-settings create `
        --name $name_diagnosis_log `
        --resource $vm_id `
        --workspace $analytics_workspace 
}
printMyMessage -message "Monitor diagnosis was enabled for each virtual machine!"

printMyMessage -message "Alerts creation for the virtual machines." -c 0

Write-Host "Creating new action groups for the alerts." -BackgroundColor DarkGreen
az monitor action-group create `
    --action-group-name $action_group1 `
    --action email admin $e1 `
    --tags Project=$lab

az monitor action-group create `
    --action-group-name $action_group2 `
    --action email admin $e2 `
    --tags Project=$lab

$vm1ID = $(az vm show --name $vm1_name --query "id"--output tsv)
$vm2ID = $(az vm show --name $vm2_name --query "id"--output tsv)
$vm3ID = $(az vm show --name $vm3_name --query "id"--output tsv)

Write-Host "Checking if the alert ($metric_alert) exists."  -BackgroundColor DarkGreen
az monitor metrics alert show --name $metric_alert --output none 2>$null

if($LASTEXITCODE -ne 0){

    Write-Host "Creating a new metric alert for each virtual machine." -BackgroundColor DarkGreen
    az monitor metrics alert create `
        --name $metric_alert `
        --resource-group $rg1 `
        --scopes $vm1ID $vm2ID $vm3ID `
        --condition "max percentage CPU > 80" `
        --description "Virtual machine is running at or greater than 80% CPU utilization" `
        --evaluation-frequency 1m `
        --window-size 1m `
        --severity 3 `
        --action $action_group1 `
        --tags Project=$lab `
        --region $l
}else{
    Write-Host "The metric alert already exists. No further action is needed." -BackgroundColor DarkGreen
}

Write-Host "Checking if the alert ($activity_log_alert) exists."  -BackgroundColor DarkGreen
az monitor activity-log alert show --name $activity_log_alert --output none 2>$null

if($LASTEXITCODE -ne 0){

    Write-Host "Creating a new activity log alert for each virtual machine in case of deletion." -BackgroundColor DarkGreen
    az monitor activity-log alert create `
        --name $activity_log_alert `
        --scope $vm1ID $vm2ID $vm3ID `
        --condition category=Administrative and operationName='Microsoft.Compute/virtualMachines/delete' `
        --action-group $action_group1 `
        --description "The virtual machine was deleted." `
        --tags Project=$lab

}else{
    Write-Host "The activity log alert already exists. No further action is needed." -BackgroundColor DarkGreen
}

Write-host "Deleting the virtual machine ($vm1_name) to trigger the <VMDeletionAlert>." -BackgroundColor DarkYellow
az vm delete `
    --name $vm1_name `
    --force-deletion true `
    --yes

Write-host "The virtual machine ($vm1_name) was deleted." -BackgroundColor DarkGreen

$ResourcegroupId = $(az group show --name $rg1 --query "id" --output tsv)

Write-Host "Adding a alert processing rule to add an action group to revious rules." -BackgroundColor DarkGreen

$action_group2_id = $( az monitor action-group show --name $action_group2 --query "id" --output tsv)

az monitor alert-processing-rule create `
    --name "add notification group" `
    --rule-type AddActionGroups `
    --action-group $action_group2_id  `
    --scopes $ResourcegroupId `
    --description "Add action group to all alerts."

Write-Host "Processing rule added." -BackgroundColor DarkGreen

Write-Host "Deleting the second virtual machine to test the processing rule." -BackgroundColor DarkYellow
az vm delete `
    --name $vm2_name `
    --force-deletion true `
    --yes
Write-host "The virtual machine ($vm2_name) was deleted." -BackgroundColor DarkGreen

# Write-Host "Adding a alert processing rule to remove all notifications from previous rules." -BackgroundColor DarkGreen
# az monitor alert-processing-rule create `
#     --name "Remove notifications due to maintenance window" `
#     --rule-type RemoveAllActionGroups `
#     --scopes $ResourcegroupId `
#     --filter-resource-type Equals "microsoft.compute/virtualmachines" `
#     --description "Removes all notifications from action groups from all alerts."

# Write-Host "Processing rule added." -BackgroundColor DarkGreen

printMyMessage -message "All Alerts Deployed!." -c 0
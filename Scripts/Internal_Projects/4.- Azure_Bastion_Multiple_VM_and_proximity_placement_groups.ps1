#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   December-19-2024
#Modified date  :   December-19-2024
#Script Purpose :   Created an azure bastion for all virtual machines in different regions, deploy vms in proximity placement groups.

#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   November-20-2024
#Modified date  :   December-18-2024
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
$date                       = $(get-date -format "MMdd")
$project                    = "IP4_1_"      + $date
$location1                  = "South Central US"
$location2                  = "East US"
$location3                  = "West US"
$rg1                        = "rg1_"        + $project 
$rg2                        = "rg2_"        + $project
$rg3                        = "rg3_"        + $project 
$vm                         = "vm"
$nic                        = "nic"
$vnet                       = "vnet"
$vnet_address               = "10.0.0.0/16"
$default_subnet             = "default" 
$default_subnet_address     = "10.0.1.0/24"
#JLopez-20241219: This is required in order to connect the Bastion to each subnet and this subnet have to be exclusive for azure bastion.
$bastion_subnet             = "azurebastionsbunet" 
$bastion_subnet_address     = "10.0.2.0/26"

printMyMessage -message "Starting with the resource groups validations." -c 0

    checkMyResourceGroup -rg $rg1 -l $location1 -t Project=$project
    checkMyResourceGroup -rg $rg2 -l $location2 -t Project=$project
    checkMyResourceGroup -rg $rg3 -l $location3 -t Project=$project

printMyMessage -message "Resource groups validations done!."


printMyMessage -message "Starting with the virtual machine deployment." -c 0

    for ($i = 1; $i -le 3; $i++) {

        $vnet_name = $vnet.Replace("vnet", "vnet$i")
        $nic_name = $nic.Replace("nic", "nic$i")
        $vm_name = $vm.Replace("vm", "vm$i")

        switch ($i) {
            1 
                { 
                    $l = $location1
                    $rg = $rg1
                }
            2 
                { 
                    $l = $location2
                    $rg = $rg2
                }
            3 
                {   
                    $l = $location3
                    $rg = $rg3
                }
            Default 
                {   
                    $l = $location3
                    $rg = $rg3
                }
        }

        Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
        az configure --defaults group=$rg

        Write-Host "Deploying the $vnet_name in $rg." -BackgroundColor DarkGreen
        az network vnet create `
            --name $vnet_name `
            --address-prefixes $vnet_address `
            --subnets '[{"name":"$default_subnet","addressPrefix":"$default_subnet_address"},{"name":"$bastion_subnet","addressPrefix":"$bastion_subnet_address"}]' `
            --location $l `
            --tags Project=$project

        Write-Host "Deploying the $nic_name in $rg." -BackgroundColor DarkGreen
        az network nic create `
            --name $nic_name `
            --vnet-name $vnet_name `
            --subnet $default_subnet `
            --location $l `
            --tags Project=$project

        Write-Host "Deploying the $vm_name in $rg." -BackgroundColor DarkGreen
        az vm create `
            --name $vm_name `
            --resource-group $rg `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" `
            --admin-username azureuser `
            --admin-password "3000@UserAzure" `
            --nics $nic_name `
            --location $l `
            --tags Project=$project `
            --no-wait
    }

printMyMessage -message "All virtual machines were deployed!."

Write-Host "Setting the default resource group to $rg1." -BackgroundColor DarkGreen
az configure --defaults group=$rg1
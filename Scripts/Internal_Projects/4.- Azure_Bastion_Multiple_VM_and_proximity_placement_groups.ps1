#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   December-19-2024
#Modified date  :   January-07-2025
#Script Purpose :   Created a single azure bastion for all virtual machines in different regions and 
#                   using hub-and-spoke topology and peering between vnets, 
#                   deploy virtual machines in a proximity placement group.

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
$date                       = $(get-date -format "yyyyMMdd")
$project                    = "IP4_1_"      + $date
$location1                  = "South Central US"
$public_ip                  = "Hubbastion-ip"       
$rg1                        = "rg1_spoke_"      + $project 
$rg2                        = "rg2_spoke_"      + $project
$rg3                        = "rg3_hub_"        + $project 
$rg4                        = "rg4_spoke_"      + $project 
$ppg                        = "ppg1"            + $project 
$vm                         = "vm"
$nic                        = "nic"
$vnet                       = "vnet"

printMyMessage -message "Starting with the resource groups validations." -c 0

    checkMyResourceGroup -rg $rg1 -l $location1 -t Project=$project
    checkMyResourceGroup -rg $rg2 -l $location1 -t Project=$project
    checkMyResourceGroup -rg $rg3 -l $location1 -t Project=$project
    checkMyResourceGroup -rg $rg4 -l $location1 -t Project=$project

printMyMessage -message "Resource groups validations done!."

printMyMessage -message "Creating the proximity placement group." -c 0
    
    Write-Host "Setting the default resource group to $rg1." -BackgroundColor DarkGreen
    az configure --defaults group=$rg1
    az configure --defaults location=$location1

    #JLopez-20250701: 
    #                A proximity placement group is a resource in azure.
    #                You need to create one before using it with other resources.
    $ppg_id =   (
            az ppg create --name $ppg  `
                --type "Standard"  `
                --tags Project=$project  `
                --query "id"  `
                --output tsv
        )

printMyMessage -message "Proximity placement group created."


printMyMessage -message "Starting with the virtual machine deployment." -c 0

    for ($i = 1; $i -le 4; $i++) {

        $vnet_name = $vnet.Replace("vnet", "vnet$i")
        $nic_name = $nic.Replace("nic", "nic$i")
        $vm_name = $vm.Replace("vm", "vm$i")

        switch ($i) {
            1 
                { 
                    $rg = $rg1
                    $vnet_address               = "11.0.0.0/16"
                    $default_subnet             = "default" 
                    $default_subnet_address     = "11.0.1.0/24"
                    #JLopez-20241219: This is required in order to connect the Bastion to each subnet and this subnet have to be exclusive for azure bastion.
                    $bastion_subnet             = "AzureBastionSubnet" 
                    $bastion_subnet_address     = "11.0.2.0/26"
                }
            2 
                { 
                    $rg = $rg2
                    $vnet_address               = "12.0.0.0/16"
                    $default_subnet             = "default" 
                    $default_subnet_address     = "12.0.1.0/24"
                    #JLopez-20241219: This is required in order to connect the Bastion to each subnet and this subnet have to be exclusive for azure bastion.
                    $bastion_subnet             = "AzureBastionSubnet" 
                    $bastion_subnet_address     = "12.0.2.0/26"
                }
            3 
                {   
                    $rg = $rg3
                    $vnet_address               = "13.0.0.0/16"
                    $default_subnet             = "default" 
                    $default_subnet_address     = "13.0.1.0/24"
                    #JLopez-20241219: This is required in order to connect the Bastion to each subnet and this subnet have to be exclusive for azure bastion.
                    $bastion_subnet             = "AzureBastionSubnet" 
                    $bastion_subnet_address     = "13.0.2.0/26"
                }
            default 
                {   
                    $rg = $rg4
                    $vnet_address               = "14.0.0.0/16"
                    $default_subnet             = "default" 
                    $default_subnet_address     = "14.0.1.0/24"
                    #JLopez-20241219: This is required in order to connect the Bastion to each subnet and this subnet have to be exclusive for azure bastion.
                    $bastion_subnet             = "AzureBastionSubnet" 
                    $bastion_subnet_address     = "14.0.2.0/26"
                }
        }

        Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
        az configure --defaults group=$rg

        Write-Host "Deploying the $vnet_name in $rg." -BackgroundColor DarkGreen
        az network vnet create `
            --name $vnet_name `
            --address-prefixes $vnet_address `
            --subnets "[{'name':'$default_subnet','addressPrefix':'$default_subnet_address'},{'name':'$bastion_subnet','addressPrefix':'$bastion_subnet_address'}]" `
            --location $location1 `
            --tags Project=$project

        Write-Host "Deploying the $nic_name in $rg." -BackgroundColor DarkGreen
        az network nic create `
            --name $nic_name `
            --vnet-name $vnet_name `
            --subnet $default_subnet `
            --location $location1 `
            --tags Project=$project

        Write-Host "Deploying the $vm_name in $rg." -BackgroundColor DarkGreen
        az vm create `
            --name $vm_name `
            --resource-group $rg `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" `
            --admin-username azureuser `
            --admin-password "3000@UserAzure" `
            --nics $nic_name `
            --ppg $ppg_id `
            --location $location1 `
            --tags Project=$project `
            --no-wait
    }

printMyMessage -message "All virtual machines were deployed!."

printMyMessage -message "Starting peering the hub network with the spoke networks." -c 0
    $vnet1_id     = $(az network vnet show --name "vnet1" --resource-group $rg1 --query "id" --output tsv)
    $vnet2_id     = $(az network vnet show --name "vnet2" --resource-group $rg2 --query "id" --output tsv)
    $vnet3_id     = $(az network vnet show --name "vnet3" --resource-group $rg3 --query "id" --output tsv)
    $vnet4_id     = $(az network vnet show --name "vnet4" --resource-group $rg4 --query "id" --output tsv)

    Write-Host "Peering vnet3 (hub) with vnet1 (spoke)." -BackgroundColor DarkGreen
    az network vnet peering create `
        --name "vnet3-to-vnet1" `
        --resource-group $rg3 `
        --vnet-name "vnet3" `
        --remote-vnet $vnet1_id `
        --allow-vnet-access true

    az network vnet peering create `
        --name "vnet1-to-vnet3" `
        --resource-group $rg1 `
        --vnet-name "vnet1" `
        --remote-vnet $vnet3_id `
        --allow-vnet-access true

    Write-Host "Peering vnet3 (hub) with vnet2 (spoke)." -BackgroundColor DarkGreen
    az network vnet peering create `
        --name "vnet3-to-vnet2" `
        --resource-group $rg3 `
        --vnet-name "vnet3" `
        --remote-vnet $vnet2_id `
        --allow-vnet-access true

    az network vnet peering create `
        --name "vnet2-to-vnet3" `
        --resource-group $rg2 `
        --vnet-name "vnet2" `
        --remote-vnet $vnet3_id `
        --allow-vnet-access true

    Write-Host "Peering vnet3 (hub) with vnet4 (spoke)." -BackgroundColor DarkGreen
    az network vnet peering create `
        --name "vnet3-to-vnet4" `
        --resource-group $rg3 `
        --vnet-name "vnet3" `
        --remote-vnet $vnet4_id `
        --allow-vnet-access true

    az network vnet peering create `
        --name "vnet4-to-vnet3" `
        --resource-group $rg4 `
        --vnet-name "vnet4" `
        --remote-vnet $vnet3_id `
        --allow-vnet-access true

printMyMessage -message "All networks peered."

Write-Host "Setting the default resource group to $rg3 (hub resource group)." -BackgroundColor DarkGreen
az configure --defaults group=$rg3

printMyMessage -message "Deploying the Bastion instance in ($location1) location." -c 0

    Write-Host "Deploying the public ip address for the bastion." -BackgroundColor DarkGreen
    #JLopez-20250103: The public ip need to be in the same region where the bastion is going to be deployed.
    az network public-ip create `
        --name $public_ip `
        --location $location1 `
        --sku "Standard" `
        --allocation-method "Static" `
        --tags Project=$project

    az network bastion create `
        --name PrincipalBastion `
        --public-ip-address $public_ip `
        --vnet-name "vnet3" `
        --location $location1 `
        --tags Project=$project

printMyMessage -message "Bastion instance deployed!."
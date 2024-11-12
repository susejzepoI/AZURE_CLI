#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      November-05-2024
#Modified date:     November-11-2024

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
$project                = "IP2_3_" + $date
$location               = "West US"
$rg                     = "rg_" + $project 
$nsg                    = "nsg_" + $project
$vnet                   = "vnet_" + $project
$pub_dns                = "www.pubdns_$project.com"             
$priv_dns               = "www.privdns_$project.com"
$vnet1_range            = "10.1.0.0/16"
$subnet1_range          = "10.1.0.0/24"
$location1              = "West Europe"
$vnet2_range            = "10.2.0.0/16"
$subnet2_range          = "10.2.0.0/24"
$location2              = "UK South"
$vnet3_range            = "10.3.0.0/16"
$subnet3_range          = "10.3.0.0/24"
$location3              = "Mexico Central"
$vnet4_range            = "10.4.0.0/16"
$subnet4_range          = "10.4.0.0/24"
$location4              = "East US"


printMyMessage -message "Starting with the resource group validation." -c 0

checkMyResourceGroup -rg $rg -l $location -t Project=$project

Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
az configure --defaults group=$rg

printMyMessage -message "Resource group validation done!."

printMyMessage -message "Creating the Private DNS zone." -c 0

#JLopez-2024111: The private DNS zone is a global resource, It can be linked to virtual networks from multiple regions.
az network private-dns zone create `
    --name $priv_dns `
    --tags Project=$Project

printMyMessage -message "Private DNS zone deployed!." -c 0

printMyMessage -message "Starting with the resources deployment for each virtual network." -c 0

for ($i = 1; $i -le 4; $i++) {

    $vnet_name      = $vnet.Replace("vnet_","vnet" + $i + "_")
    $subnet_name    = $vnet.Replace("vnet_","subnet" + $i + "_")
    $nsg_name       = $nsg.Replace("nsg_","nsg" + $i + "_")
    $vm_name        = $vnet.Replace("vnet_","vm" + $i + "_")
    $pip_name       = $vnet.Replace("vnet_","pip" + $i + "_")
    $nic_name       = $vnet.Replace("vnet_","nic" + $i + "_")
    $dns_link_name  = $vnet.Replace("vnet_","dns_vnet_link_" + $i + "_")

    Write-Host "Creting resources for the virtual network: $vnet_name." -BackgroundColor DarkGreen

    switch ($i) {
        1   {   
                $vnet_address       = $vnet1_range 
                $subnet_adrress     = $subnet1_range 
                $resource_location  = $location1
            }
        2   {   
                $vnet_address       = $vnet2_range 
                $subnet_adrress     = $subnet2_range 
                $resource_location  = $location2
            }
        3   {   
                $vnet_address       = $vnet3_range 
                $subnet_adrress     = $subnet3_range 
                $resource_location  = $location3          

            }
        4   {   
                $vnet_address       = $vnet4_range 
                $subnet_adrress     = $subnet4_range
                $resource_location  = $location4
            }
        Default 
            {
                $vnet_address       = $vnet1_range 
                $subnet_adrress     = $subnet1_range 
                $resource_location  = $location1
            }
    }

    az network vnet create `
        --name $vnet_name `
        --address-prefixes $vnet_address `
        --subnet-name $subnet_name `
        --subnet-prefixes $subnet_adrress `
        --location $resource_location `
        --tags Project=$Project 

    $vnet_id = $(az network vnet show --name $vnet_name --query "id" --output tsv)

    Write-Host "Linking the vnet with the $priv_dns dns zone (auto-resolution enabled)." -BackgroundColor DarkGreen
    az network private-dns link vnet create `
        --zone-name $priv_dns `
        --name $dns_link_name `
        --virtual-network $vnet_id `
        --registration-enabled true

    Write-Host "Deploying the $vm_name virtual machine and its components." -BackgroundColor DarkGreen
    az network nsg create `
        --name $nsg_name `
        --location $resource_location `
        --tags Project=$Project

    az network nsg rule create `
        --nsg-name $nsg_name `
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

    az network public-ip create `
        --allocation-method "Static" `
        --location $resource_location `
        --name $pip_name

    az network nic create `
        --name  $nic_name `
        --vnet-name $vnet_name `
        --subnet $subnet_name `
        --network-security-group $nsg_name `
        --public-ip-address $pip_name `
        --location $resource_location

    az vm create `
        --name $vm_name `
        --location $resource_location `
        --admin-username azureuser `
        --admin-password "3000@UserAzure" `
        --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" `
        --tags Project=$project `
        --nics $nic_name `
        --no-wait 

    Write-Host "All resources were deployed for the virtual network: $vnet_name." -BackgroundColor DarkGreen
}

printMyMessage -message "All virtual networks were deployed!."
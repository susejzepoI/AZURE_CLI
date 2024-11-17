#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      November-05-2024
#Modified date:     November-16-2024

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
$project                = "IP2_2_" + $date
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
$location2              = "uksouth"
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


#JLopez: Checking if the private DNS already exists
az network private-dns zone show --name $priv_dns --output none 2>$null

if ($LASTEXITCODE -ne 0 ) {
    Write-Host "Creating the $priv_dns private dns zone." -BackgroundColor DarkGreen
    #JLopez-2024111: The private DNS zone is a global resource, It can be linked to virtual networks from multiple regions.
    az network private-dns zone create `
        --name $priv_dns `
        --tags Project=$Project
}else {
    Write-Host "The $priv_dns private DNS zone already exists, no further action is required." -BackgroundColor DarkYellow
}

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

    az network private-dns link vnet show --name $dns_link_name --zone-name $priv_dns --output none 2>$null

    if($LASTEXITCODE -ne 0){
        Write-Host "Linking the vnet with the $priv_dns dns zone (auto-resolution enabled)." -BackgroundColor DarkGreen
        az network private-dns link vnet create `
            --zone-name $priv_dns `
            --name $dns_link_name `
            --virtual-network $vnet_id `
            --registration-enabled true
    }else{
        Write-Host "The linked $dns_link_name already exists, no further action is required." -BackgroundColor DarkYellow
    }


    Write-Host "Deploying the $vm_name virtual machine and its components." -BackgroundColor DarkGreen
    az network nsg create `
        --name $nsg_name `
        --location $resource_location `
        --tags Project=$Project

    az network nsg rule create `
        --nsg-name $nsg_name `
        --name "Inbound-RDP"`
        --priority 110 `
        --source-address-prefixes "*" `
        --source-port-ranges "*" `
        --destination-address-prefixes "*" `
        --destination-port-ranges 3389 `
        --access "Allow" `
        --protocol "Tcp" `
        --direction "Inbound" `
        --description "Allow Inbound RDP connections on 3389 port (for testing only)."

    az network nsg rule create `
        --nsg-name $nsg_name `
        --name "Outbound-RDP"`
        --priority 110 `
        --source-address-prefixes "*" `
        --source-port-ranges "*" `
        --destination-address-prefixes "*" `
        --destination-port-ranges 3389 `
        --access "Allow" `
        --protocol "Tcp" `
        --direction "Outbound" `
        --description "Allow Outbound RDP connections on 3389 port (for testing only)."

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

printMyMessage -message "Adding 'A' records sets manually to each virtual machine." -c 0

az network private-dns record-set a show --name "vm1" --zone-name $priv_dns --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vm = $vnet.Replace("vnet_","vm1" + "_")
    $private_ip1 = $( az vm show --name $vm --show-details --query "privateIps" --output tsv)
    az network private-dns record-set  a add-record `
        --record-set-name "vm1" `
        --zone-name $priv_dns `
        --ipv4-address $private_ip1
}else {
    Write-Host "The A record set 'vm1' already exists, no further action is required." -BackgroundColor DarkYellow
}

az network private-dns record-set a show --name "vm2" --zone-name $priv_dns --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vm = $vnet.Replace("vnet_","vm2" + "_")
    $private_ip2 = $( az vm show --name $vm --show-details --query "privateIps" --output tsv)
    az network private-dns record-set  a add-record `
        --record-set-name "vm2" `
        --zone-name $priv_dns `
        --ipv4-address $private_ip2
}else {
    Write-Host "The A record set 'vm2' already exists, no further action is required." -BackgroundColor DarkYellow
}

az network private-dns record-set a show --name "vm3" --zone-name $priv_dns --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vm = $vnet.Replace("vnet_","vm3" + "_")
    $private_ip3 = $( az vm show --name $vm --show-details --query "privateIps" --output tsv)
    az network private-dns record-set a add-record `
        --record-set-name "vm3" `
        --zone-name $priv_dns `
        --ipv4-address $private_ip3
}else {
    Write-Host "The A record set 'vm3' already exists, no further action is required." -BackgroundColor DarkYellow
}

az network private-dns record-set a show --name "vm4" --zone-name $priv_dns --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vm = $vnet.Replace("vnet_","vm4" + "_")
    $private_ip4 = $( az vm show --name $vm --show-details --query "privateIps" --output tsv)
    az network private-dns record-set a add-record `
        --record-set-name "vm4" `
        --zone-name $priv_dns `
        --ipv4-address $private_ip4
}else {
    Write-Host "The A record set 'vm4' already exists, no further action is required." -BackgroundColor DarkYellow
}

printMyMessage -message "'A' records were added!."

printMyMessage -message "Adding a 'CNAME' record set manually for 'vm1' record set." -c 0

az network private-dns record-set cname show --name "principal" --zone-name $priv_dns --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vm1_FQDN = "vm1." + $priv_dns
    az network private-dns record-set cname set-record `
        --cname $vm1_FQDN `
        --record-set-name "principal" `
        --zone-name $priv_dns
}else {
    Write-Host "The CNAME record set 'principal' already exists, no further action is required." -BackgroundColor DarkYellow
}

printMyMessage -message "'CNAME' record was added!."

printMyMessage -message "Adding peering between virtual networks." -c 0

$vnet1_name   = $vnet.Replace("vnet_","vnet1_")

Write-Host "Peering between vnet 1 and vnet 2." -BackgroundColor DarkGreen

az network vnet peering show --vnet-name $vnet1_name --name "vnet1-to-vnet2" --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vnet1_id     = $(az network vnet show --name $vnet1_name --query "id" --output tsv)
    $vnet2_name   = $vnet.Replace("vnet_","vnet2_")
    $vnet2_id     = $(az network vnet show --name $vnet2_name --query "id" --output tsv)

    az network vnet peering create `
        --name "vnet1-to-vnet2" `
        --vnet-name $vnet1_name `
        --remote-vnet $vnet2_id `
        --allow-forwarded-traffic false `
        --allow-vnet-access true

    az network vnet peering create `
        --name "vnet2-to-vnet1" `
        --vnet-name $vnet2_name `
        --remote-vnet $vnet1_id `
        --allow-forwarded-traffic false `
        --allow-vnet-access true
}else {
    Write-Host "The peerings already exists between vnet1 and vnet 2, no further action is required." -BackgroundColor DarkYellow
}

Write-Host "Peering between vnet 1 and vnet 3." -BackgroundColor DarkGreen

az network vnet peering show --vnet-name $vnet1_name --name "vnet1-to-vnet3" --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vnet3_name   = $vnet.Replace("vnet_","vnet3_")
    $vnet3_id     = $(az network vnet show --name $vnet3_name --query "id" --output tsv)

    az network vnet peering create `
        --name "vnet1-to-vnet3" `
        --vnet-name $vnet1_name `
        --remote-vnet $vnet3_id `
        --allow-forwarded-traffic false `
        --allow-vnet-access true

    az network vnet peering create `
        --name "vnet3-to-vnet1" `
        --vnet-name $vnet3_name `
        --remote-vnet $vnet1_id `
        --allow-forwarded-traffic false `
        --allow-vnet-access true
}else {
    Write-Host "The peerings already exists between vnet 1 and vnet 3, no further action is required." -BackgroundColor DarkYellow
}

Write-Host "Peering between vnet 1 and vnet 4." -BackgroundColor DarkGreen

az network vnet peering show --vnet-name $vnet1_name --name "vnet1-to-vnet4" --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    $vnet4_name   = $vnet.Replace("vnet_","vnet4_")
    $vnet4_id     = $(az network vnet show --name $vnet4_name --query "id" --output tsv)

    az network vnet peering create `
        --name "vnet1-to-vnet4" `
        --vnet-name $vnet1_name `
        --remote-vnet $vnet4_id `
        --allow-forwarded-traffic false `
        --allow-vnet-access true

    az network vnet peering create `
        --name "vnet4-to-vnet1" `
        --vnet-name $vnet4_name `
        --remote-vnet $vnet1_id `
        --allow-forwarded-traffic false `
        --allow-vnet-access true
}else {
    Write-Host "The peerings already exists between vnet 1 and vnet 4, no further action is required." -BackgroundColor DarkYellow
}
printMyMessage -message "Peering deployed!." -c 0
printMyMessage -message "All resources were deployed!." -c 0
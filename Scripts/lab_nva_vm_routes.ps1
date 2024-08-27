#Interactive lab 
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-21-2024
#Modified date:     August-27-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/control-network-traffic-flow-with-routes/5-exercise-create-nva-vm

[CmdletBinding()]
param (
    [string]$rg = "az10420240824",
    [string]$l  = "West US",
    [string]$s  = "Suscripción de Plataformas de MSDN"
)

#JLopez: Internal variables
$route_table    = "publicTable"
$vnet           = "vnet"
$prodSubnet     = "productionsubnet"
$pubSubnet      = "publicsubnet"
$privSubnet     = "privSubnet"
$dmzSubnet      = "dmzSubnet"
$vm             = "nva"
$nic_id         = ""
$nic_name       = ""
$username       = "azureuseraz104"
$publ_vm        = "Public"
$priv_vm        = "Private"
$ssh_command    = "sudo sysctl -w net.ipv4.ip_forward=1; exit;"
$ssh_command2   = "[].virtualMachine.network.publicIpAddresses[*].ipAddress"
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

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "      Resource group validation done!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "         Creating the virtual network." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez: Creating the virtual network and the first subnet
az network vnet create `
    --name $vnet `
    --resource-group $rg `
    --address-prefix 10.0.0.0/16 `
    --subnet-name $pubSubnet `
    --subnet-prefixes 10.0.0.0/24 `
    --tags Project=az104Test

#JLopez: Creating the second subnet.
Write-Host "Creating the second subnet $privSubnet." -BackgroundColor DarkGreen
az network vnet subnet create `
    --name $privSubnet `
    --vnet-name $vnet `
    --resource-group $rg `
    --address-prefixes 10.0.1.0/24

#JLopez: Creating the second subnet.
Write-Host "Creating the third subnet $privSubnet." -BackgroundColor DarkGreen
az network vnet subnet create `
    --name $dmzSubnet `
    --vnet-name $vnet `
    --resource-group $rg `
    --address-prefixes 10.0.2.0/24

Write-Host "The following subnets networks were created."
az network vnet subnet list `
    --resource-group $rg `
    --vnet-name $vnet `
    --output table


Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "        Virtual network was deployed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "         Creating the route table." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez: Creating the route table
az network route-table create `
    --name $route_table `
    --resource-group $rg `
    --disable-bgp-route-propagation false

#JLopez: Creating the custom route
Write-Host "Creating the custom route." -BackgroundColor DarkGreen
az network route-table route create `
    --route-table-name $route_table `
    --resource-group $rg `
    --name $prodSubnet `
    --address-prefix 10.0.1.0/24 `
    --next-hop-type VirtualAppliance `
    --next-hop-ip-address 10.0.2.4

#JLopez: Updating the public subnet to add the route table.
Write-Host "Updating the public subnet to add the route table." -BackgroundColor DarkGreen
az network vnet subnet update `
    --name $pubSubnet `
    --vnet-name $vnet `
    --resource-group $rg `
    --route-table $route_table

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "            Route table deployed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
    
for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "       Creating the virtual appliance." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

az vm create `
    --resource-group $rg `
    --name $vm `
    --vnet-name $vnet `
    --subnet $dmzSubnet `
    --image Ubuntu2204 `
    --admin-username "azureuseraz104" `
    --tags Project=az104Test

#JLopez: Enabling IP forwarding for the VM.
Write-Host "Enabling IP forwarding for the VM." -BackgroundColor DarkGreen

#Jlopez: Looking for the nic id.
Write-Host "Looking the NIC Id." -BackgroundColor DarkGreen
$nic_id = $(az vm nic list --resource-group $rg --vm-name $vm --query "[].{id:id}" --output tsv)
if($nic_id -ne ""){

    #JLopez: Looking the nic name.
    Write-Host "Looking the nic name." -BackgroundColor DarkGreen
    $nic_name = $(az vm nic show --resource-group $rg --vm-name $vm --nic $nic_id --query "{name:name}" --output tsv)

    if($nic_name -ne ""){
        #JLopez: Update the NIC if was found
        write-Host "Enabling the NIC IP forwarding." -BackgroundColor DarkGreen
        az network nic update `
            --name $nic_name `
            --resource-group $rg `
            --ip-forwarding true

        $NVA_IP = $(az vm list-ip-addresses --resource-group $rg --name $vm --query "[].virtualMachine.network.publicIpAddresses[*].ipAddress" --output tsv)
    }
}

ssh -t -o StrictHostKeyChecking=no $username@$NVA_IP $ssh_command

Write-Host "IP forwarding enable on the IP: $NVA_IP" -BackgroundColor DarkGreen

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "       Virtual appliance deployed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

for ($i = 0; $i -lt 6; $i++) {
    Write-Host ""
}

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "      Creating the public and private vms." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen

#JLopez-27082024: Creating the Public virtual machine.
Write-Host "Creating the public virtual machine." -BackgroundColor DarkGreen
az vm create `
    --resource-group $rg `
    --name $publ_vm `
    --vnet-name $vnet `
    --subnet $pubSubnet `
    --image Ubuntu2204 `
    --admin-username $username `
    --no-wait `
    --custom-data .\utilities\cloud-init1.txt `
    --tags Project=az104Test

#JLopez-27082024: Creating the Private virtual machine.
Write-Host "Creating the private virtual machine." -BackgroundColor DarkGreen
az vm create `
    --resource-group $rg `
    --name $priv_vm `
    --vnet-name $vnet `
    --subnet $privSubnet `
    --image Ubuntu2204 `
    --admin-username $username `
    --custom-data .\utilities\cloud-init1.txt `
    --tags Project=az104Test

$PUBLIC_IP = $(az vm list-ip-addresses --resource-group $rg --name $publ_vm --query $ssh_command2 --output tsv)

$PRIVATE_IP = $(az vm list-ip-addresses --resource-group $rg --name $priv_vm --query $ssh_command2 --output tsv)

Write-Host "Public virtual machine IP Address: $PUBLIC_IP." -BackgroundColor DarkGreen
Write-Host "Private virtual machine IP Address: $PRIVATE_IP." -BackgroundColor DarkGreen

#JLopez-27082024: Trace route from public to private virtual machine.
Write-Host "Trace route from public to private virtual machine." -BackgroundColor DarkGreen
ssh -t -o StrictHostKeyChecking=no $username@$PUBLIC_IP 'traceroute private --type=icmp; exit'

#JLopez-27082024: Trace route from private to public virtual machine.
Write-Host "Trace route from private to public virtual machine." -BackgroundColor DarkGreen
ssh -t -o StrictHostKeyChecking=no $username@$PRIVATE_IP 'traceroute public --type=icmp; exit'

Write-Host "_____________________________________________" -BackgroundColor DarkGreen
Write-Host "       Virtual Machines deployed!." -BackgroundColor DarkGreen
Write-Host "_____________________________________________" -BackgroundColor DarkGreen
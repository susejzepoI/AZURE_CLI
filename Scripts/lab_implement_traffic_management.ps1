#Interactive lab 03
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      June-03-2024
#Modified date:     July-09-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/9-simulation-load-balancer



[CmdletBinding()]
param(
    #JLopez: Location to deploy resources in the subscription.
    [Parameter(Mandatory=$true, HelpMessage="Location to deploy resources in the subscription.")]
    [string]$Location,

    #JLopez: Resource group names to deploy the resources in the current azure subscription.
    [Parameter(Mandatory=$true, HelpMessage="Name of the first resource group (this rg contains 4 virtual machines and 3 vnets + peering) to deploy.")]
    [string]$resourcegroup1name,

    #JLopez: Virtuals nework names
    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 1 name (this vnet contains the first 2 virtual machines).")]
    [string]$vnet1Name,

    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 2 name (this vnet contains the third virtual machine + peering to the vnet 1).")]
    [string]$vnet2Name,

    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 2 name (this vnet contains the fourth virtual machine + peering to the vnet 1).")]
    [string]$vnet3Name,

    [Parameter(Mandatory=$true, HelpMessage="Virtual nework 2 name (this vnet contains the fourth virtual machine + peering to the vnet 1).")]
    [string]$vmUserName

)

#JLopez: Print entered variables
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "********************************************"
Write-Host "   #Author:            Jesus Lopez Mesia"
Write-Host "   #Modified date:     July-09-2024"
Write-Host "********************************************"
Write-Host ""


Write-Host "Location: $Location"
Write-Host "Resource groups: $resourcegroup1name."
Write-Host "Vnets Names: $vnet1Name, $vnet2Name, $vnet3Name."

Write-Host "Starting to create the 3 resource groups in the same region ($Location)."

az group create --location $Location `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03

Write-Host "Creating the 3 virtual networks in the same region ($Location)."

az network vnet create --name $vnet1Name `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03 `
    --location $Location `
    --address-prefixes 10.60.0.0/22 `
    --subnets '[{"name":"subnet0","addressPrefix":"10.60.0.0/24"},{"name":"subnet1","addressPrefix":"10.60.1.0/24"},{"name":"subnet-appgw","addressPrefix":"10.60.3.224/27"}]'

az network vnet create --name $vnet2Name `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03 `
    --location $Location `
    --address-prefixes 10.62.0.0/22 `
    --subnet-name "Subnet0" `
    --subnet-prefixes 10.62.0.0/24

az network vnet create --name $vnet3Name `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03 `
    --location $Location `
    --address-prefixes 10.63.0.0/22 `
    --subnet-name "Subnet0" `
    --subnet-prefixes 10.63.0.0/24

Write-Host "Creating the virtual machines in each vnet."

Write-Host "Enter the password for the user $vmUserName."

    try {
        $pass = Read-Host "Enter your password " -MaskInput

        Write-Host "Creating the NSG for 'az104-06-vm0' and 'az104-06-vm1' virtual machines."

        az network nsg create --name "myNSG" --resource-group $resourcegroup1name

        az network nsg rule create `
            --resource-group $resourcegroup1name `
            --nsg-name "myNSG" `
            --name "default-allow-rdp" `
            --priority 1000 `
            --source-port-range "*" `
            --source-address-prefixes "*" `
            --destination-address-prefixes "*" `
            --destination-port-ranges "3389" `
            --access "Allow" `
            --protocol "Tcp" `
            --direction "Inbound" `
            --description "JLopez: Allow RDP traffic."

            az network nsg rule create `
            --resource-group $resourcegroup1name `
            --nsg-name "myNSG" `
            --name "default-allow-http" `
            --priority 1100 `
            --source-port-range "*" `
            --source-address-prefixes "*" `
            --destination-address-prefixes "*" `
            --destination-port-ranges "80" `
            --access "Allow" `
            --protocol "Tcp" `
            --direction "Inbound" `
            --description "JLopez: Allow RDP traffic."

        Write-Host "Creating the virtual machines for $vnet1Name vnet."

        az vm create --name "az104-06-vm0" `
            --resource-group $resourcegroup1name `
            --vnet-name $vnet1Name `
            --subnet "subnet0" `
            --nsg "myNSG" `
            --tags project=az104lab03 `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"
        
        az vm create --name "az104-06-vm1" `
            --resource-group $resourcegroup1name `
            --vnet-name $vnet1Name `
            --subnet "subnet1" `
            --nsg "myNSG" `
            --tags project=az104lab03 `
            --admin-username $vmUserName `
            --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

        Write-Host "Creating the virtual machine for $vnet2Name vnet."

        az vm create --name "az104-06-vm2" --resource-group $resourcegroup1name `
            --vnet-name $vnet2Name --subnet "subnet0" --tags project=az104lab03 `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

        Write-Host "Creating the virtual machine for $vnet3Name vnet."

        az vm create --name "az104-06-vm3" --resource-group $resourcegroup1name `
            --vnet-name $vnet3Name --subnet "subnet0" --tags project=az104lab03 `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

        Write-Host "Creating the network watcher for each virtual machine."

        $vms = az vm list --resource-group $resourcegroup1name --query "[].name" -o tsv

        #JLopez-20240706: To see the full version table for an specific publisher you can use: az vm extension image list-versions --location "West US" --publisher "Microsoft.Azure.NetworkWatcher" --name "NetworkWatcherAgentWindows" --output table
        foreach($vm in $vms){
            Write-Host "Setting extension for VM: $vm."
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name $vm `
                --name "NetworkWatcherAgentWindows" `
                --publisher "Microsoft.Azure.NetworkWatcher" 
        }

        Write-Host "Configuring peerings from $vnet1Name to $vnet2Name."
        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet1Name-to-$vnet2Name" `
            --vnet-name $vnet1Name `
            --remote-vnet $vnet2Name `
            --allow-forwarded-traffic true `
            --allow-vnet-access true

        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet2Name-to-$vnet1Name" `
            --vnet-name $vnet2Name `
            --remote-vnet $vnet1Name `
            --allow-forwarded-traffic true `
            --allow-vnet-access true
            

        Write-Host "Configuring peerings from $vnet1Name to $vnet3Name."
        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet1Name-to-$vnet3Name" `
            --vnet-name $vnet1Name `
            --remote-vnet $vnet3Name `
            --allow-forwarded-traffic true `
            --allow-vnet-access true

        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet3Name-to-$vnet1Name" `
            --vnet-name $vnet3Name `
            --remote-vnet $vnet1Name `
            --allow-forwarded-traffic true `
            --allow-vnet-access true

        Write-Host "Configuring ip forwarding for the 'az104-06-vm0' virtual machine."


        Write-Host "Checking if the virtual machine 'az104-06-vm0' was created."

        $checkVM0 = $(az vm show --resource-group $resourcegroup1name --name "az104-06-vm0" --query "name" --output tsv)

        if ($checkVM0) {
            $vm0NicID = $(az vm show --resource-group $resourcegroup1name --name "az104-06-vm0" --query "networkProfile.networkInterfaces[].id" -o tsv)
            az network nic update --ids $vm0NicID --ip-forwarding true
    
            Write-Host "Configuring settings for the the 'az104-06-vm0' virtual machine."
    
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm0" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command Install-WindowsFeature RemoteAccess -IncludeManagementTools\"}'
    
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm0" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command Install-WindowsFeature -Name Routing -IncludeManagementTools -IncludeAllSubFeature\"}'
    
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm0" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command Install-WindowsFeature -Name RSAT-RemoteAccess-PowerShell\"}'
    
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm0" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command Install-RemoteAccess -Vpntype RoutingOnly\"}'
    
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm0" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command Set-NetIPInterface -InterfaceAlias "Ethernet" -Forwarding Enabled\"}'
            
            Write-Host "Creating the UDR 'az104-06-r23' over the '$vnet2Name'."

            az network route-table create --name "az104-06-r23" --resource-group $resourcegroup1name --location $Location --disable-bgp-route-propagation true

            az network route-table route create `
                --route-table-name "az104-06-r23" `
                --resource-group $resourcegroup1name `
                --name "az104-06-route-vnet2-to-vnet3" `
                --address-prefix 10.63.0.0/20 `
                --next-hop-type "VirtualAppliance" `
                --next-hop-ip-address 10.60.0.4

            az network vnet subnet update --vnet-name $vnet2Name --name "subnet0" --resource-group $resourcegroup1name --route-table "az104-06-r23"

            Write-Host "Creating the UDR 'az104-06-r32' over the '$vnet3Name'."

            az network route-table create --name "az104-06-r32" --resource-group $resourcegroup1name --location $Location --disable-bgp-route-propagation true

            az network route-table route create `
                --route-table-name "az104-06-r32" `
                --resource-group $resourcegroup1name `
                --name "az104-06-route-vnet3-to-vnet2" `
                --address-prefix 10.62.0.0/20 `
                --next-hop-type "VirtualAppliance" `
                --next-hop-ip-address 10.60.0.4

            az network vnet subnet update --vnet-name $vnet3Name --name "subnet0" --resource-group $resourcegroup1name --route-table "az104-06-r32"

            Write-host "Creating a load balancer"

            az network public-ip create `
                --resource-group $resourcegroup1name `
                --name "az104-06-pip4" `
                --tags project=az104lab03 `
                --allocation-method Static `
                --sku Standard `
                --tier Regional `
                --location $Location

            az network lb create --name "az104-06-lb4" `
                --resource-group $resourcegroup1name `
                --tags project=az104lab03 `
                --location $Location

            az network lb frontend-ip create `
                --name "az104-06-fip4" `
                --resource-group $resourcegroup1name `
                --lb-name "az104-06-lb4" `
                --public-ip-address "az104-06-pip4"

            az network lb address-pool create `
                --address-pool-name "az104-06-lb4-be1" `
                --lb-name "az104-06-lb4" `
                --resource-group $resourcegroup1name `
                --vnet $vnet1Name `
                --backend-addresses "[{name:addr1,ip-address:10.60.0.4,subnet:subnet0},{name:addr2,ip-address:10.60.1.4,subnet:subnet1}]"

            az network lb probe create `
                --lb-name "az104-06-lb4" `
                --name "az104-06-lb4-hp1" `
                --resource-group $resourcegroup1name `
                --protocol "TCP" `
                --port 80 `
                --interval 5 `
                --number-of-probes 2

            az network lb rule create `
                --lb-name "az104-06-lb4" `
                --name "az104-06-lb4-lbrule1" `
                --resource-group $resourcegroup1name `
                --protocol "TCP" `
                --backend-pool-name "az104-06-lb4-be1" `
                --frontend-port 80 `
                --backend-port 80 `
                --probe "az104-06-lb4-hp1" `
                --frontend-ip "az104-06-fip4"
            
            Write-Host "Preparing index file for 'az104-06-vm0' and 'az104-06-vm1'."
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm0" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command New-Item -Path C:\\inetpub\\wwwroot\\ -ItemType Directory; Add-Content -Path C:\\inetpub\\wwwroot\\iisstart.htm -Value ''Hello World from az104-06-vm0''\"}'
       

                az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name "az104-06-vm1" `
                --name CustomScriptExtension `
                --publisher Microsoft.Compute `
                --version 1.9 `
                --settings '{\"commandToExecute\": \"powershell -ExecutionPolicy Unrestricted -Command New-Item -Path C:\\inetpub\\wwwroot\\ -ItemType Directory; Add-Content -Path C:\\inetpub\\wwwroot\\iisstart.htm -Value ''Hello World from az104-06-vm1''\"}'
        
        } else {
            Write-Error "The virtual machine 'az104-06-vm0' wasn't created."
        }

    }catch{
        Write-Error "An error was caught: $_"
    }
    finally {
        #JLopez-18062024: Clean up the password variable.
        $pass = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }

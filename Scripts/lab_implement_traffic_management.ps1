#Interactive lab 03
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      June-03-2024
#Modified date:     July-03-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/9-simulation-load-balancer



[CmdletBinding()]
param(
    #JLopez: Location to deploy resources in the subscription.
    [Parameter(Mandatory=$true, HelpMessage="Location to deploy resources in the subscription.")]
    [string]$Location,

    #JLopez: Resource group names to deploy the resources in the current azure subscription.
    [Parameter(Mandatory=$true, HelpMessage="Name of the first resource group (this rg contains 4 virtual machines and 3 vnets + peering) to deploy.")]
    [string]$resourcegroup1name,

    # [Parameter(Mandatory=$true, HelpMessage="Name of the second resource group (this rg contains the first gateway with a public IP) to deploy.")]
    # [string]$resourcegroup2name,

    # [Parameter(Mandatory=$true, HelpMessage="Name of the third resource group (this rg contains the second gateway with a public IP) to deploy.")]
    # [string]$resourcegroup3name,

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
Write-Host "   #Modified date:     July-03-2024"
Write-Host "********************************************"
Write-Host ""


Write-Host "Location: $Location"
Write-Host "Resource groups: $resourcegroup1name."
Write-Host "Vnets Names: $vnet1Name, $vnet2Name, $vnet3Name."

Write-Host "Starting to create the 3 resource groups in the same region ($Location)."

az group create --location $Location `
    --resource-group $resourcegroup1name `
    --tags project=az104lab03

# az group create --location $Location `
#     --resource-group $resourcegroup2name `
#     --tags project=az104lab03

# az group create --location $Location `
#     --resource-group $resourcegroup3name `
#     --tags project=az104lab03

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
        $pass = Read-Host "Enter your password: " -MaskInput

        Write-Host "Creating the virtual machines for $vnet1Name vnet."

        az vm create --name "az104-06-vm0" --resource-group $resourcegroup1name `
            --vnet-name $vnet1Name --subnet "subnet0" `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"
        
        az vm create --name "az104-06-vm1" --resource-group $resourcegroup1name `
            --vnet-name $vnet1Name --subnet "subnet1" `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

        Write-Host "Creating the virtual machine for $vnet2Name vnet."

        az vm create --name "az104-06-vm2" --resource-group $resourcegroup1name `
            --vnet-name $vnet2Name --subnet "subnet0" `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

        Write-Host "Creating the virtual machine for $vnet3Name vnet."

        az vm create --name "az104-06-vm3" --resource-group $resourcegroup1name `
            --vnet-name $vnet3Name --subnet "subnet0" `
            --admin-username $vmUserName --admin-password $pass `
            --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"

        Write-Host "Creating the network watcher for each virtual machine."

        $vms = az vm list --resource-group $resourcegroup1name --query "[].name" -o tsv

        foreach($vm in $vms){
            
            Write-Host "Setting extension for VM: $vm."
            az vm extension set `
                --resource-group $resourcegroup1name `
                --vm-name $vm `
                --name "NetworkWatcherAgentWindows" `
                --publisher "Microsoft.Azure.NetworkWatcher" `
                --version 1.9
        }

        Write-Host "Configuring peerings from $vnet1Name to $vnet2Name."
        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet1Name-to-$vnet2Name" `
            --vnet-name $vnet1Name `
            --remote-vnet $vnet2Name `
            --allow-forwarded-traffic false `
            --allow-vnet-access true

        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet2Name-to-$vnet1Name" `
            --vnet-name $vnet2Name `
            --remote-vnet $vnet1Name `
            --allow-forwarded-traffic false `
            --allow-vnet-access true
            

        Write-Host "Configuring peerings from $vnet1Name to $vnet3Name."
        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet1Name-to-$vnet3Name" `
            --vnet-name $vnet1Name `
            --remote-vnet $vnet3Name `
            --allow-forwarded-traffic false `
            --allow-vnet-access true

        az network vnet peering create `
            --resource-group $resourcegroup1name `
            --name "$vnet3Name-to-$vnet1Name" `
            --vnet-name $vnet3Name `
            --remote-vnet $vnet1Name `
            --allow-forwarded-traffic false `
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
        }else {
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

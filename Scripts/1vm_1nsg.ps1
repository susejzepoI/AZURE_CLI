#Task
# 1. Create a virtual machine
    # a. Connect to Azure
    az login
    # b. Check the context
    az account show
    # c. Create new resource group
    az group create --resource-group "MyRGSecure-20240407" --location westus
    # d. Create a virtual network and subnets
    az network vnet create --address-prefixes 10.1.0.0/16 --name "myRGSecure-507268-vnet" --resource-group "MyRGSecure-20240407" --subnet-name default --subnet-prefixes 10.1.0.0/24
    # e. Create a new virtual machine
    az vm create --name "SimpleWinVM" --resource-group "MyRGSecure-20240407" --admin-username azureuser --admin-password "3000@UserAzure" --vnet-name "myRGSecure-507268-vnet" --subnet "default" --nsg '""' --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest"
# 2. Create a network security group
    #a. Create a new nsg
    az network nsg create --name "myNSGSecure" --resource-group "MyRGSecure-20240407"
    #b. associate network interface
        #a. Fin the NSG ID
        $nsgID = (az network nsg show --name myNSGSecure --resource-group "MyRGSecure-20240407" --query id --output tsv)
        #b. Update the NIC of the VM
        az network nic update --name SimpleWinVMVMNic --resource-group "MyRGSecure-20240407" --network-security-group $nsgId
# 3. Configure an inbound security port rule to allow RDP
az network nsg rule create -g "MyRGSecure-20240407" --nsg-name "myNSGSecure" -n "AllowRDP" --priority 300 --source-port-ranges * --source-address-prefixes * --destination-port-ranges 3389 --destination-address-prefixes * --access allow --protocol Tcp --description "JLopez: Allow RDP traffic."
# 4. Configure an outbound security port rule to deny internet access
az network nsg rule create -g "MyRGSecure-20240407" --nsg-name "myNSGSecure" -n "BlockInternet" --priority 4000 --direction Outbound --access deny --protocol * --source-address-prefix * --source-port-range * --destination-address-prefix 'Internet' --destination-port-range * --description "JLopez: Deny internet traffic from vm."
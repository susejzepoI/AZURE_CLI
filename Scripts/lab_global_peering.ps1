#Interactive lab
#Author:    Jesus Lopez Mesia
#Linkedin:  https://www.linkedin.com/in/susejzepol/
#Date:      May-02-2024
#Lab:       https://learn.microsoft.com/en-us/training/modules/configure-vnet-peering/6-simulation-peering

# 1) Create two resources groups in the same region (Region A).
az group create --location "Canada Central" --resource-group "rg1-canda-central"
az group create --location "Canada Central" --resource-group "rg2-canda-central"

# 2) Create one resource group in another region (Region B).
az group create --location "West US 2" --resource-group "rg3-West-US-2"

# 3) Create one virtual network with its corresponding subnet for each resource group.
az network vnet create --name "vnet0-canada-central" --resource-group "rg1-canda-central" --address-prefixes 10.50.0.0/22 --subnet-name "Subnet0" --subnet-prefixes 10.50.0.0/24
az network vnet create --name "vnet1-canada-central" --resource-group "rg2-canda-central" --address-prefixes 10.51.0.0/22 --subnet-name "Subnet0" --subnet-prefixes 10.51.0.0/24
az network vnet create --name "vnet3-west-US-2" --resource-group "rg3-West-US-2" --address-prefixes 10.52.0.0/22 --subnet-name "Subnet0" --subnet-prefixes 10.52.0.0/24

# 4) Create the virtual machines for all vnets
az vm create --name vm0 --resource-group "rg1-canda-central" --vnet-name "vnet0-canada-central" --subnet "Subnet0" --admin-username userazure3000 --admin-password "******"
az vm create --name vm1 --resource-group "rg2-canda-central" --vnet-name "vnet1-canada-central" --subnet "Subnet0" --admin-username userazure3000 --admin-password ""******""
az vm create --name vm3 --resource-group "rg3-West-US-2" --vnet-name "vnet3-west-US-2" --subnet "Subnet0" --admin-username userazure3000 --admin-password ""******""

# 5) Create the peering between the vnet0 to vnet1 (The specification said that this command need to be excecuted twice but in reverse to peering networks).
az network vnet peering create --resource-group "rg1-canda-central" --name "vnet0-to-vnet1" --vnet-name "vnet0-canada-central" --remote-vnet "/subscriptions/24c299fa-aec1-489b-8cf2-671209727540/resourceGroups/rg2-canda-central/providers/Microsoft.Network/virtualNetworks/vnet1-canada-central" --allow-forwarded-traffic false --allow-vnet-access true
az network vnet peering create --resource-group "rg2-canda-central" --name "vnet1-to-vnet0" --vnet-name "vnet1-canada-central" --remote-vnet "/subscriptions/24c299fa-aec1-489b-8cf2-671209727540/resourceGroups/rg1-canda-central/providers/Microsoft.Network/virtualNetworks/vnet0-canada-central" --allow-forwarded-traffic false --allow-vnet-access true

# 6) Create the peering between the vnet0 to the vnet2
az network vnet peering create --resource-group "rg1-canda-central" --name "vnet0-to-vnet2" --vnet-name "vnet0-canada-central" --remote-vnet "/subscriptions/24c299fa-aec1-489b-8cf2-671209727540/resourceGroups/rg3-West-US-2/providers/Microsoft.Network/virtualNetworks/vnet3-west-US-2" --allow-forwarded-traffic false --allow-vnet-access true
az network vnet peering create --resource-group "rg3-West-US-2" --name "vnet2-to-vnet0" --vnet-name "vnet3-west-US-2" --remote-vnet "/subscriptions/24c299fa-aec1-489b-8cf2-671209727540/resourceGroups/rg1-canda-central/providers/Microsoft.Network/virtualNetworks/vnet0-canada-central" --allow-forwarded-traffic false --allow-vnet-access true

# 7) Create the peering between the vnet1 to the vnet2
az network vnet peering create --resource-group "rg2-canda-central" --name "vnet1-to-vnet2" --vnet-name "vnet1-canada-central" --remote-vnet "/subscriptions/24c299fa-aec1-489b-8cf2-671209727540/resourceGroups/rg3-West-US-2/providers/Microsoft.Network/virtualNetworks/vnet3-west-US-2" --allow-forwarded-traffic false --allow-vnet-access true
az network vnet peering create --resource-group "rg3-West-US-2" --name "vnet2-to-vnet1" --vnet-name "vnet3-west-US-2" --remote-vnet "/subscriptions/24c299fa-aec1-489b-8cf2-671209727540/resourceGroups/rg2-canda-central/providers/Microsoft.Network/virtualNetworks/vnet1-canada-central" --allow-forwarded-traffic false --allow-vnet-access true
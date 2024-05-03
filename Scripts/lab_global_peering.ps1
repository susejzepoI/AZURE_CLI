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
az vm create --name vm0 --resource-group "rg1-canda-central" --vnet-name "vnet0-canada-central" --subnet "Subnet0" --admin-username userazure3000 --admin-password "3000@UserAzure"
az vm create --name vm1 --resource-group "rg2-canda-central" --vnet-name "vnet1-canada-central" --subnet "Subnet0" --admin-username userazure3000 --admin-password "3000@UserAzure"
az vm create --name vm3 --resource-group "rg3-West-US-2" --vnet-name "vnet3-west-US-2" --subnet "Subnet0" --admin-username userazure3000 --admin-password "3000@UserAzure"
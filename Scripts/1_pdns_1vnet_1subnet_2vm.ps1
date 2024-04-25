
#Create a new resource group
az group create --location "East US" --resource-group contosoRG
az configure --defaults group=contosoRG

#Create a new virtual network and subnet
az network vnet create --address-prefixes 10.20.0.0/16 --name CoreServiceVnet --resource-group contosoRG --subnet-name DatabaseSubnet --subnet-prefixes 10.20.20.0/24 --subscription "24c299fa-aec1-489b-8cf2-671209727540"

#Create a new Private DNS zone
az network private-dns zone create --name "contosodns.com" --resource-group contosoRG --subscription "24c299fa-aec1-489b-8cf2-671209727540"

#Create a link between the Private DNS zone and the Vnet
az network private-dns link vnet create --name coreservicesvnetlink --registration-enabled true --resource-group contosoRG --virtual-network CoreServiceVnet --zone-name "contosodns.com"
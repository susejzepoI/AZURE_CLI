#JLopez-20240331
#This script is responsible for create two virtual machines, a virtual network and a subnet.
#It also, set the communitacion between they using `ADP`.
#az login
#az account set --subscription 24c299fa-aec1-489b-8cf2-671209727540
az group create --location "East US" --resource-group az104virtualnetworkdemo
az configure --defaults group=az104virtualnetworkdemo
#Create a new virtual network
az network vnet create --address-prefixes 10.1.0.0/16 --name az104vn01 --resource-group az104virtualnetworkdemo --subnet-name default --subnet-prefixes 10.1.0.0/24
#Create two new virtual machines
az vm create --name vm --resource-group az104virtualnetworkdemo --image "MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest" --vnet-name "az104vn01" --subnet "default" --admin-username userazure3000 --admin-password "3000@UserAzure" --count 2
#Deallocate them
az vm deallocate --name vm0
az vm deallocate --name vm1
#Remove the resource group
az group delete --resource-group az104virtualnetworkdemo
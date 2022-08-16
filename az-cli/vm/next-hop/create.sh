##!/usr/bin/env bash
set -e
. ./params.sh


## Create RG
echo "Create RG"
az group create \
  --name $VM_VNET_RG \
  --location $VM_VNET_LOCATION \
  --debug


## Create VNet and Subnet
echo "Create Vnet for Jump Server"
az network vnet create \
  --resource-group $VM_VNET_RG \
  --name $VM_VNET_NAME \
  --address-prefix $VM_VNET_CIDR \
  --debug


## Create AKS Subnet
echo "Create Subnet for AKS Cluster"
az network vnet subnet create \
  --resource-group $VM_VNET_RG \
  --vnet-name $VM_VNET_NAME \
  --name $AKS_SNET_NAME \
  --address-prefixes $AKS_SNET_CIDR \
  --debug


## VM Server Creation
echo "Create VM Server Subnet"
az network vnet subnet create \
  --resource-group $VM_VNET_RG \
  --vnet-name $VM_VNET_NAME \
  --name $VM_SNET_NAME \
  --address-prefixes $VM_SNET_CIDR \
  --debug


## VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $VM_VNET_RG \
  --vnet-name $VM_VNET_NAME \
  --subnet $VM_SNET_NAME \
  --name $VM_NIC_NAME \
  --debug 


## VM Nic 2 Create
echo "Create VM Nic 2"
az network nic create \
  --resource-group $VM_VNET_RG \
  --vnet-name $VM_VNET_NAME \
  --subnet $AKS_SNET_NAME \
  --name $VM_NIC_NAME_2 \
  --ip-forwarding true \
  --debug


## Create VM
echo "Create VM"
az vm create \
  --resource-group $VM_VNET_RG \
  --authentication-type $VM_AUTH_TYPE \
  --name $VM_NAME \
  --computer-name $VM_INTERNAL_NAME \
  --image $VM_IMAGE \
  --size $VM_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $VM_STORAGE_SKU \
  --os-disk-size-gb $VM_OS_DISK_SIZE \
  --os-disk-name $VM_OS_DISK_NAME \
  --nics $VM_NIC_NAME $VM_NIC_NAME_2 \
  --tags $VM_TAGS \
  --debug


## Create Route Table
echo "Create Route Table"
az network route-table create \
  --name $VNET_ROUTE_TABLE_NAME \
  --resource-group $VM_VNET_RG \
  --location $VM_VNET_LOCATION \
  --debug


## Create Route
echo "Create Route"
az network route-table route create \
  --name $VNET_ROUTE_TABLE_ROUTE_NAME \
  --next-hop-type VirtualAppliance \
  --address-prefix "0.0.0.0/0" \
  --route-table-name $VNET_ROUTE_TABLE_NAME \
  --next-hop-ip-address $VNET_NVA_IP \
  --resource-group $VM_VNET_RG \
  --debug


## Create Route Association
echo "Create Route Association"
az network vnet subnet update \
  --vnet-name $VM_VNET_NAME \
  --route-table $VNET_ROUTE_TABLE_NAME \
  --name $AKS_SNET_NAME \
  --resource-group $VM_VNET_RG \
  --debug



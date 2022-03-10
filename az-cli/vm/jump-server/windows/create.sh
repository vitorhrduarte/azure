##!/usr/bin/env bash
set -e
. ./params.sh

funcRgExists () {
  RG_EXISTS=$(az group list \
    --output json | jq  -r ".[] | select ( .name == \"$JS_MAIN_VNET_RG\" ) | [ .name ] | @tsv" | wc -l)
}


funcVnetExists () {
  VNET_EXISTS=$(az network vnet list \
    --output json | jq -r ".[] | select ( .name == \"$JS_MAIN_VNET_RG\" ) | [ .name ] | @tsv" | wc -l)
}


## Check if RG exists
echo "Checking if RG exists"
funcRgExists

## Check if Vnet Exists
echo "Check if Vnet Exists"
funcVnetExists


## If RG does not exist...
if [[ "$RG_EXISTS" == "0" ]]
then
  echo "RG does not exit... need to create"

  ## Create RG (if not present)
  echo "Create RG"
  az group create \
    --name $JS_MAIN_VNET_RG \
    --location $JS_MAIN_VNET_LOCATION \
    --debug
fi

## If Vnet does not exist....
if [[ "$VNET_EXISTS" == "0" ]]
then
  echo "Vner does not exit.... need to create"  

  ## Create VNet and Subnet (if not present)
  echo "Create Vnet for Jump Server"
  az network vnet create \
    --resource-group $JS_MAIN_VNET_RG \
    --name $JS_MAIN_VNET_NAME \
    --address-prefix $JS_MAIN_VNET_CIDR \
    --debug
fi

## Windows VM RDP Client subnet Creation
echo "Create VM RDP Subnet"
az network vnet subnet create \
  --resource-group $JS_MAIN_VNET_RG \
  --vnet-name $JS_MAIN_VNET_NAME \
  --name $JS_SUBNET_NAME \
  --address-prefixes $JS_SUBNET_CIDR \
  --debug


## Windows VM RDP NSG Create
echo "Create Windows RDP NSG"
az network nsg create \
  --resource-group $JS_MAIN_VNET_RG \
  --name $JS_NSG_NAME \
  --debug


## Windows Public IP Create
echo "Create Windows Public IP"
az network public-ip create \
  --name $JS_PUBLIC_IP_NAME \
  --resource-group $JS_MAIN_VNET_RG \
  --debug

## Windows VM Nic Create
echo "Create Windows VM Nic"
az network nic create \
  --resource-group $JS_MAIN_VNET_RG \
  --vnet-name $JS_MAIN_VNET_NAME \
  --subnet $JS_SUBNET_NAME \
  --name $JS_NIC_NAME \
  --network-security-group $JS_NSG_NAME \
  --debug

## Windows Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $JS_DEFAULT_IP_CONFIG \
  --nic-name $JS_NIC_NAME \
  --resource-group $JS_MAIN_VNET_RG \
  --public-ip-address $JS_PUBLIC_IP_NAME \
  --debug


## Windows Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $JS_MAIN_VNET_RG \
  --name $JS_SUBNET_NAME \
  --vnet-name $JS_MAIN_VNET_NAME \
  --network-security-group $JS_NSG_NAME \
  --debug


## Windows Create VM
echo "Create Windows VM"
az vm create \
  --resource-group $JS_MAIN_VNET_RG \
  --name $JS_NAME \
  --image $JS_IMAGE  \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --nics $JS_NIC_NAME \
  --tags $JS_TAGS \
  --computer-name $JS_INTERNAL_NAME \
  --authentication-type $JS_AUTH_TYPE \
  --size $JS_SIZE \
  --storage-sku $JS_STORAGE_SKU \
  --os-disk-size-gb $JS_OS_DISK_SIZE \
  --os-disk-name $JS_OS_DISK_NAME \
  --nsg-rule NONE \
  --debug




##!/usr/bin/env bash
set -e
. ./params.sh


## Create RG
echo "Create RG"
az group create \
  --name $VM_VNET_RG \
  --location $VM_VNET_LOCATION \
  --debug


## VM Server Creation
echo "Create VM Server Subnet"
az network vnet subnet create \
  --resource-group $VM_VNET_RG \
  --vnet-name $VM_VNET_NAME \
  --name $VM_SNET_NAME \
  --address-prefixes $VM_SNET_CIDR \
  --debug


## VM NSG Create
echo "Create NSG"
az network nsg create \
  --resource-group $VM_VNET_RG \
  --name $VM_NSG_NAME \
  --debug


## Public IP Create
echo "Create Public IP"
az network public-ip create \
  --name $VM_PUBLIC_IP_NAME \
  --resource-group $VM_VNET_RG \
  --debug


## VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $VM_VNET_RG \
  --vnet-name $VM_VNET_NAME \
  --subnet $VM_SNET_NAME \
  --name $VM_NIC_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug 


## Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $VM_DEFAULT_IP_CONFIG \
  --nic-name $VM_NIC_NAME \
  --resource-group $VM_VNET_RG \
  --public-ip-address $VM_PUBLIC_IP_NAME \
  --debug


## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $VM_VNET_RG \
  --name $VM_SNET_NAME \
  --vnet-name $VM_VNET_NAME \
  --network-security-group $VM_NSG_NAME \
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
  --nics $VM_NIC_NAME \
  --tags $VM_TAGS \
  --debug


## Waiting for PIP
VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $VM_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$VM_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv" | wc -l)

while [[ "$VM_PUBLIC_IP" = "0" ]]
do
   echo "not good to go: " $VM_PUBLIC_IP
   echo "Sleeping for 2s..."
   sleep 2s
   VM_PUBLIC_IP=$(az network public-ip list \
     --resource-group $VM_VNET_RG \
     --output json | jq -r ".[] | select (.name==\"$VM_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv" | wc -l)
done

VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $VM_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$VM_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv")


## Allow SSH from local ISP
echo "Update VM NSG to allow SSH"
az network nsg rule create \
  --nsg-name $VM_NSG_NAME \
  --resource-group $VM_VNET_RG \
  --name ssh_allow \
  --priority 100 \
  --source-address-prefixes $VM_MY_ISP_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $VM_PRIV_IP \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp \
  --description "Allow from MY ISP IP"


## Input Key Fingerprint
echo "Input Key Fingerprint" 
FINGER_PRINT_CHECK=$(ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP | wc -l)

while [[ "$FINGER_PRINT_CHECK" = "0" ]]
do
    echo "not good to go: $FINGER_PRINT_CHECK"
    echo "Sleeping for 5s..."
    sleep 5
    FINGER_PRINT_CHECK=$(ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP | wc -l)
done


echo "Good to go with Input Key Fingerprint"
ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP >> ~/.ssh/known_hosts


## Update Server VM
echo "Update Server VM"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt update

## Upgrade Server VM
echo "Upgrade Server VM"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt upgrade -y


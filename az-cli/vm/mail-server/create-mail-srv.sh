##!/usr/bin/env bash
set -e
. ./params.sh


## VM Mail Server Creation
echo "Create VM Mail Server Subnet"
az network vnet subnet create \
  --resource-group $AKS_MAIN_VNET_RG \
  --vnet-name $AKS_MAIN_VNET_NAME \
  --name $VM_MAIL_SUBNET_NAME \
  --address-prefixes $VM_MAIL_SNET_CIDR \
  --debug


## VM NSG Create
echo "Create NSG"
az network nsg create \
  --resource-group $AKS_MAIN_VNET_RG \
  --name $VM_MAIL_NSG_NAME \
  --debug


## Public IP Create
echo "Create Public IP"
az network public-ip create \
  --name $VM_MAIL_PUBLIC_IP_NAME \
  --resource-group $AKS_MAIN_VNET_RG \
  --debug


## VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $AKS_MAIN_VNET_RG \
  --vnet-name $AKS_MAIN_VNET_NAME \
  --subnet $VM_MAIL_SUBNET_NAME \
  --name $VM_MAIL_NIC_NAME \
  --network-security-group $VM_MAIL_NSG_NAME \
  --debug 


## Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $VM_MAIL_DEFAULT_IP_CONFIG \
  --nic-name $VM_MAIL_NIC_NAME \
  --resource-group $AKS_MAIN_VNET_RG \
  --public-ip-address $VM_MAIL_PUBLIC_IP_NAME \
  --debug


## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $AKS_MAIN_VNET_RG \
  --name $VM_MAIL_SUBNET_NAME \
  --vnet-name $AKS_MAIN_VNET_NAME \
  --network-security-group $VM_MAIL_NSG_NAME \
  --debug


## Create VM
echo "Create VM"
az vm create \
  --resource-group $AKS_MAIN_VNET_RG \
  --authentication-type $VM_MAIL_AUTH_TYPE \
  --name $VM_MAIL_NAME \
  --computer-name $VM_MAIL_INTERNAL_NAME \
  --image $VM_MAIL_IMAGE \
  --size $VM_MAIL_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $VM_MAIL_STORAGE_SKU \
  --os-disk-size-gb $VM_MAIL_OS_DISK_SIZE \
  --os-disk-name $VM_MAIL_OS_DISK_NAME \
  --nics $VM_MAIL_NIC_NAME \
  --tags $VM_MAIL_TAGS \
  --debug


## Waiting for PIP
VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $AKS_MAIN_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$VM_MAIL_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv" | wc -l)

while [[ "$VM_PUBLIC_IP" = "0" ]]
do
   echo "not good to go: " $VM_PUBLIC_IP
   echo "Sleeping for 2s..."
   sleep 2s
   VM_PUBLIC_IP=$(az network public-ip list \
     --resource-group $AKS_MAIN_VNET_RG \
     --output json | jq -r ".[] | select (.name==\"$VM_MAIL_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv" | wc -l)
done

VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $AKS_MAIN_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$VM_MAIL_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv")


## Allow SSH from local ISP
echo "Update VM NSG to allow SSH"
az network nsg rule create \
  --nsg-name $VM_MAIL_NSG_NAME \
  --resource-group $AKS_MAIN_VNET_RG \
  --name ssh_allow \
  --priority 100 \
  --source-address-prefixes $VM_MY_ISP_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $VM_MAIL_PRIV_IP \
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



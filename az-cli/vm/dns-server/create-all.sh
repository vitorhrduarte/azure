##!/usr/bin/env bash
set -e
. ./params.sh

## VM DNS Server Subnet Creation
echo "Create VM DNS Server Subnet"
az network vnet subnet create \
  --resource-group $MAIN_VNET_RG \
  --vnet-name $MAIN_VNET_NAME \
  --name $VM_DNS_SUBNET_NAME \
  --address-prefixes $VM_DNS_SNET_CIDR \
  --debug


## VM NSG Create
echo "Create NSG"
az network nsg create \
  --resource-group $MAIN_VNET_RG \
  --name $VM_NSG_NAME \
  --debug


## Public IP Create
echo "Create Public IP"
az network public-ip create \
  --name $VM_DNS_PUBLIC_IP_NAME \
  --resource-group $MAIN_VNET_RG \
  --debug


## VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $MAIN_VNET_RG \
  --vnet-name $MAIN_VNET_NAME \
  --subnet $VM_DNS_SUBNET_NAME \
  --name $VM_NIC_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug 


## Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $VM_DNS_DEFAULT_IP_CONFIG \
  --nic-name $VM_NIC_NAME \
  --resource-group $MAIN_VNET_RG \
  --public-ip-address $VM_DNS_PUBLIC_IP_NAME \
  --debug


## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $MAIN_VNET_RG \
  --name $VM_DNS_SUBNET_NAME \
  --vnet-name $MAIN_VNET_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug


## Create VM
echo "Create VM"
az vm create \
  --resource-group $MAIN_VNET_RG \
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

echo "Sleeping 45s - Allow time for Public IP"
sleep 45

## Output Public IP of VM
echo "Public IP of VM is:"
VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $MAIN_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$VM_DNS_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv")

## Allow SSH from local ISP
echo "Update VM NSG to allow SSH"
az network nsg rule create \
  --nsg-name $VM_NSG_NAME \
  --resource-group $MAIN_VNET_RG \
  --name ssh_allow \
  --priority 100 \
  --source-address-prefixes $VM_MY_ISP_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $VM_DNS_PRIV_IP \
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

echo "Goood to go with Input Key Fingerprint"
ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP >> ~/.ssh/known_hosts



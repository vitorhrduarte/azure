##!/usr/bin/env bash
set -e
. ./params.sh

##############################
#  Functions #################
##############################


## Function to Peer Vnet's
funcPeerVnet () {

  ## Get Vnet's ID's
  echo "Getting Vnet's ID's"
  ORIGIN_JS_VNET_ID=$(az network vnet list -o json | jq -r ".[] | select( .name == \"$JS_VNET_NAME\" ) | [ .id ] | @tsv" | column -t)
  echo "$JS_VNET_NAME ID: $ORIGIN_JS_VNET_ID"
  DESTINATION_VNET_ID=$(az network vnet list -o json | jq -r ".[] | select( .name == \"$DEST_VNET_NAME\" ) | [ .id ] | @tsv" | column -t)
  echo "$DEST_VNET_NAME ID: $DESTINATION_VNET_ID"

  ## Peering Vnets
  echo "Peering $JS_VNET_NAME-To-$DEST_VNET_NAME"
  az network vnet peering create \
    --name "$JS_VNET_NAME-To-$DEST_VNET_NAME" \
    --resource-group $JS_VNET_RG \
    --vnet-name $JS_VNET_NAME \
    --remote-vnet $DESTINATION_VNET_ID \
    --allow-vnet-access \
    --debug

  echo "Peering $DEST_VNET_NAME-To-$JS_VNET_NAME"
  az network vnet peering create \
    --name  "$DEST_VNET_NAME-To-$JS_VNET_NAME" \
    --resource-group $DEST_VNET_RG \
    --vnet-name $DEST_VNET_NAME \
    --remote-vnet $ORIGIN_JS_VNET_ID \
    --allow-vnet-access \
    --debug

}



###################################
# Main ############################
###################################



if [[ "$NVA_CREATION" == "1" ]];
then	

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

## Peer the Vnet
echo "Peer the Vnet"
funcPeerVnet

fi

if [[ "$NVA_SETUP" == "1" ]];
then


## Input Key Fingerprint
echo "Input Key Fingerprint" 
FINGER_PRINT_CHECK=$(ssh-keygen -F $VM_PRIV_IP_NOCIDR >/dev/null | ssh-keyscan -H $VM_PRIV_IP_NOCIDR | wc -l)

while [[ "$FINGER_PRINT_CHECK" = "0" ]]
do
    echo "Not Good to GO: $FINGER_PRINT_CHECK"
    echo "Sleeping for 5s..."
    sleep 5
    FINGER_PRINT_CHECK=$(ssh-keygen -F $VM_PRIV_IP_NOCIDR >/dev/null | ssh-keyscan -H $VM_PRIV_IP_NOCIDR | wc -l)
done

echo "Goood to go with Input Key Fingerprint"
ssh-keygen -F $VM_PRIV_IP_NOCIDR >/dev/null | ssh-keyscan -H $VM_PRIV_IP_NOCIDR >> ~/.ssh/known_hosts


## Install Net Tools
echo "Install Net Tools"
ssh $GENERIC_ADMIN_USERNAME@$VM_PRIV_IP_NOCIDR "sudo apt install net-tools -y"

## Enable IP Forwarding
echo "Enable IP Forwarding"
ssh $GENERIC_ADMIN_USERNAME@$VM_PRIV_IP_NOCIDR "sudo sed -i 's/#net\.ipv4\.ip_forward=1/net\.ipv4\.ip_forward=1/g' /etc/sysctl.conf"


## Enable the Routing
echo "Enable the Routing"
ssh $GENERIC_ADMIN_USERNAME@$VM_PRIV_IP_NOCIDR "sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"


## Install Software to save IPTables on reboot
echo "Install software to save iptables on reboot"
ssh $GENERIC_ADMIN_USERNAME@$VM_PRIV_IP_NOCIDR "sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent"


## Rebooting
echo "Rebooting"
ssh $GENERIC_ADMIN_USERNAME@$VM_PRIV_IP_NOCIDR "sudo reboot"

fi

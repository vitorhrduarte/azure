##!/usr/bin/env bash
set -e
. ./params.sh


 ###################################################################################
 ## Functions 
 ###################################################################################
 ## Coundown function
 countdown() {
   IFS=:
   set -- $*
   secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
   while [ $secs -gt 0 ]
   do
     sleep 1 &
     printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
     secs=$(( $secs - 1 ))
     wait
   done
   echo
 }
 
###################################################################################
## Functions
###################################################################################


## Create RG for Cluster
echo "Create RG for Cluster"
az group create \
  --name $CLUSTER_RG_NAME \
  --location $CLUSTER_RG_LOCATION \
  ##--debug


## Create VNet for Cluster
echo "Create Vnet for Cluster"
az network vnet create \
  --resource-group $CLUSTER_RG_NAME \
  --name $CLUSTER_VNET_NAME \
  --address-prefix $CLUSTER_VNET_CIDR \
  ##--debug


## Create Subnet for Cluster
echo "Create Subnet for AKS Cluster"
az network vnet subnet create \
  --resource-group $CLUSTER_RG_NAME \
  --vnet-name $CLUSTER_VNET_NAME \
  --name $CLUSTER_VNET_SNET_NAME \
  --address-prefixes $CLUSTER_VNET_SNET_CIDR \
  ##--debug


## Create Single Control Plane k8s
for i in $(seq 1 $CLUSTER_HOW_MANY_CCP_NODES)
do
  echo ""
  echo "CCP ID: $i"

  ## Create Linux VM
  echo "Create CCP VM"
  az vm create \
    --resource-group $CLUSTER_RG_NAME \
    --authentication-type $CCP_AUTH_TYPE \
    --name "$CCP_NAME$i" \
    --computer-name "$CCP_INTERNAL_NAME$i" \
    --image $CCP_IMAGE \
    --size $CCP_SIZE \
    --admin-username $GENERIC_ADMIN_USERNAME \
    --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
    --storage-sku $CCP_STORAGE_SKU \
    --os-disk-size-gb $CCP_OS_DISK_SIZE \
    --os-disk-name "$CCP_NAME$i""_disk_01" \
    --vnet-name $CLUSTER_VNET_NAME \
    --subnet $CLUSTER_VNET_SNET_NAME \
    --public-ip-address "" \
    --tags $CCP_TAGS \
    ##--debug
done

## Create X Worker nodes
for j in $(seq 1 $CLUSTER_HOW_MANY_WORKER_NODES)
do 
  echo ""
  echo "WKN ID: $j"

  ## Create Linux Worker Nodes VMs
  echo "Create Linux VM's for Worker Nodes"
  az vm create \
    --resource-group $CLUSTER_RG_NAME \
    --authentication-type $WN_AUTH_TYPE \
    --name "$WN_NAME$j" \
    --computer-name "$WN_INTERNAL_NAME$j" \
    --image $WN_IMAGE \
    --size $WN_SIZE \
    --admin-username $GENERIC_ADMIN_USERNAME \
    --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
    --storage-sku $WN_STORAGE_SKU \
    --os-disk-size-gb $WN_OS_DISK_SIZE \
    --os-disk-name "$WN_NAME$j""_disk_01" \
    --vnet-name $CLUSTER_VNET_NAME \
    --subnet $CLUSTER_VNET_SNET_NAME \
    --public-ip-address "" \
    --tags $WN_TAGS \
    ##--debug
done


echo "END"


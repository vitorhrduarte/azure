#!/bin/bash

# Define Envrinoment Variables :
ARO_RG_LOCATION="westeurope"                        # Location of your ARO cluster
ARO_CLUSTER_NAME="aro-2022-06"                      # Name of your ARO cluster
ARO_RG_NAME="rg-"$ARO_CLUSTER_NAME                  # Name of Resource Group where you want to create your ARO Cluster
ARO_NODE_RG_NAME="mc-rg-$ARO_CLUSTER_NAME"


ARO_VNET_NAME="vnet-"$ARO_CLUSTER_NAME                                  # Name of ARO VNET
ARO_VNET_PREFIX="10.5"
ARO_VNET_CIDR="$ARO_VNET_PREFIX.0.0/16"                                 # VNET Address Prefixes
ARO_VNET_SUBNET_MASTER_NAME="snet-m-$ARO_CLUSTER_NAME"                  # Name of ARO Master Subnet
ARO_VNET_SUBNET_MASTER_NAME_CIDR="$ARO_VNET_PREFIX.0.0/18"              # Master Subnet Address Prefixes
ARO_VNET_SUBNET_WORKER_NAME="snet-w-$ARO_CLUSTER_NAME"                  # Name of ARO Worker Subnet
ARO_VNET_SUBNET_WORKER_NAME_CIDR="$ARO_VNET_PREFIX.64.0/18"             # Worker Subnet Address Prefixes


ARO_PULL_SECRET_PATH=$ARO_SECRET_PULL_PATH


## Create ARO Cluster Prerequisites :
echo "Create ARO RG"
az group create \
  --name $ARO_RG_NAME \
  --location $ARO_RG_LOCATION

echo "Create ARO Vnet"
az network vnet create \
  --resource-group $ARO_RG_NAME \
  --name $ARO_VNET_NAME \
  --address-prefixes $ARO_VNET_CIDR

echo "Create ARO Subnet for Master nodes"
az network vnet subnet create \
  --resource-group $ARO_RG_NAME \
  --vnet-name $ARO_VNET_NAME \
  --name $ARO_VNET_SUBNET_MASTER_NAME \
  --address-prefixes $ARO_VNET_SUBNET_MASTER_NAME_CIDR \
  --service-endpoints Microsoft.ContainerRegistry

echo "Create ARO Subnet for Worker nodes"
az network vnet subnet create \
  --resource-group $ARO_RG_NAME \
  --vnet-name $ARO_VNET_NAME \
  --name $ARO_VNET_SUBNET_WORKER_NAME \
  --address-prefixes $ARO_VNET_SUBNET_WORKER_NAME_CIDR \
  --service-endpoints Microsoft.ContainerRegistry

echo "Update ARO Subnet for Master nodes"
az network vnet subnet update \
  --name $ARO_VNET_SUBNET_MASTER_NAME \
  --resource-group $ARO_RG_NAME \
  --vnet-name $ARO_VNET_NAME \
  --disable-private-link-service-network-policies true

echo "Create ARO Cluster"
az aro create \
  --resource-group $ARO_RG_NAME  \
  --name $ARO_CLUSTER_NAME \
  --vnet $ARO_VNET_NAME \
  --master-subnet $ARO_VNET_SUBNET_MASTER_NAME \
  --worker-subnet $ARO_VNET_SUBNET_WORKER_NAME \
  --pull-secret $ARO_PULL_SECRET_PATH \
  --cluster-resource-group $ARO_NODE_RG_NAME \
  --client-id $ARO_SP_ID \
  --client-secret $ARO_SP_SECRET \
  --debug

echo "Get ARO's in SUB"
az aro list \
  --output table

echo "Get ARO Credentials"
az aro list-credentials \
  --name $ARO_CLUSTER_NAME \
  --resource-group $ARO_RG_NAME

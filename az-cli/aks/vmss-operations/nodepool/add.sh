##!/usr/bin/env bash

## Get all the AKS cluster
echo "Get available AKS"
az aks list \
  --output table

echo ""
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Input AKS RG Name: " AKSRG
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Selected AKS RG Name is: $AKSRG"
echo ""
echo ""
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Input AKS Name: " AKS
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Selected AKS Name is: $AKS"

az aks list \
  --resource-group $AKSRG \
  --query "[].agentPoolProfiles[].{Name:name, Mode:mode, Count:count, NodeImgVer:nodeImageVersion, MaxPods:maxPods}" \
  --output table 


echo ""
echo "Adding NP to AKS $AKS"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Input NP Name: " NPNAME
read -p "Input NP SKU: " NPSKU
read -p "Input NP Type user/system: " NPTYPE
read -p "Input NP Instances: " NPINSTANCES
read -p "Input NP Disk is Ephemeral/Managed: " NPOSDISKTYPE
read -p "Input NP OS Disk Size in GB: " NPOSSIZE
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ""

az aks nodepool add \
  --resource-group $AKSRG \
  --name $NPNAME \
  --cluster-name $AKS \
  --node-osdisk-type $NPOSDISKTYPE \
  --node-osdisk-size $NPOSSIZE \
  --tags "env=$NPNAME" \
  --mode $NPTYPE \
  --node-count $NPINSTANCES \
  --node-vm-size $NPSKU \
  --debug


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
echo "Removing NP to AKS $AKS"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Input NP Name: " NPNAME
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ""

echo ""
echo "Deleting NP $NPNAME"
echo ""

az aks nodepool delete \
  --resource-group $AKSRG \
  --name $NPNAME \
  --cluster-name $AKS \
  --no-wait \
  --debug


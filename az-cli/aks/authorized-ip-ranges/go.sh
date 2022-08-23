##!/usr/bin/env bash

AKS_NAME="aks-kube01"
AKS_RG_NAME="rg-$AKS_NAME"


PIP=$(curl -s -4 ifconfig.io) 

CURRENTPIP=$(az aks show --resource-group $AKS_RG_NAME --name $AKS_NAME --query apiServerAccessProfile.authorizedIpRanges | jq -r ". | @csv")

echo ""
echo "PIP: $PIP"
echo ""
echo "CURRENT IP: $CURRENTPIP"

CURRENTPIP=$(echo "$CURRENTPIP" | sed s/\"//g)

FINALLIST="$PIP/32,$CURRENTPIP"



echo ""
echo "Final List: $FINALLIST"

az aks update \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --api-server-authorized-ip-ranges $FINALLIST

##!/usr/bin/env bash

AKS_NAME="aks-kube01"
AKS_RG_NAME="rg-$AKS_NAME"


PIP=$(curl -s -4 ifconfig.io) 

CURRENTPIP=$(az aks show --resource-group $AKS_RG_NAME --name $AKS_NAME --query apiServerAccessProfile.authorizedIpRanges | jq -r ". | @csv")

#echo ""
#echo "PIP: $PIP"
#echo ""
#echo "CURRENT IP: $CURRENTPIP"

CURRENTPIP=$(echo "$CURRENTPIP" | sed s/\"//g)

FINALLIST="$PIP/32,$CURRENTPIP"



declare -A words

IFS=","
for w in $FINALLIST; do
  #echo $w
  #echo ""
  words+=( [$w]="" )
done

FLIST=$(echo \"${!words[@]}\" | sed 's/ /,/g')
#echo ">>>>>"
FL=$(echo $FLIST | sed 's/ /,/g' | sed 's/"//g')

#echo ">>>>>"
#echo $FL



echo "Set Empty List"
az aks update \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --api-server-authorized-ip-ranges ""

echo "Update Allowed List"
az aks update \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --api-server-authorized-ip-ranges $FL \
  --debug

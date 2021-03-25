##!/usr/bin/env bash

echo "Show AKS Clusters:" 
az aks list \
  --query "[].{Name:name, Location:location, RG:resourceGroup}" \
  -o table

echo ""
read -p "AKS RG? " aksrg
echo "List nodepool for the AKS Cluster"
az aks list \
  -g $aksrg \
  --query "[].agentPoolProfiles[].{Name:name, Mode:mode, Count:count, NodeImgVer:nodeImageVersion, MaxPods:maxPods}" \
  -o table

aksclustername=$(az aks list -g $aksrg --query "[].{Name:name}" -o tsv)
aksrgname=$(az aks list -g $aksrg --query "[].{RG:resourceGroup}" -o tsv)

echo ""
read -p "Insert Nodepool name: " aksnpname
echo ""

hasautoscaler=$(az aks nodepool show --cluster-name $aksclustername -n $aksnpname -g $aksrgname -o json | jq ".enableAutoScaling")

if [[ $hasautoscaler == "true" ]];
then
  echo ""
  echo "Nothing to do, nodepool $aksnpname has AutoScaler enabled"
  echo ""

  read -p "Want to Disable? {true,false} " disableautoscaler
 
  while [[ "$disableautoscaler" != "true" && "$disableautoscaler" != "false" ]]
  do
    read -p "Do you want to enable AutoScaler? {true,false} " disableautoscaler
  done
 
  if [[ "$disableautoscaler" == "true" ]];
  then
    echo "Disabling AutoScaler"
    az aks nodepool update \
      --disable-cluster-autoscaler \
      -g $aksrgname \
      -n $aksnpname \
      --cluster-name $aksclustername \
      --debug
  fi
else
  read -p "Do you want to enable AutoScaler? {true,false} " enableautoscaler
   
  while [[ "$enableautoscaler" != "true" && "$enableautoscaler" != "false" ]]
  do
    read -p "Do you want to enable AutoScaler? {true,false} " enableautoscaler
  done

  if [[ $enableautoscaler == "true"  ]];
  then
    echo ""
    read -p "Maximum nodes is: " maxnodes
    az aks nodepool update \
      -g $aksrgname \
      -n $aksnpname \
      --cluster-name $aksclustername \
      --enable-cluster-autoscaler \
      --min-count 1 \
      --max-count $maxnodes \
      --debug
  else 
    read -p "How Many Nodes? " npnumber
    az aks scale \
      --name $aksclustername \
      --resource-group $aksrgname \
      --nodepool-name  $aksnpname \
      --node-count $npnumber \
     --debug
  fi
fi

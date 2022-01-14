##!/usr/bin/env bash
set -e
. ./params.sh

declare -a OSM_NS

## Get all the OSM NS
echo "Get all the OSM NS"
OSM_NS=($(kubectl get ns -l openservicemesh.io/monitored-by=osm --no-headers | awk '{print $1}' | tr ' ' '\n'))

## Delete all the previous NS
echo "Delete all the previous NS"
for NS in "${OSM_NS[@]}"; do
  echo "Deleting NS: ${NS}"
  kubectl delete ns ${NS}
done

## Remove AKS OSM add-on
echo "Remove AKS OSM add-on"
az aks disable-addons \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --addons open-service-mesh

##!/usr/bin/env bash

## Verify your mesh has permissive mode enabled
echo "Verify your mesh has permissive mode enabled"
OSM_STATUS=$(kubectl get meshconfig osm-mesh-config \
  --namespace kube-system -o=jsonpath='{$.spec.traffic.enablePermissiveTrafficPolicyMode}')

if [[ "OSM_STATUS" == "true" ]] 
then
    echo "OSM status is: " $OSM_STATUS 
    echo "Continue..."
else
    echo "Allow all for OSM..."
	kubectl patch meshconfig osm-mesh-config \
  	  --namespace kube-system -p '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":true}}}' \
      --type=merge
fi

## Create and onboard the namespaces to be managed by OSM
echo " "
echo "Create and onboard the namespaces to be managed by OSM"
echo "Creating NS: bookstore" 
kubectl create ns bookstore

echo " "
echo "Creating NS: bookbuyer"
kubectl create ns bookbuyer

echo " "
echo "Creating NS: bookthief"
kubectl create ns bookthief

echo " "
echo "Creating NS: bookwarehouse"
kubectl create ns bookwarehouse

echo " "
echo "Add previous NS to the OSM Namespace"
osm namespace add bookstore bookbuyer bookthief bookwarehouse


## Deploy the sample application to the AKS cluster
echo "Deploy the sample application to the AKS cluster"
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/main/manifests/apps/bookbuyer.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/main/manifests/apps/bookthief.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/main/manifests/apps/bookstore.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/main/manifests/apps/bookwarehouse.yaml


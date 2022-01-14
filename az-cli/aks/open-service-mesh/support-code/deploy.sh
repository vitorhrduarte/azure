##!/usr/bin/env bash
set -e
. ./params.sh

## Enable OSM in the AKS cluster
echo "Enable OSM in the AKS cluster"
az aks enable-addons \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --addons open-service-mesh

## Check OSM setup
echo "Check OSM setup"
az aks show \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --query 'addonProfiles.openServiceMesh.enabled'

## Sleep 30s
echo "Sleep 30s"
sleep 30

## Check OSM Deployment
echo "Check OSM Deployment"
kubectl get deployment --namespace kube-system osm-controller -o=jsonpath='{$.spec.template.spec.containers[:1].image}'

## Verify OSM components status
echo "Verify OSM components status"
echo "Deployments"
kubectl get deployments --namespace kube-system --selector app.kubernetes.io/name=openservicemesh.io

echo ""
echo "Pods"
kubectl get pods --namespace kube-system --selector app.kubernetes.io/name=openservicemesh.io

echo ""
echo "Services"
kubectl get services --namespace kube-system --selector app.kubernetes.io/name=openservicemesh.io

## Verify OSM mesh
echo "Verify OSM mesh"
kubectl get meshconfig osm-mesh-config -n kube-system -o yaml

## Install OSM
echo "Install OSM Binaries"
bash support-code/install-osm.sh

## Deploy sample app
echo "Deploy sample app"
bash support-code/deploy-sample-app.sh




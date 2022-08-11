##!/usr/bin/env bash

## Create a namespace for your ingress resources
echo "Creating NS for IngController"
kubectl create namespace ingress-basic

## Add the ingress-nginx repository
echo "Add IngController Helm Repo"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

## Tips
## The following example creates a Kubernetes namespace for the ingress resources named ingress-basic. 
## Specify a namespace for your own environment as needed. 
## If your AKS cluster is not Kubernetes RBAC enabled, add --set rbac.create=false to the Helm commands.

## If you would like to enable client source IP preservation for requests to containers in your cluster, add --set controller.service.externalTrafficPolicy=Local to the Helm install command. 
## The client source IP is stored in the request header under X-Forwarded-For. 
## When using an ingress controller with client source IP preservation enabled, TLS pass-through will not work.


## Use Helm to deploy an NGINX ingress controller
echo "Deploy IngController"
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    -f internal-ingress.yaml \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."failure-domain\.beta\.kubernetes\.io/zone"=westeurope-1 \
    --set controller.nodeSelector."kubernetes\.io/hostname"=aks-usrnp02-27199108-vmss000001 \
    --set defaultBackend.nodeSelector."failure-domain\.beta\.kubernetes\.io/zone"=westeurope-1 \
    --set defaultBackend.nodeSelector."kubernetes\.io/hostname"=aks-usrnp02-27199108-vmss000001 \
    --set controller.admissionWebhooks.patch.nodeSelector."failure-domain\.beta\.kubernetes\.io/zone"=westeurope-1 \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/hostname"=aks-usrnp02-27199108-vmss000001 \
    --set controller.service.externalTrafficPolicy=Local

echo "Sleep for 45s"
sleep 45

echo "Deploy AKS App 00"
kubectl apply -f 00-app00.yaml --namespace ingress-basic

echo "Deploy AKS App Ingress Controller"
kubectl apply -f 01-app-ingress.yaml --namespace ingress-basic


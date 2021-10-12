##!/usr/bin/env bash

## Installation
## How to install AAD Pod Identity on your clusters.
## Quick Install
## To install/upgrade AAD Pod Identity on RBAC-enabled clusters:

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.8.4/deploy/infra/deployment-rbac.yaml

## To install/upgrade aad-pod-identity on RBAC-disabled clusters:
##kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.8.4/deploy/infra/deployment.yaml

## For AKS clusters, you will have to allow MIC and AKS add-ons to access IMDS without being intercepted by NMI:

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.8.4/deploy/infra/mic-exception.yaml

## Warning
## failure to apply mic-exception.yaml in AKS clusters will result in token failures for AKS addons using managed identity for authentication.


## Helm
## AAD Pod Identity allows users to customize their installation via Helm.
## Link https://github.com/Azure/aad-pod-identity/tree/master/charts/aad-pod-identity#configuration

helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts

helm install aad-pod-identity aad-pod-identity/aad-pod-identity

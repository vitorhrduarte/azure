##!/usr/bin/env bash
set -e
. ./params.sh

## Add Repo
echo "Adding Repository"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

## Install 
echo "Install Nginx Ingress"
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.0.16 \
    --namespace ingress-basic --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.image.digest="" \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.image.digest="" \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.image.digest=""

## Get PIP of LB
echo "Get PIP of LB"
LB_PIP=$(kubectl get svc -A -n nginx-ingress-ingress-nginx-controller --no-headers -o json | jq -r '.items[].status.loadBalancer.ingress[]?.ip' | wc -l)

while [[ "$LB_PIP" = "0" ]]
do
    echo "not good to go: $LB_PIP"
    echo "Sleeping for 5s..."
    sleep 5
    LB_PIP=$(kubectl get svc -A -n nginx-ingress-ingress-nginx-controller --no-headers -o json | jq -r '.items[].status.loadBalancer.ingress[]?.ip' | wc -l)
done

echo "Go to go with LB PIP"
LB_PIP=$(kubectl get svc -A -n nginx-ingress-ingress-nginx-controller --no-headers -o json | jq -r '.items[].status.loadBalancer.ingress[]?.ip')
echo "LB PIP is: $LB_PIP"

## Create a DNS zone
echo "Create a DNS zone"
az network dns zone create \
  --resource-group $AKS_RG \
  --name $CUSTOM_DOMAIN_NAME

## Add an A record to your DNS zone
echo "Add an A record to your DNS zone"
az network dns record-set a add-record \
  --resource-group $AKS_RG \
  --zone-name $CUSTOM_DOMAIN_NAME \
  --record-set-name "*" \
  --ipv4-address $LB_PIP \
  --debug

## Get LB PIP ID
echo "Get LB PIP ID"
PUBLIC_IP_ID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$LB_PIP')].[id]" --output tsv)
echo "LB PIP ID: $PUBLIC_IP_ID"


## Set the DNS label using the Azure CLI
echo "Set the DNS label using the Azure CLI"
## Update public ip address with DNS name
echo "Update public ip address with DNS name"
az network public-ip update \
  --ids $PUBLIC_IP_ID \
  --dns-name $AKS_APP_DNS_NAME \
  --debug

## Display the FQDN
echo "Display the FQDN"
az network public-ip show \
  --ids $PUBLIC_IP_ID \
  --query "[dnsSettings.fqdn]" \
  --output tsv


## Label the ingress-basic namespace to disable resource validation
echo "Label the cert-manager namespace to disable resource validation"
kubectl label namespace ingress-basic cert-manager.io/disable-validation=true

## Add the Jetstack Helm repository
echo "Add the Jetstack Helm repository"
helm repo add jetstack https://charts.jetstack.io

## Update your local Helm chart repository cache
echo "Update your local Helm chart repository cache"
helm repo update

## Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager \
  --namespace ingress-basic \
  --version $CERT_MANAGER_TAG \
  --set installCRDs=true \
  --set nodeSelector."kubernetes\.io/os"=linux \
  --set image.tag=$CERT_MANAGER_TAG \
  --set webhook.nodeSelector."kubernetes\.io/os"=linux \
  --set webhook.image.tag=$CERT_MANAGER_TAG \
  --set cainjector.nodeSelector."kubernetes\.io/os"=linux \
  --set cainjector.image.tag=$CERT_MANAGER_TAG \
  --set startupapicheck.nodeSelector."kubernetes\.io/os"=linux \
  --set startupapicheck.image.tag=$CERT_MANAGER_TAG

## Deploy Cluster Issuer
echo "Deploy Cluster Issuer"

rm -rf lets-encrypt-cluster-issuer.yaml

printf "apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $APP_ADMIN_EMAIL
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
          podTemplate:
            spec:
              nodeSelector:
                "kubernetes.io/os": linux

" >> lets-encrypt-cluster-issuer.yaml

kubectl apply -f lets-encrypt-cluster-issuer.yaml

## Deploy Apps
echo "App 01"
kubectl apply -f app-01.yaml -n ingress-basic
echo ""
echo "App 02"
kubectl apply -f app-02.yaml -n ingress-basic

## Deploy Ingress Route
echo "Deploy Ingress Route"

rm -rf ingress-route.yaml

printf "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/rewrite-target: /\$1
    nginx.ingress.kubernetes.io/use-regex: \"true\"
spec:
  tls:
  - hosts:
    - $APP_FQDN
    secretName: tls-secret
  rules:
  - host: $APP_FQDN
    http:
      paths:
      - path: /hello-world-one(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
      - path: /hello-world-two(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-two
            port:
              number: 80
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress-static
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /static/\$2
    nginx.ingress.kubernetes.io/use-regex: \"true\"
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
  - hosts:
    - $APP_FQDN
    secretName: tls-secret
  rules:
  - host: $APP_FQDN
    http:
      paths:
      - path:
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port: 
              number: 80
        path: /static(/|$)(.*)
" >> ingress-route.yaml 

kubectl apply -f ingress-route.yaml -n ingress-basic

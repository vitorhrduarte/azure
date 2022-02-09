##!/usr/bin/env bash

getCoreDnsCustomConfigMap () {
    echo "Get Current Custom CoreDNS CM"
    kubectl -n kube-system describe cm coredns-custom
}


## Get Current Custom CoreDNS CM
getCoreDnsCustomConfigMap

## Apply CoreDNS ConfigMap
echo "Apply CoreDNS ConfigMap"
kubectl apply -f core-dns-cm.yaml 

## Re-deploy CoreDNS pods 
echo "Re-deploy CoreDNS pods"
kubectl rollout restart -n kube-system deployment/coredns

## Get Current Custom CoreDNS CM
getCoreDnsCustomConfigMap

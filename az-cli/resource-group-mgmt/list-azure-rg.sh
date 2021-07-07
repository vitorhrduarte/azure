#!/bin/bash


echo "List Azure RG"
az group list -o json | jq -r '(["Location","AKSClusterName","Status"] | (., map(length*"-"))),(.[] | [ .location, .name ,.properties.provisioningState ]) | @tsv' | column -t

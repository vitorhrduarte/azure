##!/usr/bin/env bash

echo "List AKS's"
az aks list -o table

echo ""
read -p "Input AKS RG: " aksrg
read -p "Input AKS NAME: " aksname
az aks nodepool list -g $aksrg --cluster-name $aksname -o table

echo""
read -p "Input AKS Nodepool: " aksnp
az aks nodepool show -g $aksrg --cluster-name $aksname -n $aksnp | jq -r ". | [.name, .mode] | @csv"

echo ""
read -p "Input AKS Nodepool Type {user,system}: " aksnptype
az aks nodepool update -g $aksrg --cluster-name $aksname -n $aksnp --mode $aksnptype --debug
echo ""
echo "Current value is: "
az aks nodepool show -g $aksrg --cluster-name $aksname -n $aksnp | jq -r ". | [.name, .mode] | @csv"


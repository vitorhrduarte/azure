#!/bin/sh

echo "Not running VMs"
az vm list -d --query "[?powerState!='VM running']" -o table

echo "Running VMs"
az vm list -d --query "[?powerState=='VM running']" -o table


echo "All VMs"
az vm list -d -o table

#!/bin/bash

usage() {
  echo "Usage: $0 -g <resource-group> -n <vm-name> [-h]"
  echo "Retrieves the public IP address of a VM in Azure"
  echo ""
  echo "Options:"
  echo "  -g <resource-group>  The name of the resource group that contains the VM"
  echo "  -n <vm-name>         The name of the VM"
  echo "  -h                   Display this help message"
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

# Parse command line arguments
while getopts ":g:n:h" opt; do
  case $opt in
    g) resourceGroup="$OPTARG"
    ;;
    n) vmName="$OPTARG"
    ;;
    h) usage
       exit 0
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        usage
        exit 1
    ;;
  esac
done

# Check if both resource group and VM name are provided
if [ -z "$resourceGroup" ] || [ -z "$vmName" ]; then
  echo "Error: Both resource group and VM name are required"
  usage
  exit 1
fi

# Check if resource group exists
if ! az group show -n $resourceGroup &>/dev/null; then
  echo "Error: Resource group $resourceGroup not found"
  exit 1
fi

# Check if VM exists
if ! az vm show -d -g $resourceGroup -n $vmName &>/dev/null; then
  echo "Error: VM $vmName not found in resource group $resourceGroup"
  exit 1
fi

# Use the Azure CLI to get the public IP address of the VM
publicIp=$(az vm show -d -g $resourceGroup -n $vmName --query publicIps -o tsv)

# Print the public IP address
echo "Public IP address of $vmName is: $publicIp"


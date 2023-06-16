#!/bin/bash

function help {
    echo "Usage: $0 -r <resource-group-name>"
    echo "This script lists all the running VMs in the specified resource group and their public IP addresses (if any)."
}

while getopts ":r:h" opt; do
  case ${opt} in
    r )
      resourceGroupName=$OPTARG
      ;;
    h )
      help
      exit 0
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      help
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument" >&2
      help
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [[ -z "$resourceGroupName" ]]; then
    echo "Error: Resource group name is missing"
    help
    exit 1
fi

if ! az group show -n $resourceGroupName &>/dev/null; then
    echo "Error: Resource group '$resourceGroupName' not found"
    exit 1
fi

vms=($(az vm list -g $resourceGroupName --query "[].name" -o tsv))
ipAddresses=()

for vmName in "${vms[@]}"; do
    vmStatus=$(az vm show -d -g $resourceGroupName -n "$vmName" --query "powerState" -o tsv)

    if [[ "$vmStatus" == "VM running" ]]; then
        publicIp=$(az vm show -d -g $resourceGroupName -n "$vmName" --query "publicIps" -o tsv)

        if [[ "$publicIp" != "" ]]; then
            ipAddresses+=("$vmName: $publicIp")
        fi
    fi
done

echo "Public IP addresses:"
printf '%s\n' "${ipAddresses[@]}"


##!/usr/bin/env bash

## Get all the AKS cluster
echo "Get available AKS"
az aks list \
  --output table

echo ""
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Input AKS name: " AKSNAME
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Selected AKS Name is: $AKSNAME"
echo ""
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Input AKS RG: " AKSRGNAME
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Selected AKS RG Name is: $AKSRGNAME"

## Get Environment Variables : 
AKS_NODE_RG_NAME=$(az aks show \
  --name $AKSNAME \
  --resource-group $AKSRGNAME \
  --query nodeResourceGroup \
  --output tsv )

echo "Selected AKS Node RG Name is : $AKS_NODE_RG_NAME"
echo ""

VMSS_ID=$(az vmss list \
  --resource-group $AKS_NODE_RG_NAME \
  --query=[].name \
  --output tsv)

echo "Available VMSS ID('s) is/are :"
echo "$VMSS_ID"
echo ""

echo ">>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Insert VMSS nodepool: " VMSSNODEPOOL
echo ">>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Selected VMSS nodepool is: $VMSSNODEPOOL"
echo ""

VMSS_INSTANCE_ID=$(az vmss list-instances \
  --name $VMSSNODEPOOL \
  --resource-group $AKS_NODE_RG_NAME \
  --query=[].instanceId -o tsv)

echo "Available VMSS Instances ID('s) is/are : "
echo "$VMSS_INSTANCE_ID"
echo ""
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Insert VMSS Instance ID number: " VMSSIDNUMBER
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Selected Instance # $VMSSIDNUMBER of VMSS $VMSSNODEPOOL"
echo ""

## Show the current Service Principle for the AKS Cluster :
SP_ID=$(az aks show \
  --resource-group $AKSRGNAME \
  --name $AKSNAME  \
  --query servicePrincipalProfile.clientId \
  --output tsv)
echo "Current AKS SP ID is $SP_ID"

##  Save information of the Service Principle :
SP_INFORMATION=$(az ad sp show --id $SP_ID)

az ad sp show \
  --id $SP_ID > SP_ID_$(date +%Y-%m-%d_%H:%M)_$VMSSNODEPOOL\_$VMSSIDNUMBER.json
echo "Current AAD SP Information is: $SP_ID"

## Show the Application Display Name for the Service Principle :
SP_DISPLAY_NAME=$(az ad sp show \
  --id $SP_ID | grep 'appDisplayName' | cut -d":" -f2 | awk '{print $1}' | cut -d"\"" -f2)

echo "Current AAD SP Display Name is: $SP_DISPLAY_NAME"
echo ""

## Save information of /etc/kubernetes/azure.json :
echo "Running VMSS command"
az vmss run-command invoke \
  --command-id RunShellScript \
  --resource-group $AKS_NODE_RG_NAME \
  --name $VMSSNODEPOOL \
  --instance-id $VMSSIDNUMBER \
  --scripts "hostname && date && cat /etc/kubernetes/azure.json" > $VMSSNODEPOOL\_$VMSSIDNUMBER\_$(date +%Y-%m-%d_%H:%M)_etc_kubernetes_azure.json

echo "Processing SP password"
SP_PASS=$(az vmss run-command invoke \
  --command-id RunShellScript \
  --resource-group $AKS_NODE_RG_NAME  \
  --name $VMSSNODEPOOL  \
  --instance-id $VMSSIDNUMBER \
  --scripts "hostname && date && cat /etc/kubernetes/azure.json" | grep aadClientSecret | sed 's/\\n/\n/g' | grep aadClientSecret | cut -d":" -f2 | cut -d"\"" -f2 | cut -d"\\" -f1)

echo ""
echo Service Principle Password In VMSS: $SP_PASS
echo Service Principle Display Name In AAD: $SP_DISPLAY_NAME
echo Service Principle ID in AKS: $SP_ID
echo ""
echo "List of the JSON outputs in current directory: "
ls | grep "^$VMSSNODEPOOL\_$VMSSIDNUMBER"
echo ""
read -p "Input JSON output name file: " JSON_OUT
cat $JSON_OUT | jq ".value[].message" | jq -r "."
echo ""


## Extend the expiration Date of Service Principle without changing the old password :
echo ""
echo "Extend current SP expiration date"
read -p "Input desired date: format { mm/dd/yyyy } : " EXPIREDATE
date "+%m/%d/%Y" -d $EXPIREDATE > /dev/null  2>&1
IS_DATE_VALID=$?

if [[ $IS_DATE_VALID == "1" ]]; then
  echo "Invalid date: $IS_DATE_VALID"
else
  TODAY_DATE=$(date "+%m/%d/%Y")
  TODAY_DATE_EPOCH=$(date -d $TODAY_DATE '+%s')
  EXPIRE_DATE_EPOCH=$(date -d $EXPIREDATE '+%s')

  if [ $EXPIRE_DATE_EPOCH -gt $TODAY_DATE_EPOCH ]; then   
    echo "GO ahead? yes or no?"
    PS3='Your choice is: '
    select result in 'yes' 'no'; do
      case $REPLY in
        [12])
            break
            ;;
        *)
            echo 'Invalid choice' >&2
      esac
    done

    if [[ "$result" == "yes"  ]]; then
      echo "Changing SP expiring date...."
      az ad sp credential reset \
        --name $SP_DISPLAY_NAME \
        --password $SP_PASS \
        --end-date $EXPIREDATE'T11:59:59+00:00' > SP_Info_Final.txt
    fi
  else
    echo "Invalid Date. is less or equal to today"
  fi
fi


echo "END"

##!/usr/bin/env bash


showHelp() {
cat << EOF  
Usage: 

bash create.sh --help/-h  [for help]
bash create.sh -o/--operation <enable disable status> -g/--group <aks-rg-name> -n/--name <aks-name>

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the AKS Http Routing
                                            enable or disable Or status

-g, -group,         --group                 AKS RG Name

-n, -name,          --name                  AKS Name

EOF
}

options=$(getopt -l "help::,operation:,group:,name:" -o "h::o:g:n:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-o|--operation)
    shift
    HTTP_ROUTING_OPERATION_TYPE=$1
    ;;  
-g|--group)
    shift
    AKS_RG_NAME=$1
    ;;  
-n|--name)
    shift
    AKS_NAME=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


funcHttpRoutingStatus () {
  ## Get the current AKS Http Routing Status
  echo "Get the current AKS Http Routing Status"

  AKS_HR_STATUS=$(az aks show \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --output json &>/dev/null | jq -r "select ( .addonProfiles.httpApplicationRouting.enabled == \"true\") | [ .addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName ] | @tsv" | wc -l)
  
  if [[ "$AKS_HR_STATUS" == "0" ]];
  then
    echo ""
    echo "Http Routing in not enabled in Cluster: $AKS_NAME in RG: $AKS_RG_NAME"
    echo ""
    echo "Exiting"
    exit 1
  fi

  AKS_HR_STATUS=$(az aks show \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --output json  &>/dev/null | jq -r " select ( .addonProfiles.httpApplicationRouting.enabled == "true") | [ .addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName ] | @tsv")
  echo ""
  echo "AKS Http Routing Status"
  echo "$AKS_HR_STATUS"
}



funcHttpRoutingAdd () {
  ## Add Http Routing Add-On
  echo "Add Http Routing Add-On"
  az aks enable-addons \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --addons http_application_routing \
    --debug
}



funcHttpRoutingRemove () {
  ## Remove Http Routing Add-On
  echo "Remove Http Routing Add-On"
  az aks disable-addons \
    --addons http_application_routing \
    --name $AKS_NAME \
    --resource-group $AKS_RG_NAME \
    --debug

}


funcHttpRoutingAksDNS () {
  ## Get AKS Cluster DNS Name
  echo "Get AKS Cluster DNS Name"
  AKS_SPECIFIC_DNS_ZONE=$(az aks show \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --output json  &>/dev/null | jq -r ".addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName" | wc -l)  

  if [[ "$AKS_SPECIFIC_DNS_ZONE" == "0"  ]]
  then
    ## If AKS has not Http Routing Defined then we need to exit
    echo "AKS has not Http Routing Defined then we need to exit"
    echo "Exiting..."
    exit 1

  fi

  ## If AKS has Http Routing enabled then...  
  AKS_SPECIFIC_DNS_ZONE=$(az aks show \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --output json  &>/dev/null | jq -r ".addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName")   

}


funcHttpRoutingSampleApp () {
  ## Apply sample APP
  echo "Apply sample APP"

cat <<EOF > http-routing-sample.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld
  template:
    metadata:
      labels:
        app: aks-helloworld
    spec:
      containers:
      - name: aks-helloworld
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Http Routing in AKS is Working! Yey!"
---
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: aks-helloworld
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aks-helloworld
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
spec:
  rules:
  - host: aks-helloworld.$AKS_SPECIFIC_DNS_ZONE
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: 
            name: aks-helloworld
            port: 
              number: 80

EOF


  kubectl apply -f http-routing-sample.yaml     

}


##########################
##
## Core Part
##
##########################

if [[ "$HTTP_ROUTING_OPERATION_TYPE" == "enable" ]]; 
then
   echo "Add Http Routing To AKS"
   funcHttpRoutingAdd
   echo "Get AKS Dns Details"
   funcHttpRoutingAksDNS
   echo "Deploy Sample APP"
   funcHttpRoutingSampleApp
elif [[ "$HTTP_ROUTING_OPERATION_TYPE" == "disable" ]];
then
  echo "Remove Http Routing To AKS"
  funcHttpRoutingRemove  
elif [[ "$HTTP_ROUTING_OPERATION_TYPE" == "status" ]];
then
  echo "Get AKS Http Routing Status"
  funcHttpRoutingStatus
else
  echo "No available option provided"
  exit 1
fi


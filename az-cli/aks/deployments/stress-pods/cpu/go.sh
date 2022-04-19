#!/bin/bash



showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -p/--pod <pod-name> -t/--tag <nodepool-instance-tag-namep-host-name> 

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-p, -pod,           --pod                   Define pod name

-t, -tag,           --tag                   Define, if we want, if defined, deploy pod in a
											specific nodepool instance          
EOF
}

options=$(getopt -l "help::,pod:,tag:" -o "h::p:t:" -a -- "$@")

eval set -- "$options"


while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;
-p|--pod)
    shift
    POD_NAME=$1
    ;;
-t|--tag)
    shift
    NP_INSTANCE_TAG_NAME=$1
    ;;
--)
    shift
    break
    exit 0
    ;;
esac
shift
done



funcHasTags () {
  ## Check if the TAG have beein provided 
  echo "Check if the TAG have being provided"
  if [[ -z "$NP_INSTANCE_TAG_NAME" ]];
  then
    echo "No Hostname Provided"
    HAS_HOSTNAME="0"
  else
    echo "Hostname Provided"
    HAS_HOSTNAME="1"
  fi
}


funcCheckNodeExistence () {
  if [[ "$HAS_HOSTNAME" == "1" ]];
  then 
    ## Check if hostname exist in current AKS cluster
    echo "Check if hostname exist in current AKS cluster"
    NPINSTANCE_EXIST=$(kubectl get nodes -l "kubernetes.io/hostname="$NP_INSTANCE_TAG_NAME | wc -l)

    if [[ "$NPINSTANCE_EXIST" == "0"  ]];
    then
      echo "$NP_INSTANCE_TAG_NAME does not exist in current AKS cluster"
      echo "Exiting..."
      exit 0
    fi
  fi  
}


funcCreateYaml () {
  ## Create Yaml to be Deployed
  echo "Create Yaml to be Deployed"
  
  if [[ "$HAS_HOSTNAME" == "1" ]];
  then
cat <<EOF > pod-cpu.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  containers:
  - image: typeoneg/stresstest-pod:v1 
    name: cpu-perf
    command: [ "sh", "-c", "sleep infinity" ]
  nodeSelector:
    kubernetes.io/os: linux
    kubernetes.io/hostname: $NP_INSTANCE_TAG_NAME
EOF
  else
cat <<EOF > pod-cpu.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  containers:
  - image: typeoneg/stresstest-pod:v1 
    name: cpu-perf
    command: [ "sh", "-c", "sleep infinity" ]
  nodeSelector:
    kubernetes.io/os: linux
EOF
  fi
}


funcDeployYaml () {
  ## Deploy Yaml
  echo "Deploy Yaml"
  kubectl apply -f pod-cpu.yaml  
}


################################
##
## Core
##
###############################

echo ""
echo "Process TAGS if Any"
funcHasTags 
echo ""
echo "If TAGS are there, check if hostname exists"
funcCheckNodeExistence
echo ""
echo "Create Yaml"
funcCreateYaml
echo ""
echo "Deploy Yaml"
funcDeployYaml

#!/bin/bash



showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -p/--pod <pod-name> -t/--tag <nodepool-instance-tag-namep-host-name> -s/storage <pvc-size-in-Gi> 

IMPORTANT: For PVC they are being dynamically created.


Install Pre-requisites JQ

-h, -help,          --help                  Display help

-p, -pod,           --pod                   Define pod name

-t, -tag,           --tag                   Define, if we want, if defined, deploy pod in a
                                            specific nodepool instance          

-s, -stor           --storage               Define, if we want, storage class size in GI. Examplei for 10G: 10

EOF
}

options=$(getopt -l "help::,pod:,tag:,storage:" -o "h::p:t:s:" -a -- "$@")

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
-s|--storage)
    shift
    PVC_STATIC_SIZE=$1
    ;;
--)
    shift
    break
    exit 0
    ;;
esac
shift
done


funcGetAKSInfraRG () {
   CURRENT_AKS=$(kubectl config current-context)
   AKS_INFRA_RG=$(az aks list -o json | jq -r ".[] | select ( .name == \"$CURRENT_AKS\") | [ .nodeResourceGroup] | @tsv")
}


funcCreateDisk () {
  
  DISK_ID=$(az disk create \
    --resource-group $AKS_INFRA_RG \
    --name "my$POD_NAMEdisk" \
    --size-gb $PVC_STATIC_SIZE \
    --query id 
    --output tsv)

}

funcHasPvc () {
  ## Check if PVC is desired
  echo "Check if PVC is desired"
  
  if [[ -z "$PVC_STATIC_SIZE" ]];
  then 
    echo "No PVC desired"
    HAS_PVC="0"
  else
    echo "Has PVC"
    HAS_PVC="1"
  fi
}


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
  
  if [[ "$HAS_HOSTNAME" == "1" ]] && [[ "$HAS_PVC" == "1" ]];
  then 

cat <<EOF > pod-disk.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  labels:
    purpose: perf
spec:
  containers:
  - image: typeoneg/stresstest-pod:v1 
    name: cpu-perf
    command: [ "sh", "-c", "sleep infinity" ]
    volumeMounts:
    - mountPath: "/mnt/azure"
      name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: azure-managed-disk
  nodeSelector:
    kubernetes.io/os: linux
    kubernetes.io/hostname: $NP_INSTANCE_TAG_NAME
EOF
    
  elif [[ "$HAS_HOSTNAME" == "0" ]] && [[ "$HAS_PVC" == "1" ]]; 
  then 

cat <<EOF > pod-disk.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  labels:
    purpose: perf
spec:
  containers:
  - image: typeoneg/stresstest-pod:v1 
    name: cpu-perf
    command: [ "sh", "-c", "sleep infinity" ]
    volumeMounts:
    - mountPath: "/mnt/azure"
      name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: azure-managed-disk
EOF

  elif [[ "$HAS_HOSTNAME" == "0" ]] && [[ "$HAS_PVC" == "0" ]]; 
  then 

cat <<EOF > pod-disk.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  labels:
    purpose: perf
spec:
  containers:
  - image: typeoneg/stresstest-pod:v1 
    name: cpu-perf
    command: [ "sh", "-c", "sleep infinity" ]
EOF

  else
    echo "Nothing was done...." 
  fi
}


funcDeployYaml () {
  ## Deploy Yaml
  echo "Deploy Yaml"
  kubectl apply -f pod-disk.yaml  
}


funcDeployPvc () {
  ## Remove Existent yaml
  echo "Remove Existent yaml"
  rm -rf pod-pvc.yaml

  ## Define PVC
  echo "Define PVC"
cat <<EOF > pod-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-managed-disk
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: $PVC_STATIC_SIZE
EOF
  
  ## Apply PVC
  echo "Apply PVC"
  kubectl apply -f pod-pvc.yaml

}


################################
##
## Core
##
###############################
echo ""
echo "Process PVC if Any"
funcHasPvc 
echo ""
echo "Deploy PVC if applicable"
if [[ "$HAS_PVC" == "1" ]];
then
   funcDeployPvc
fi
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

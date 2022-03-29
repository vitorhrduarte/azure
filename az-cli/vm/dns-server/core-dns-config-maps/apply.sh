##!/usr/bin/env bash


showHelp() {
cat << EOF  
Usage: 

bash apply.sh --help/-h  [for help]
bash apply.sh -f/--file <file-name>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-f, -file,          --file                  Input yaml file name

EOF
}



options=$(getopt -l "help::,file:" -o "h::f:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;
-f|--file)
    shift
    YAML_FILE_NAME=$1
    ;;
--)
    shift
    break
    exit 0
    ;;
esac
shift
done






getCoreDnsCustomConfigMap () {
    echo "Get Current Custom CoreDNS CM"
    kubectl -n kube-system describe cm coredns-custom
}


## Get Current Custom CoreDNS CM
getCoreDnsCustomConfigMap

## Apply CoreDNS ConfigMap
echo "Apply CoreDNS ConfigMap"
kubectl apply -f $YAML_FILE_NAME 

## Re-deploy CoreDNS pods 
echo "Re-deploy CoreDNS pods"
kubectl rollout restart -n kube-system deployment/coredns

## Get Current Custom CoreDNS CM
getCoreDnsCustomConfigMap

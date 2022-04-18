##!/usr/bin/env bash


## Linux SSH Port
SSH_PORT="22"


showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -p/--pip <linux-pip-name> -g/--group <vm-resourceGroup>

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-p, -pip,           --publicipname          PIP Name associated to the Linux VM         

-g, -rg,            --rg                    VM Resource Group  

EOF
}

options=$(getopt -l "help::,pip:,rg:" -o "h::g:p:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;
-p|--publicipname)
    shift
    VM_PIP=$1
    ;;
-g|--rg)
    shift
    VM_RG=$1
    ;;
--)
    shift
    break
    exit 0
    ;;
esac
shift
done



funcGetPIPinRG () {
  ## Get Linux PIP
  echo "Get Linux PIP"
  PIP=$(az network public-ip list \
    --output json | jq -r ".[] | select(( .resourceGroup == \"$VM_RG\") and (.name == \"$VM_PIP\")) | [ .ipAddress ] | @tsv")
}

funcTestAccessPIP () {
  ## Try the connection to PIP
  echo "Try the connection to PIP"
  if (nc -z -w 5 $PIP $SSH_PORT 2>&1 >/dev/null)
  then
    echo "Remote Access - OK"
    funcSshTo
  else
    echo "Remote Access - NOT OK"
    echo "Exiting..."
  fi 
}


funcSshTo () {
  ## Get the FingerPrint 
  echo "Get the FingerPrint"
  ssh-keygen -F $PIP >/dev/null

  ## Update the know_hosts
  echo "Update the know_hosts"
  ssh-keyscan -H $PIP >> ~/.ssh/known_hosts

  ## Do the SSH session
  echo "Do the SSH session"
  ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2 $GENERIC_ADMIN_USERNAME@$PIP -i $SSH_PRIV_KEY
}


## Get PIP
echo ""
echo "Get PIP"
funcGetPIPinRG
echo ""
funcTestAccessPIP



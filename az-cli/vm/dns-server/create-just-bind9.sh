##!/usr/bin/env bash
set -e
. ./params.sh

## Output Public IP of VM
echo "Public IP of VM is:"
VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $MAIN_VNET_RG \
  --query "{ip:[].ipAddress}" -o json | jq -r ".ip | @csv")

VM_PUBLIC_IP_PARSED=$(echo $VM_PUBLIC_IP | sed 's/"//g')
echo $VM_PUBLIC_IP_PARSED

BIND_CONFIG_FILE_NAME="named.conf.options"

echo "Cleaning up Bind Config File"
rm -rf $BIND_CONFIG_FILE_NAME

echo "Write to Bind Config File "
printf "
logging {
          channel "misc" {
                    file \"/var/log/named/misc.log\" versions 4 size 4m;
                    print-time YES;
                    print-severity YES;
                    print-category YES;
          };
  
          channel "query" {
                    file \"/var/log/named/query.log\" versions 4 size 4m;
                    print-time YES;
                    print-severity NO;
                    print-category NO;
          };
  
          category default {
                    "misc";
          };
  
          category queries {
                    "query";
          };
};


acl goodclients {
    localhost;
    $AKS_SUBNET_CIDR;
};

options {
        directory \"/var/cache/bind\";

        forwarders {
                $VM_BIND_FORWARDERS_01;
                $VM_BIND_FORWARDERS_02;
        };

        recursion yes;

        allow-query { goodclients; };

        dnssec-validation auto;

        auth-nxdomain no;    # conform to RFC1035
        listen-on-v6 { any; };
};
" >> $BIND_CONFIG_FILE_NAME



## Update DNS Server VM
echo "Update DNS Server VM and Install Bind9"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo apt update && sudo apt upgrade -y

## Install Bind9
echo "Install Bind9"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo apt install vim bind9 -y

## Setup Bind9
echo "Setup Bind9"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup

## Create Bind9 Logs folder
echo "Create Bind9 Logs folder"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo mkdir /var/log/named 

## Setup good permission in Bind9 Logs folder - change owner
echo "Setup good permission in Bind9 Logs folder - change owner"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo chown -R bind:bind /var/log/named 

## Setup good permission in Bind9 Logs folder - change permissions
echo "Setup good permission in Bind9 Logs folder - change permissions"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo chmod -R 775 /var/log/named

## Copy Bind Config file to DNS Server
echo "Copy Bind Config File to Remote DNS server"
scp -i $SSH_PRIV_KEY $BIND_CONFIG_FILE_NAME $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED:/tmp

## sudo cp options file to /etc/bind/
echo "Copy the Bind File to /etc/bind"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo "cp /tmp/$BIND_CONFIG_FILE_NAME /etc/bind"

## sudo systemctl stop bind9
echo "Stop Bind9"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo systemctl stop bind9

## sudo systemctl start bind9
echo "Start Bind9"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED sudo systemctl start bind9



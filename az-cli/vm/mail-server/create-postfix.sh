##!/usr/bin/env bash
set -e
. ./params.sh

## Output Public IP of VM
echo "Public IP of VM is:"
VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $AKS_MAIN_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$VM_MAIL_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv")
echo $VM_PUBLIC_IP

## Update Mail Server VM
echo "Update DNS Server VM"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt update && sudo apt upgrade -y

## Install Postfix
echo ""
echo "debconf-set-selections postfix/mailname"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo debconf-set-selections <<< "postfix postfix/mailname string mail-srv.snotfcp.com" 
echo ""
echo "debconf-set-selections postfix/mynetworks"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo debconf-set-selections <<< "postfix postfix/mynetworks  string  127.0.0.0/8 $AKS_MAIN_VNET_CIDR"
echo ""
echo "debconf-set-selections postfix/main_mailer_type"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"
echo ""
echo "Postfix"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt install postfix -y
echo ""
echo "Insert Mail Dir"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo postconf \"home_mailbox = maildir/\"
echo ""
echo "Restart Postfix"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo systemctl restart postfix
echo ""
echo "Create Mail Users"
echo "User: amail"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo useradd -r -u 150 -g mail -m -d /home/amail -s /sbin/nologin -c \"Virtual MailDir Handler\" amail
echo "User: bmail"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo useradd -r -u 151 -g mail -m -d /home/bmail -s /sbin/nologin -c \"Virtual MailDir Handler\" bmail
echo "Done!"

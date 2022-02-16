##!/usr/bin/env bash
set -e
. ./params.sh

if [[ $CREATE_POSTFIX -eq "1" && $CREATE_MAIL_SRV -eq "1" ]]; then
    echo "Create VM"
    bash create-mail-srv.sh
    bash create-postfix.sh
    echo ""
fi

if [[ $CREATE_POSTFIX -eq "1" && $CREATE_MAIL_SRV -eq "0" ]]; then
    echo "Setup Mail Server - Postfix"
    bash create-postfix.sh
fi


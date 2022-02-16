##!/usr/bin/env bash
set -e
. ./params.sh


if [[ $JUST_BIND -eq "0" && $ALL -eq "1" ]]; then
    echo "Create VM"
    bash create-all.sh
    echo ""
    echo "Setup Bind9 Server"
    bash create-just-bind9.sh
fi

if [[ $JUST_BIND -eq "1" && $ALL -eq "0" ]]; then
    echo "Setup Bind9"
    bash create-just-bind9.sh
fi


for i in {ccp1,ccp2,wknode1,wknode2,wknode3,ccplb,wknlb}; do ssh-keygen -f "/home/gits/.ssh/known_hosts" -R $i; done

for i in {cp01,wk1,wk2,wk3}; do ssh-keygen -f "/home/gits/.ssh/known_hosts" -R $i; done

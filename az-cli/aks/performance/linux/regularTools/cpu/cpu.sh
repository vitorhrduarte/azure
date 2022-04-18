


 ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | awk '$5*10>50*10' | awk '{print $1}' | xargs -I '{}' bash -c "pstree -als {}" | grep containerd-shim | awk '{print $5}' | uniq | xargs -I '{}' bash -c "crictl ps --no-trunc -p {} && echo "" && crictl pods --id {}"

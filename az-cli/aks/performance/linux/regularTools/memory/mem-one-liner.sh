ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | awk '$3>50' | awk '{print $1}' | xargs -I '{}' bash -c "pstree -als {}" | grep containerd-shim | awk '{print $5}' | uniq | xargs -I '{}' bash -c "crictl ps --no-trunc -p {} && echo "" && crictl pods --id {}"

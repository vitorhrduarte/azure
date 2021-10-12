## Access one pod

## Run
for i in $(ls /proc | grep '^[0-9]') ; do if [ -f /proc/"$i"/status ]; then cat /proc/"$i"/status | grep -w "Name\|NoNewPrivs\|Pid" ; echo ""; fi ; done

## The flag NoNewPrivs should be = 1 if the policy is enabled

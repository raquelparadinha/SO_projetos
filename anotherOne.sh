#!/bin/bash

declare -A netifList=()

netif_re='^[a-z]\w{1,14}$'
n=0
#echo `cat /sys/class/net`
for netif in /sys/class/net/*; do
    echo "$netif"
    if [[ $netif =~ $netif_re ]]; then
        netifList[$n]=$netif
    fi
    echo $n
    echo "${netifList[*]}"
    n=$((n + 1))
done
echo $netifList
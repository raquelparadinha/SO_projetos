
#!/bin/bash
# netbanda.sh
# Autor Fernando Dejano
 
INTERVALO="5"  # update dos intervalos em segundos
 
#if [ -z "$1" ]; then
#        echo
#        echo Sintaxe uso: $0 <Interface>
#        echo
#        echo Exemplo: $0 eth0
#        echo
#    echo Exemplo: $0 wlan0
#    echo
#    echo Mostra Banda em kbits/s
#        exit
#fi
 
IF=$1
puta=0
 
while [[ $puta -lt 5 ]] 
do
        R1=`cat /sys/class/net/$1/statistics/rx_bytes` # vem em bytes
        T1=`cat /sys/class/net/$1/statistics/tx_bytes` # vem em bytes
        TKBPS=`expr $R1 / 1024` # por em kilobytes
        RKBPS=`expr $T1 / 1024` # por em kilobytes
        echo "TX $1: $TKBPS kb/s RX $1: $RKBPS kb/s"
        let "puta+=1"
done
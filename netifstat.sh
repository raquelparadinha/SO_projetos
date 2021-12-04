#!/bin/bash

###############################################################################################################################
#                                               SO - Trabalho prático 1
#
#   Realizado por:
#       Ana Raquel Paradinha - NMec: 102491
#       Paulo Pinto - NMec: 103234
#
###############################################################################################################################

declare -A rx           # Array associativo que guarda os rx
declare -A tx           # Array associativo que guarda os tx        # O index corresponde ao nome da interface
declare -A trate        # Array associativo que guarda os trate     
declare -A rrate        # Array associativo que guarda os rrate
declare -A rx_last
declare -A tx_last
declare -A rx_total
declare -A tx_total

rexp='^[0-9]+(\.[0-9]*)?$'     # Verificar se o ultimo arg é um numero
name=""
number=0
turn=0                      # começa em 1 porque já conta com o argumento dos segundos, serve para ver se os argumentos estão bem colocados
ctrl=0
ord=0
exp=0
loop=0
col=1
reverse=""

# Lista as opções disponíveis 
options() {
    echo "-----------------------------------------------------------------------------------"
    echo "${@:0} -c [name] -b|-k|-m -p [number] -t|-r|-T|-R -v -l [seconds]"
    echo
    echo "OPÇÕES DISPONÍVEIS!"
    echo
    echo "    -c    : Selecionar as interfaces a analisar através de uma expressão regular"
    echo "    -p    : Defenir o número de interfaces a visualizar"
    echo "    -l    : Analisar as interfaces de s em s segundos"
    echo "    -v    : Fazer um sort reverso"
    echo "O último argumento tem de corresponder sempre ao número de segundos que pretende analisar."
    echo
    echo "Opções de unidades (usar apenas 1):"
    echo "    -b    : Valores em bytes (default)"
    echo "    -k    : Valores em Kilobytes"
    echo "    -m    : Valores em Megabytes"
    echo
    echo "Opções de ordenação (usar apenas 1):"
    echo "    -t    : Ordenar pelo TX"
    echo "    -r    : Ordenar pelo RX"
    echo "    -T    : Ordenar pelo TRATE"
    echo "    -R    : Ordenar pelo RRATE"
    echo "A ordenação default é alfabética e para cada opção é decrescente."
    echo "------------------------------------------------------------------------------------"
}

error_exit () {
    options
    exit 1
}

unit_exit () {
    if [[ $ctrl == 1 ]]; then 
        # Quando há mais que 1 argumento de unidades
        echo "ERRO: não é possivel usar -b, -k e -m ao mesmo tempo!"
        error_exit
    else 
        ctrl=1
    fi
}

sort_exit () {
    reverse="r"
    if [[ $ord == 1 ]]; then
        echo "Não é possivel usar -t,-r,-T e -R ao mesmo tempo!"
        error_exit
    else 
        ord=1
    fi
}

# Verifica que o argumento obrigatório está presente
if [[ $# == 0 ]]; then
    echo "ERRO: deve passar pelo menos um argumento (número de segundos a analisar)."
    error_exit
fi

# Verifica que o último argumento é o número de segundos
sec=${@: -1}
if ! [[ $sec =~ $rexp ]]; then # =~ serve para comparar a expressão regex e a outra coisa
    echo "ERRO: o último argumento tem de ser o número de segundos que pretende analisar."
    error_exit
fi

set -- "${@:1:$(($#-1))}"   #retira o último arg (sec) para não ser usado como arg das opções

# Tratamento das opções passadas como argumentos
while getopts ":c:bkmp:trTRvl" option; do    
    case $option in
    c) # Seleção das interfaces a visualizar através de uma expressão regular
        name=$OPTARG
        ;;
    b)
        unit_exit     # Unidade = Byte
        ;;
    k)
        unit_exit
        exp=1     # Unidade = KiloByte
        ;;
    m)
        unit_exit
        exp=2     # Unidade = MegaByte
        ;;
    p) # Número de interfaces a visualizar
        number=$OPTARG
        if [[ number =~ "^[0-9]+$" ]]; then
            echo "ERRO: o número de interfaces tem de ser um inteiro positivo."
            error_exit
        fi
        ;;
    t)
        sort_exit
        col=2
        ;;
    r)
        sort_exit
        col=3
        ;;
    T)
        sort_exit
        col=4
        ;;
    R)
        sort_exit
        col=5
        ;;
    v) #Ordenação reversa
        if [[ $reverse == "r" ]];  then
            reverse=""
        else
            reverse="r"
        fi
        ;;
    l) # Loop
        loop=1
        ;;
    :) # Argumento obrigatório em falta
        echo "ERRO: argumento em falta na opção -${OPTARG}!" 1>&2
        error_exit
        ;;
    *) #Passagem de argumentos inválidos
        echo "ERRO: opção inválida!"
        error_exit
        ;;
    esac
done

printData() {
    n=0
    un=$((1024 ** exp))
    for net in /sys/class/net/[[:alnum:]]*; do
        if [[ -r $net/statistics ]]; then
            FILE="$net"
            f="$(basename -- $FILE)"
            if ! [[ $name =~ ""  && $f =~ $name ]]; then   
                continue                                  
            fi               

            if [[ $turn == 0 ]]; then
                rx_bytes1=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') # está em bytes
                tx_bytes1=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') # está em bytes
                sleep $sec
            else
                rx_bytes1=rx_last[$f]
                tx_bytes1=tx_last[$f]
            fi

            rx_bytes2=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') #está em bytes
            tx_bytes2=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') #está em bytes
            
            rx[$f]=$((rx_bytes2 - rx_bytes1))
            tx[$f]=$((tx_bytes2 - tx_bytes1))

            rrate[$f]=$(bc <<< "scale=1;${rx[$f]}/$sec")
            trate[$f]=$(bc <<< "scale=1;${tx[$f]}/$sec")

            if [[ $loop == 1 ]]; then
                tx_total[$f]=$((tx_total[$f] + tx[$f]))
                rx_total[$f]=$((rx_total[$f] + rx[$f]))
                rx_last[$f]=$rx_bytes2
                tx_last[$f]=$tx_bytes2
            fi
            n=$((n + 1))
        fi
        if [ $n == $number ]; then  
            break
        fi
    done
    n=0
    for net in /sys/class/net/[[:alnum:]]*; do
        if [[ -r $net/statistics ]]; then
            FILE="$net"
            f="$(basename -- $FILE)"
            if ! [[ $name =~ ""  && $f =~ $name ]]; then   
                continue                                  
            fi              
            if [[ $loop == 1 ]]; then
                printf "%-12s %12s %12s %12s %12s %12s %12s\n" "$f" "$(bc <<< "scale=1; ${tx[$f]}/$un")" "$(bc <<< "scale=1; ${rx[$f]}/$un")" "$(bc <<< "scale=1;${trate[$f]}/$un")" "$(bc <<< "scale=1;${rrate[$f]}/$un")" "$(bc <<< "scale=1;${tx_total[$f]}/$un")" "$(bc <<< "scale=1;${rx_total[$f]}/$un")"
            else
                printf "%-12s %12s %12s %12s %12s\n" "$f" "$(bc <<< "scale=1; ${tx[$f]}/$un")" "$(bc <<< "scale=1; ${rx[$f]}/$un")" "$(bc <<< "scale=1;${trate[$f]}/$un")" "$(bc <<< "scale=1;${rrate[$f]}/$un")"
            fi
            n=$((n + 1))
        fi
        if [ $n == $number ]; then
            break
        fi
    done | sort -k$col$reverse
}
if [[ $loop == 1 ]]; then
    while true; do
        printf "%-12s %12s %12s %12s %12s %12s %12s\n" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT"
        printData
        turn=1
        echo ""
        sleep $sec
    done
else
    printf "%-12s %12s %12s %12s %12s\n" "NETIF" "TX" "RX" "TRATE" "RRATE"
    printData
fi
exit 0


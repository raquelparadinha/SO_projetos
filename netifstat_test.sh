#!/bin/bash

echo "...Ajuda por favor..."

declare -A optList      # Array associativo (usa strings como index) --> guarda os argumentos passados
declare -a names         # Array que guarda os nomes das interfaces de rede
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

# Lista as opções disponíveis 
options() {
    echo "-----------------------------------------------------------------------------------"
    echo "OPÇÃO INVÁLIDA!"
    echo "    -c          : Seleção de processos a utilizar através de uma expressão regular"
    echo "    -b          : Ver a opção em bytes, se não for escrita nenhuma das opções (-b;-k;-m) será esta a utilizada"
    echo "    -k          : Ver a opção em Kilobytes"
    echo "    -m          : Ver a opção em Megabytes"
    echo "Apenas pode ser usada uma das opções -b, -k, -m"
    echo "    -p          : Usado para defenir o número de interfaces a  visualisar" 
    echo "    -t          : Dar sort em relação ao TX"
    echo "    -r          : Dar sort em relação ao RX"
    echo "    -T          : Dar sort em relação ao TRATE"
    echo "    -R          : Dar sort em relação ao RRATE"
    echo "Não pode ser passado mais do que um argumento de ordenação em simultâneo (-t, -r, -T, -R)"
    echo "    -v          : Fazer um sort reverso"
    echo "    -l          : Script deve funcionar em loop de s em s segundos"
    echo "Último argumento: Número de segundos para a visualização"
    echo "------------------------------------------------------------------------------------"
}

erro_exit () {
    options
    exit 1
}

unit_exit () {
    if [[ $ctrl == 1 ]]; then 
        # Quando há mais que 1 argumento de unidades
        echo "ERRO: não é possivel usar -b, -k e -m ao mesmo tempo!"
        erro_exit
    fi
}

# Verifica que o argumento obrigatório está presente
if [[ $# == 0 ]]; then
    echo "ERRO: deve passar pelo menos um argumento (número de segundos para a visualização)."
    erro_exit
fi

# Verifica que o último argumento é o número de segundos
sec=${@: -1}
if ! [[ $sec =~ $rexp ]]; then # =~ serve para comparar a expressão regex e a outra coisa
    echo "ERRO: o último argumento tem de ser o número de segundos que pretende analisar."
    erro_exit
fi

set -- "${@:1:$(($#-1))}"

# Tratamento das opções passadas como argumentos
while getopts ":c:bkmp:trTRvl" option; do    
    case $option in
    c) # Seleção das interfaces a visualizar através de uma expressão regular
        name=$OPTARG
        ;;
    b)
        unit_exit     # Unidade = Byte
        ctrl=1
        ;;
    k)
        unit_exit
        exp=1     # Unidade = KiloByte
        ctrl=1
        ;;
    m)
        unit_exit
        exp=2     # Unidade = MegaByte
        ctrl=1
        ;;
    p) # Número de interfaces a visualizar
        number=$OPTARG
        if [[ number =~ "^[0-9]+$" ]]; then
            echo "ERRO: o número de interfaces deve ser um inteiro positivo."
            erro_exit
        fi
        ;;

    v) #Ordenação reversa

        ;;

    t | T | R | r)

        if [[ $ord = 1 ]]; then
            #Quando há mais que 1 argumento de ordenacao
            echo "Não é possivel usar -t,-T,-R ou -r ao mesmo tempo!"
            erro_exit
        else
            #Se algum argumento for de ordenacao ord=1
            ord=1
        fi
        ;;
    l) # Loop
        continue
        ;;
    :) # Argumento obrigatório em falta
        echo "ERRO: argumento em falta na opção -${OPTARG}!" 1>&2
        erro_exit
        ;;
    *) #Passagem de argumentos inválidos
        echo "ERRO: opção inválida!"
        erro_exit
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
            if ! [[ $name =~ ""  && $f =~ $name ]]; then    #Que estás a fazer? A ver se deixo a parte das opções melhor
                continue                                     #Parece boa ideia, queres ajuda? Tenta fazer outra parte se queres, acho que esta consigo
            fi                                               #Okidoki, o que falta, mesmo? Os sorts DEUUUU O queeeeeeeeeeeee? Esta merda do name ?para que serve?
                                                             #Pois, comecei a ver um video no youtube XD    é a cena do -c, mas mais clean, uuuuuuuuuh, és uma maquina <3
            names[$n]=$f

            if [[ turn -eq 0 ]]; then
                rx_bytes1=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') # está em bytes
                tx_bytes1=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') # está em bytes
                #echo "$rx_bytes1"
                sleep $sec
            else
                rx_bytes1=rx_last[$f]
                tx_bytes1=tx_last[$f]
            fi

            rx_bytes2=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') #está em bytes
            tx_bytes2=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') #está em bytes
            #echo "$rx_bytes1"
            #echo "$rx_bytes2"
            rx[$f]=$((rx_bytes2 - rx_bytes1))
            tx[$f]=$((tx_bytes2 - tx_bytes1))

            #echo "${rx[$f]}/$sec"
            rrate=$(bc <<< "scale=1;${rx[$f]}/$sec")
            rrate[$f]=$rrate

            trate=$(bc <<< "scale=1;${tx[$f]}/$sec")
            trate[$f]=$trate
            if [[ -v optList[l] ]]; then
                tx_total[$f]=$((tx_total[$f] + tx[$f]))
                rx_total[$f]=$((rx_total[$f] + rx[$f]))
                #echo "${tx_total}"
                #echo "${rx_total}"
                tx[$f]=$(bc <<< "scale=1; ${tx[$f]}/$un")
                rx[$f]=$(bc <<< "scale=1; ${rx[$f]}/$un")
                trate[$f]=$(bc <<< "scale=1;${trate[$f]}/$un")
                rrate[$f]=$(bc <<< "scale=1;${rrate[$f]}/$un")
                printf "%-12s %12s %12s %12s %12s %12s %12s\n" "$f" "${tx[$f]}" "${rx[$f]}" "${trate[$f]}" "${rrate[$f]}" "${tx_total[$f]}" "${rx_total[$f]}"
                rx_last[$f]=$rx_bytes2
                tx_last[$f]=$tx_bytes2
            else
                tx[$f]=$(bc <<< "scale=1; ${tx[$f]}/$un")
                rx[$f]=$(bc <<< "scale=1; ${rx[$f]}/$un")
                trate[$f]=$(bc <<< "scale=1;${trate[$f]}/$un")
                rrate[$f]=$(bc <<< "scale=1;${rrate[$f]}/$un")
                printf "%-12s %12s %12s %12s %12s\n" "$f" "${tx[$f]}" "${rx[$f]}" "${trate[$f]}" "${rrate[$f]}"
            fi
            n=$((n + 1))
        fi
        if [ $n == $number ]; then  
            break
        fi
    done
}
if [[ -v optList[l] ]]; then
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

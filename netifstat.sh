#!/bin/bash

# Acesso Pc: sop0506; mcsez
echo "...Ajuda por favor..."

declare -A optList      # Array associativo (usa strings como index) --> guarda os argumentos passados
declare -a name         # Array que guarda os nomes das interfaces de rede
declare -A rx           # Array associativo que guarda os rx
declare -A tx           # Array associativo que guarda os tx        # O index corresponde a06; mcsezsop05o nome da interface
declare -A trate        # Array associativo que guarda os trate     
declare -A rrate        # Array associativo que guarda os rrate

i=0
rexp='^[0-9]+(\.[0-9]*)?$'     # Verificar se o ultimo arg é um numero
netif_re='^[a-z]\w{1-14}$'     # Expressão regular que verifica o argumento passado a -c 

# Lista as opções disponíveis 
function options() {
    echo "-----------------------------------------------------------------------------------"
    echo "OPÇÃO INVÁLIDA!"
    echo "    -c          : Seleção de processos a utilizar através de uma expressão regular"
    echo "    -b          : Ver a opção em bytes"
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

# Verifica que o argumento obrigatório está presente
if [[ $# == 0 ]]; then
    echo "ERRO! Deve passar pelo menos um argumento (número de segundos para a visualização)."
    options
    exit 1
fi

# Verifica que o último argumento é o número de segundos
sec=${@: -1}
if !([[ $sec =~ $rexp ]]); then # =~serve para comparar a expressão regex e a outra coisa
    echo "ERRO! O último argumento tem de ser o número de segundos que pretende analisar."
    options
    exit 1
fi

# Tratamento das opções passadas como argumentos
while getopts "c:bkmp:trTRvl:" option; do

    # Adicionar ao array optList as opções passadas ao correr o netifstat.sh, caso existam adiciona as que são passadas, caso não, adiciona "none"
    if [[ -z "$OPTARG" ]]; then
        optList[$option]="none"
    else
        optList[$option]=${OPTARG}
    fi

    case $option in
    c) # Seleção das interfaces a visualizar através de uma expressão regular
        str=${optList['c']}
        if [[ $str == 'none' || ${str:0:1} == "-" || $str =~ $netif_re ]]; then
            echo "Argumento de '-c' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            options
            exit 1
        fi
        ;;
    b) # Visualizar em bytes

        ;;
    k) # Visualizar em Kilobytes

        ;;
    m) # Visualizar em Megabytes

        ;;
    p) # Número de interfaces a visualizar
        if ! [[ ${optList['p']} =~ $rexp ]]; then
            echo "Argumento de '-p' tem de ser um número ou foi usado sem '-' atrás da opção passada." >&2
            options
            exit 1
        fi
        ;;

    r) #Ordenação reversa

        ;;

    t | T | R | v)

        if [[ $i = 1 ]]; then
            #Quando há mais que 1 argumento de ordenacao
            options
            exit 1
        else
            #Se algum argumento for de ordenacao i=1
            i=1
        fi
        ;;

    *) #Passagem de argumentos inválidos
        options
        exit 1
        ;;
    esac

done


function printData() {
    printf "%-12s %12s %12s %12s %12s\n" "NETIF" "TX" "RX" "TRATE" "RRATE"

    n=0
    for net in /sys/class/net/[[:alnum:]]*; do
        if [[ -r $net/statistics ]]; then
            FILE="$net"
            f="$(basename -- $FILE)"
            name[$n]=$f

            rx_bytes=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') #está em bytes
            rx[$f]=$rx_bytes

            tx_bytes=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') #está em bytes
            tx[$f]=$tx_bytes

            rrate=$(bc <<< "scale=1;$rx_bytes/$sec")
            rrate[$f]=$rrate

            trate=$(bc <<< "scale=1;$tx_bytes/$sec")
            trate[$f]=$trate

            printf "%-12s %12s %12s %12s %12s\n" "$f" "${tx[$f]}" "${rx[$f]}" "${trate[$f]}" "${rrate[$f]}"

            n=$((n + 1))
        fi
    done
}
printData

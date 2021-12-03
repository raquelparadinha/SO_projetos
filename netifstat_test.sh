#!/bin/bash

echo "...Ajuda por favor..."

declare -A optList      # Array associativo (usa strings como index) --> guarda os argumentos passados
declare -a name         # Array que guarda os nomes das interfaces de rede
declare -A rx           # Array associativo que guarda os rx
declare -A tx           # Array associativo que guarda os tx        # O index corresponde ao nome da interface
declare -A trate        # Array associativo que guarda os trate     
declare -A rrate        # Array associativo que guarda os rrate

rexp='^[0-9]+(\.[0-9]*)?$'     # Verificar se o ultimo arg é um numero
netif_re='^[a-z]\w{1-14}$'     # Expressão regular que verifica o argumento passado a -c
nr_args=1

# Lista as opções disponíveis 
function options() {
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

# Verifica que o argumento obrigatório está presente
if [[ $# == 0 ]]; then
    echo "ERRO! Deve passar pelo menos um argumento (número de segundos para a visualização)."
    options
    exit 1
fi

# Verifica que o último argumento é o número de segundos
sec=${@: -1}
if !([[ $sec =~ $rexp ]]); then # =~ serve para comparar a expressão regex e a outra coisa
    echo "ERRO! O último argumento tem de ser o número de segundos que pretende analisar."
    options                                                                                                                         
    exit 1
fi

ord=0
un=3
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
        arg=${optList['c']}
        if [[ $arg == 'none' || ${arg:0:1} == "-" || $arg =~ $netif_re ]]; then
            echo "Argumento de '-c' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            options
            exit 1
        fi
        let "nr_args +=2"
        ;;
    b | k | m) # Unidades
        if [[ $un = 0 || $un = 1 || $un = 2 ]]; then 
            # Quando há mais que 1 argumento de unidades
            echo "ERRO! Não é possivel usar -b, -k ou -m ao mesmo tempo!"
            options
            exit 1
        elif [[ optList[k] ]]; then
            $un = 1     # Unidade = Kilobytes
        elif [[ optList[m] ]]; then 
            $un = 2     # Unidade = Megabyte
        else 
            $un = 0     # Unidade = Byte
        fi
        let "nr_args +=1"
        ;;
    p) # Número de interfaces a visualizar
        if ! [[ ${optList['p']} =~ $rexp ]]; then
            echo "Argumento de '-p' tem de ser um número ou foi usado sem '-' atrás da opção passada." >&2
            options
            exit 1
        fi
        let "nr_args +=2"
        ;;

    r) #Ordenação reversa

        let "nr_args +=2"
        ;;

    t | T | R | v)

        if [[ $ord = 1 ]]; then
            #Quando há mais que 1 argumento de ordenacao
            echo "Não é possivel usar -t,-T,-R ou -V ao mesmo tempo!"
            options
            exit 1
        else
            #Se algum argumento for de ordenacao ord=1
            ord=1
        fi
        let "nr_args +=1"
        ;;
    l) # Loop

        let "nr_args +=2"
        ;;
    *) #Passagem de argumentos inválidos
        options
        exit 1
        ;;
    esac

done
if ! [[ $nr_args == $# ]]; then
    echo "Reveja os argumentos colocados, não introduziu o número correto destes ou no lugar errado"
    options
    exit 1
fi


function printData() {
    printf "%-12s %12s %12s %12s %12s\n" "NETIF" "TX" "RX" "TRATE" "RRATE"

    n=0

    if ! [[ -v argOpt[p] ]]; then
        p=${#nameS[@]}
    #Nº de processos que queremos ver
    else
        p=${argOpt['p']}
    fi

    for net in /sys/class/net/[[:alnum:]]*; do
        if [[ -r $net/statistics ]]; then
            FILE="$net"
            f="$(basename -- $FILE)"
            #echo "${optList[*]}"
            if [[ -v optList[c] && ! $f =~ ${optList['c']} ]]; then
                continue
            fi
            name[$n]=$f
            #echo "$sec"

            rx_bytes1=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') # está em bytes
            tx_bytes1=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') # está em bytes

            sleep $sec

            rx_bytes2=$(cat $net/statistics/rx_bytes | grep -o -E '[0-9]+') #está em bytes
            tx_bytes2=$(cat $net/statistics/tx_bytes | grep -o -E '[0-9]+') #está em bytes
            #echo "$rx_bytes1"
            #echo "$rx_bytes2"
            rx[$f]=$((rx_bytes2 - rx_bytes1))
            tx[$f]=$((tx_bytes2 - tx_bytes1))

            echo "${rx[$f]}/$sec"
            rrate=$(bc <<< "scale=1;${rx[$f]}/$sec")
            rrate[$f]=$rrate

            trate=$(bc <<< "scale=1;${tx[$f]}/$sec")
            trate[$f]=$trate

            printf "%-12s %12s %12s %12s %12s\n" "$f" "${tx[$f]}" "${rx[$f]}" "${trate[$f]}" "${rrate[$f]}"

            n=$((n + 1))
        fi
    done
    if [[ -v argOpt[t] ]]; then
        #Ordenação da tabela pelo TX
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k2 | head -n $p
    elif [[ -v argOpt[r] ]]; then
        #Ordenação da tabela pelo RX
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k3 | head -n $p
    elif [[ -v argOpt[T] ]]; then
        #Ordenação da tabela pelo TRATE
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k4 | head -n $p
    elif [[ -v argOpt[R] ]]; then
        #Ordenação da tabela pelo RRATE
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k5 | head -n $p
    fi
}
printData

#!/bin/bash
echo "...Ajuda por favor..."

declare -A argList=()

function opcoes() {
    echo "-------------------------------------------------------------------------------------------------"
    echo "OPÇÃO INVÁLIDA!"
    echo "    -c          : Seleção de processos a utilizar através de uma expressão regular"
    echo "    -b          : Ver a opção em bytes"
    echo "    -k          : Ver a opção em Kilobytess"
    echo "    -m          : Ver a opção em Megabytes"
    echo "    -p          : Usado para defenir o número de interfaces a  visualisar" 
    echo "    -t          : Dar sort em relação ao TX"
    echo "    -r          : Dar sort em relação ao RX"
    echo "    -T          : Dar sort em relação ao TRATE"
    echo "    -R          : Dar sort em relação ao RRATE"
    echo "    -v          : Fazer um sort alfabético reverso"
    echo "    -l          : Script deve funcionar em loop de s em s segundos"
    echo "Último argumento: Tem de ser um número"
    echo "-------------------------------------------------------------------------------------------------"
}

#Tratamentos das opçoes passadas como argumentos
while getopts "c:bkmp:trTRvl:" option; do

    #Adicionar ao array argList as opcoes passadas ao correr o netifstat.sh, caso existam adiciona as que são passadas, caso não, adiciona "nada"
    if [[ -z "$OPTARG" ]]; then
        argList[$option]="nada"
    else
        argList[$option]=${OPTARG}
    fi

    case $option in
    c) #Seleção de processos a utilizar atraves de uma expressão regular
        str=${argList['c']}
        if [[ $str == 'nada' || ${str:0:1} == "-" || $str =~ $re ]]; then
            echo "Argumento de '-c' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            opcoes
            exit 1
        fi
        ;;
    b) #Ver a opção em bytes

        ;;
    k) #Ver a opção em Kilobytes

        ;;
    m) #Ver a opção em Megabytes

        ;;
    p) #Número de interfaces a visualizar
        if ! [[ ${argList['p']} =~ $re ]]; then
            echo "Argumento de '-p' tem de ser um número ou foi usado sem '-' atrás da opção passada." >&2
            opcoes
            exit 1
        fi
        ;;

    r) #Ordenação reversa

        ;;

    t | T | R | v)

        if [[ $i = 1 ]]; then
            #Quando há mais que 1 argumento de ordenacao
            opcoes
            exit 1
        else
            #Se algum argumento for de ordenacao i=1
            i=1
        fi
        ;;

    *) #Passagem de argumentos inválidos
        opcoes
        exit 1
        ;;
    esac

done

function printData() {
    printf "%-12s %12s %12s %12s %12s\n" "NETIF" "TX" "RX" "TRATE" "RRATE"
}
printData
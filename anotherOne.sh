t | T | R | r)
        reverse="r"
        if [[ $ord = 1 ]]; then
            #Quando há mais que 1 argumento de ordenacao
            echo "Não é possivel usar -t,-r,-T e -R ao mesmo tempo!"
            erro_exit
        else
            #Se algum argumento for de ordenacao ord=1
            ord=1
        fi
        if [[ $option == "t" ]]; then # Uso da opção -t.
            k=2 # Alterar a coluna 2 da impressão. Coluna dos valores de TX.
        fi
        if [[ $option == "r" ]]; then # Uso da opção -r.
            k=3 # Alterar a coluna 3 da impressão. Coluna dos valores de RX.
        fi
        if [[ $option == "T" ]]; then # Uso da opção -T.
            k=4 # Alterar a coluna 4 da impressão. Coluna dos valores de TRATE.
        fi
        if [[ $option == "R" ]]; then # Uso da opção -R.
            k=5 # Alterar a coluna 5 da impressão. Coluna dos valores de RRATE.
        fi
        ;;

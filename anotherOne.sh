b | k | m) # Unidades
        if [[ $ctrl -eq 1 ]]; then 
            # Quando há mais que 1 argumento de unidades
            echo "ERRO: não é possivel usar -b, -k e -m ao mesmo tempo!"
            erro_exit
        elif [[ -v optList[k] ]]; then
            exp=1     # Unidade = Kilobytes
            crtl=1
        elif [[ -v optList[m] ]]; then 
            exp=2     # Unidade = Megabyte
            crtl=1
        else 
            exp=0     # Unidade = Byte
            crtl=1
        fi
        ;;
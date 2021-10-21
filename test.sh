#!/bin/bash

NC="\033[0m"
BOLD="\033[1m"
ULINE="\033[4m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"

DIR=../push_swap

function test_leaks()
{
    printf "$DIR "
    if [ $# -le 12 ]
    then
        args=""
        for var in "$@"
        do
            args+="${var} "
        done
        printf "%-30s" "$args"
    elif [ $# -lt 100 ]
    then
        printf "%-30s" "stack size < 100"
    elif [ $# -eq 100 ]
    then
        printf "%-30s" "stack size = 100"
    elif [ $# -eq 500 ]
    then
        printf "%-30s" "stack size = 500"
    else
        exit
    fi
    res=""
    res=`valgrind --leak-check=full --show-leak-kinds=all $DIR "$1" 2>&1 | grep "no leaks are possible"`
    if [ -n "$res" ]
    then
        printf "${GREEN}%-7s" "[OK]"
    else
        printf "${RED}%-7s" "[KO]"
    fi
}

function test_sort()
{
    res=0
    res=`$DIR $@ | ./checker_linux $@ 2>&1`
    if [ "$res" != "KO" ]
    then
        printf "${GREEN}%-6s" "[OK]"
    else
        printf "${RED}%-6s" "[KO]"
    fi
    printf "${NC}"
}

function test_score_3n
{
    res=0
    res=`$DIR $@ | wc -l`
    if [ $res -le 3 ]
    then
        printf "${GREEN}%s%s" "[$res]" "[OK]"
    else
        printf "${RED}%6s" "[$res][KO]"
    fi
    printf "${NC}"
}

function test_score_5n
{
    res=0
    res=`$DIR $@ | wc -l`
    if [ $res -le 12 ]
    then
        printf "${GREEN}%s%s" "[$res]" "[OK]"
    else
        printf "${RED}%s" "[$res][KO]"
    fi
    printf "${NC}"
}

function test_score_100n
{
    res=0
    res=`$DIR $@ | wc -l`
    if [ $res -le 700 ]
    then
        printf "${GREEN}%5s" "[$res][5]"
    elif [ $res -le 900 ]
    then
        printf "${BLUE}%5s" "[$res][4]"
    elif [ $res -le 1100 ]
    then
        printf "${BLUE}%5s" "[$res][3]"
    elif [ $res -le 1300 ]
    then
        printf "${RED}%5s" "[$res][2]"
    else
        printf "${RED}%5s" "[$res][1]"
    fi
    printf "${NC}"
}

function test_score_500n
{
    res=""
    res=`$DIR $@ | wc -l`
    if [ $res -le 5500 ]
    then
        printf "${GREEN}%5s" "[$res][5]"
    elif [ $res -le 7000 ]
    then
        printf "${BLUE}%5s" "[$res][4]"
    elif [ $res -le 8500 ]
    then
        printf "${BLUE}%5s" "[$res][3]"
    elif [ $res -le 10000 ]
    then
        printf "${RED}%5s" "[$res][2]"
    else
        printf "${RED}%5s" "[$res][1]"
    fi
    printf "${NC}"

}

function test_score()
{
    res=""
    res=`$DIR $@ | wc -l`
    if [ $# -le 3 ]
    then
        test_score_3n $@
    elif [ $# -le 5 ]
    then
        test_score_5n $@
    elif [ $# -le 100 ]
    then
        test_score_100n $@
    else
        test_score_500n $@
    fi
    printf ${NC}
}

function test_error()
{
    test_leaks $@
    ret=""
    ret=$($DIR $@ 2<&1 | grep Error )
    if [ -n "$ret" ]
    then
        printf "${GREEN}%3s" "[OK]"
    else
        printf "${RED}%3s" "[KO]"
    fi
    printf "\n${NC}"    
}

function all_test()
{
    test_leaks $@ 
    test_sort  $@
    test_score $@
    printf "\n"
}

function test_norminette()
{
    printf "%-20s" "Norminette"
    norm=$(norminette ../ | grep Error)
    if [ -z "$norm" ]
    then
        printf "${GREEN}[OK]"
    else
        printf "${RED}[KO]"
    fi
    printf "\n${NC}"
}

function test_forbidden_functions()
{
    printf "%-20s" "Forbidden function"
    functions=$(nm -D $DIR | awk '{$1=$1};1' | sed -n -e '/^U/p' | awk -F ' ' '{ print $2 }')
    for function in $functions
    do
        if [ "$function" = "exit" ] || [ "$function" = "free" ] || [ "$function" = "malloc" ] 
        then
            check_function=0
        elif [ "$function" = "write" ] || [ "$function" = "read" ] || [ "$function" = "__stack_chk_fail" ] || [ "$function" = "__libc_start_main" ]
        then
            check_function=0
        else
            check_function=1
            break
        fi
    done
    if [ $check_function = 0 ]
    then
            printf "${GREEN}[OK]"
    else
            printf "${RED}[KO]"
    fi
    printf "\n${NC}"
}

function test_compilation()
{
    printf "%-20s" "Makefile"

    if [ ! -f "../Makefile" ]
    then
        printf "${RED}[KO]\n"
        exit
    fi

    make fclean -C ../ > /dev/null 2>&1 
    make -C ../ > /dev/null 2>&1 
    if [ $? != 0 ]
    then
        printf "${RED}[KO]\n"
        exit
    fi

    ret=$(make -C ../ | grep "Nothing to be done for 'all'")
    if [ -z "$ret" ]
    then
        printf "${RED}[KO]\n"
        return 
    fi
    make clean -C ../ > /dev/null 2>&1 
    if [ $? != 0 ]
    then
        printf "${RED}[KO]\n"
        return
    fi

    make -C ../ > /dev/null 2>&1 
    make fclean -C ../ > /dev/null 2>&1 
    if [ $? != 0 ]
    then
        printf "${RED}[KO]\n"
        return
    fi

    make -C ../ > /dev/null 2>&1 
    make re -C ../ > /dev/null 2>&1 
    if [ $? != 0 ]
    then
        printf "${RED}[KO]\n"
        return
    fi

    make fclean -C ../ > /dev/null 2>&1 
    make all -C ../ > /dev/null 2>&1 
    if [ $? != 0 ]
    then
        printf "${RED}[KO]\n"
        return
    fi
    printf "${GREEN}[OK]\n${NC}"
    chmod 777 $DIR
}

clear

test_compilation

test_norminette
test_forbidden_functions

printf "${YELLOW}%63s\n${NC}" "[LEAKS][SORT][SCORE]"

all_test 
all_test 1
all_test 1 2 
all_test 1 2 3
printf "\n"

all_test 2 1 3
all_test 3 2 1
all_test 3 1 2
all_test 1 3 2
all_test 2 3 1
printf "\n"

all_test 1 2 3 4
all_test -80 45 20 12 3
all_test 10 45 4 2 2147483647
all_test 10 45 4 2 -2147483648
all_test 0
all_test -0
printf "\n"

params=$(shuf -z -i 0-500 -n 5| tr '\0' ' ')
all_test $params
params=$(shuf -z -i 0-500 -n 5| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 5| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 5| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 5| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 5| tr '\0' ' ')
all_test $params 
printf "\n"

params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params
params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 100| tr '\0' ' ')
all_test $params 
printf "\n"

params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params
params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params 
params=$(shuf -z -i 0-500 -n 500| tr '\0' ' ')
all_test $params 
printf "\n"


printf "\n"
printf "${YELLOW}%56s\n${NC}" "[LEAKS][ERROR]"

test_error x
test_error x x x
test_error 10 x
test_error x 10
test_error 1 2 3 4 10a
test_error 4 2 3 4 10a
test_error 0 -0
test_error 1 1
test_error 00-8000 10 45
test_error --4
test_error 10 45 4 2 2147483650
test_error /dev/urandom
test_error /dev/null
test_error -0

make fclean -C $DIR > /dev/null 2>&1

#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
display_welcome() {
    clear
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${GREEN}Welcome to Mukuvi Bash Shell Terminal${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "Type 'help' for a list of available commands"
    echo -e "Type 'exit' to quit the shell"
}


show_help() {
    echo -e "\n${YELLOW}Available Commands:${NC}"
    echo -e "  - pwd\t\t: Print current working directory"
    echo -e "  - ls\t\t: List directory contents"
    echo -e "  - date\t: Show current date and time"
    echo -e "  - whoami\t: Display current user"
    echo -e "  - clear\t: Clear the screen"
    echo -e "  - help\t: Show this help menu"
    echo -e "  - exit\t: Exit the shell"
}


main_shell() {
    local exit_shell=false

    while [ "$exit_shell" = false ]; do
       
        echo -en "${RED}bash-shell>${NC} "
        read -r command


        case "$command" in
            "pwd")
                pwd
                ;;
            "ls")
                ls
                ;;
            "date")
                date
                ;;
            "whoami")
                whoami
                ;;
            "clear")
                clear
                display_welcome
                ;;
            "help")
                show_help
                ;;
            "exit")
                echo -e "${YELLOW}Exiting shell. Goodbye!${NC}"
                exit_shell=true
                ;;
            *)
                if [ -n "$command" ]; then
                    echo -e "${RED}Command not recognized: $command${NC}"
                fi
                ;;
        esac
    done
}

display_welcome
main_shell
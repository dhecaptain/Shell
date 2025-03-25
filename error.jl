function print_string(s)
    print(s)
end

function read_input()
    return strip(readline())
end

function shell_loop()
    welcome_msg = "\033[34m==========================================\033[0m\n" *
                  "\033[32mWelcome to Mukuvi Shell Terminal\033[0m\n" *
                  "\033[34m==========================================\033[0m\n" *
                  "Type \"help\" for commands, \"exit\" to quit\n"
    prompt = "\033[31mjulia-shell> \033[0m"
    help_msg = "\nAvailable Commands:\n  - help   : Show this help menu\n  - exit   : Exit the shell\n  - hello  : Display a greeting\n"
    hello_msg = "Hello from Julia Shell!\n"
    error_msg = "Command not recognized\n"
    exit_msg = "Goodbye!\n"

    print_string(welcome_msg)
    
    while true
        print_string(prompt)
        input = read_input()

        if input == "exit"
            print_string(exit_msg)
            break
        elseif input == "help"
            print_string(help_msg)
        elseif input == "hello"
            print_string(hello_msg)
        else
            print_string(error_msg)
        end
    end
end

shell_loop()

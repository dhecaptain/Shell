U0 PrintString(Str s) {
    Print(s);
}

Str ReadInput() {
    Str input;
    Print("> ");
    input = GetStr();
    return input;
}

U0 ShellLoop() {
    Str welcome_msg = "Welcome to Mukuvi Shell Terminal\nType 'help' for commands, 'exit' to quit\n";
    Str help_msg = "\nAvailable Commands:\n  - help   : Show this help menu\n  - exit   : Exit the shell\n  - hello  : Display a greeting\n";
    Str hello_msg = "Hello from HolyC Shell!\n";
    Str error_msg = "Command not recognized\n";
    Str exit_msg = "Goodbye!\n";
    Str input;

    PrintString(welcome_msg);
    
    while (1) {
        input = ReadInput();

        if (StrCmp(input, "exit") == 0) {
            PrintString(exit_msg);
            Break;
        } else if (StrCmp(input, "help") == 0) {
            PrintString(help_msg);
        } else if (StrCmp(input, "hello") == 0) {
            PrintString(hello_msg);
        } else {
            PrintString(error_msg);
        }
    }
}

ShellLoop();

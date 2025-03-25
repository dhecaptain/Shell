section .data
    prompt db 10, 27, '[31mbash-shell> ', 27, '[0m', 0
    welcome_msg db 27, '[34m==========================================', 27, '[0m', 10
               db 27, '[32mWelcome to Mukuvi Shell Terminal', 27, '[0m', 10
               db 27, '[34m==========================================', 27, '[0m', 10
               db 'Type "help" for commands, "exit" to quit', 10, 0
    help_msg db 10, 'Available Commands:', 10
             db '  - help   : Show this help menu', 10
             db '  - exit   : Exit the shell', 10
             db '  - hello  : Display a greeting', 10, 0
    hello_msg db 'Hello from Assembly Shell!', 10, 0
    error_msg db 'Command not recognized', 10, 0
    exit_msg db 'Goodbye!', 10, 0

section .bss
    input resb 256

section .text
    global _start

%macro syscall 1-3
    %if %0 == 1
        mov rax, %1
        syscall
    %elif %0 == 2
        mov rax, %1
        mov rdi, %2
        syscall
    %else
        mov rax, %1
        mov rdi, %2
        mov rsi, %3
        syscall
    %endif
%endmacro

print_string:
    push rdi
    xor rcx, rcx
.strlen_loop:
    cmp byte [rdi + rcx], 0
    je .strlen_done
    inc rcx
    jmp .strlen_loop
.strlen_done:
    pop rdi
    syscall 1, 1, rdi, rcx
    ret

read_input:
    mov byte [input], 0
    syscall 0, 0, input, 256
    mov rdi, input
    call remove_newline
    ret

remove_newline:
    xor rcx, rcx
.loop:
    cmp byte [rdi + rcx], 10
    je .replace
    cmp byte [rdi + rcx], 0
    je .done
    inc rcx
    jmp .loop
.replace:
    mov byte [rdi + rcx], 0
.done:
    ret

compare_command:
    push rsi
    push rdi
.compare_loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, 0
    je .check_end
    cmp bl, 0
    je .check_end
    cmp al, bl
    jne .not_equal
    inc rsi
    inc rdi
    jmp .compare_loop
.check_end:
    cmp al, 0
    jne .not_equal
    cmp bl, 0
    jne .not_equal
    pop rdi
    pop rsi
    mov rax, 1
    ret
.not_equal:
    pop rdi
    pop rsi
    xor rax, rax
    ret

_start:
    mov rdi, welcome_msg
    call print_string

.shell_loop:
    mov rdi, prompt
    call print_string
    call read_input
    mov rsi, input
    mov rdi, exit_cmd
    call compare_command
    cmp rax, 1
    je .exit_shell
    mov rsi, input
    mov rdi, help_cmd
    call compare_command
    cmp rax, 1
    je .show_help
    mov rsi, input
    mov rdi, hello_cmd
    call compare_command
    cmp rax, 1
    je .show_hello
    mov rdi, error_msg
    call print_string
    jmp .shell_loop

.show_help:
    mov rdi, help_msg
    call print_string
    jmp .shell_loop

.show_hello:
    mov rdi, hello_msg
    call print_string
    jmp .shell_loop

.exit_shell:
    mov rdi, exit_msg
    call print_string
    syscall 60, 0

exit_cmd db 'exit', 0
help_cmd db 'help', 0
hello_cmd db 'hello', 0

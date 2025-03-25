section .data
    prompt db 'mukuvi(asm)> ', 0
    welcome db 'Mukuvi Process Monitor v1.0', 0xA
            db 'Type "list" to show processes', 0xA
            db 'Type "run" to execute C program', 0xA
            db 'Type "bash" to run shell command', 0xA
            db 'Type "exit" to quit', 0xA, 0
    list_cmd db 'ps -eo pid,comm,args', 0
    c_compile db 'gcc -o /tmp/mukuvi_prog', 0
    c_run db '/tmp/mukuvi_prog', 0
    error_msg db 'Error executing command', 0xA, 0
    newline db 0xA, 0
    buffer times 256 db 0
    proc_list times 4096 db 0
    child_pid dd 0

section .text
    global _start

_start:
    mov eax, welcome
    call print_string

main_loop:
    mov eax, prompt
    call print_string

    mov eax, buffer
    mov ebx, 256
    call read_string

    mov esi, buffer
    cmp byte [esi], 'e'
    je check_exit
    cmp byte [esi], 'l'
    je handle_list
    cmp byte [esi], 'r'
    je handle_run
    cmp byte [esi], 'b'
    je handle_bash
    jmp main_loop

check_exit:
    mov eax, buffer
    mov ebx, exit_cmd
    call compare_strings
    je exit_program
    jmp main_loop

handle_list:
    mov eax, buffer
    mov ebx, list_cmd_str
    call compare_strings
    je list_processes
    jmp main_loop

handle_run:
    mov eax, buffer
    mov ebx, run_cmd_str
    call compare_strings
    je run_c_program
    jmp main_loop

handle_bash:
    mov eax, buffer
    mov ebx, bash_cmd_str
    call compare_strings
    je run_bash_command
    jmp main_loop

list_processes:
    mov eax, list_cmd
    call execute_system
    jmp main_loop

run_c_program:
    mov eax, c_compile
    call execute_system
    cmp eax, 0
    jl compile_error
    mov eax, c_run
    call execute_system
    jmp main_loop

compile_error:
    mov eax, compile_err_msg
    call print_string
    jmp main_loop

run_bash_command:
    mov esi, buffer
    add esi, 5
    mov eax, esi
    call execute_system
    jmp main_loop

execute_system:
    push eax
    mov eax, 2
    xor ebx, ebx
    xor ecx, ecx
    int 0x80
    cmp eax, 0
    jl system_error
    mov [child_pid], eax
    mov eax, 7
    mov ebx, [child_pid]
    xor ecx, ecx
    xor edx, edx
    int 0x80
    mov eax, 0
    ret

system_error:
    mov eax, error_msg
    call print_string
    mov eax, -1
    ret

print_string:
    push eax
    push ebx
    push ecx
    push edx
    mov ecx, eax
    call strlen
    mov edx, eax
    mov eax, 4
    mov ebx, 1
    int 0x80
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

read_string:
    push eax
    push ebx
    push ecx
    push edx
    mov ecx, eax
    mov edx, ebx
    mov eax, 3
    mov ebx, 0
    int 0x80
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

strlen:
    push ebx
    mov ebx, eax
.nextchar:
    cmp byte [eax], 0
    jz .finished
    inc eax
    jmp .nextchar
.finished:
    sub eax, ebx
    pop ebx
    ret

compare_strings:
    push eax
    push ebx
.compare_loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc esi
    inc edi
    jmp .compare_loop
.not_equal:
    clc
    jmp .done
.equal:
    stc
.done:
    pop ebx
    pop eax
    ret

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80

section .bss
    exit_cmd db 'exit', 0
    list_cmd_str db 'list', 0
    run_cmd_str db 'run', 0
    bash_cmd_str db 'bash', 0
    compile_err_msg db 'Compilation failed', 0xA, 0
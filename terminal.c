#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <time.h>

#ifdef _WIN32
    #include <windows.h>
    #define CLEAR_SCREEN "cls"
    #define LIST_COMMAND "dir"
    #define GET_USER getenv("USERNAME")
#else
    #include <pwd.h>
    #define CLEAR_SCREEN "clear"
    #define LIST_COMMAND "ls"
    #define GET_USER getpwuid(getuid())->pw_name
#endif

#define RED     "\x1b[31m"
#define GREEN   "\x1b[32m"
#define YELLOW  "\x1b[33m"
#define BLUE    "\x1b[34m"
#define RESET   "\x1b[0m"

#define MAX_COMMAND_LENGTH 100

void display_welcome();
void show_help();
void execute_command(char* command);

void main_shell() {
    char command[MAX_COMMAND_LENGTH];

    while (1) {
        printf(RED "bash-shell> " RESET);
        if (fgets(command, sizeof(command), stdin) == NULL) {
            break;
        }
        command[strcspn(command, "\n")] = 0; 

        if (strcmp(command, "exit") == 0) {
            printf(YELLOW "Exiting shell. Goodbye!\n" RESET);
            break;
        }
        execute_command(command);
    }
}


void display_welcome() {
    system(CLEAR_SCREEN);
    printf(BLUE "===========================================\n" RESET);
    printf(GREEN "Welcome to Mukuvi Shell Terminal\n" RESET);
    printf(BLUE "===========================================\n" RESET);
    printf("Type 'help' for available commands\n");
    printf("Type 'exit' to quit\n");
}

void show_help() {
    printf(YELLOW "\nAvailable Commands:\n" RESET);
    printf("  - pwd\t\t: Show current directory\n");
    printf("  - ls\t\t: List directory contents\n");
    printf("  - date\t: Show current date/time\n");
    printf("  - whoami\t: Display current user\n");
    printf("  - clear\t: Clear the screen\n");
    printf("  - help\t: Show help\n");
    printf("  - exit\t: Exit the shell\n");
}

void execute_command(char* command) {
    if (strcmp(command, "pwd") == 0) {
        char cwd[1024];
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            printf("%s\n", cwd);
        } else {
            perror("getcwd() error");
        }
    }
    else if (strcmp(command, "ls") == 0) {
        system(LIST_COMMAND);
    }
    else if (strcmp(command, "date") == 0) {
        time_t now = time(NULL);
        printf("%s", ctime(&now));
    }
    else if (strcmp(command, "whoami") == 0) {
        char *user = GET_USER;
        if (user) {
            printf("%s\n", user);
        } else {
            printf("Unknown User\n");
        }
    }
    else if (strcmp(command, "clear") == 0) {
        system(CLEAR_SCREEN);
        display_welcome();
    }
    else if (strcmp(command, "help") == 0) {
        show_help();
    }
    else if (strlen(command) > 0) {
        printf(RED "Command not recognized: %s\n" RESET, command);
    }
}

int main() {
    display_welcome();
    main_shell();
    return 0;
}

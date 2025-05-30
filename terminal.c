#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <dirent.h>
#include <time.h>

#define MAX_COMMAND_LENGTH 256
#define MAX_ARGS 64
#define MAX_PLUGINS 16

#define COLOR_RED     "\x1b[31m"
#define COLOR_GREEN   "\x1b[32m"
#define COLOR_YELLOW  "\x1b[33m"
#define COLOR_BLUE    "\x1b[34m"
#define COLOR_RESET   "\x1b[0m"

typedef struct {
    char name[64];
    void (*function)(int argc, char **argv);
    char description[256];
} Plugin;

typedef struct {
    char prompt[64];
    int debug_mode;
    Plugin plugins[MAX_PLUGINS];
    int plugin_count;
} MukuviTerminal;

void initialize_terminal(MukuviTerminal *terminal);
void display_welcome();
void handle_command(MukuviTerminal *terminal, char *input);
void register_plugins(MukuviTerminal *terminal);
void plugin_help(int argc, char **argv);
void plugin_system_info(int argc, char **argv);
void plugin_process_list(int argc, char **argv);
void plugin_network_scan(int argc, char **argv);
void plugin_file_explorer(int argc, char **argv);

void signal_handler(int signum) {
    printf("\n%sReceived interrupt signal. Use 'exit' to quit.%s\n", COLOR_YELLOW, COLOR_RESET);
}

void initialize_terminal(MukuviTerminal *terminal) {
    strcpy(terminal->prompt, COLOR_GREEN "mukuvi> " COLOR_RESET);
    terminal->debug_mode = 0;
    terminal->plugin_count = 0;
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    register_plugins(terminal);
}

void register_plugins(MukuviTerminal *terminal) {
    strcpy(terminal->plugins[terminal->plugin_count].name, "help");
    terminal->plugins[terminal->plugin_count].function = plugin_help;
    strcpy(terminal->plugins[terminal->plugin_count].description, "Display available commands");
    terminal->plugin_count++;

    strcpy(terminal->plugins[terminal->plugin_count].name, "sysinfo");
    terminal->plugins[terminal->plugin_count].function = plugin_system_info;
    strcpy(terminal->plugins[terminal->plugin_count].description, "Display system information");
    terminal->plugin_count++;

    strcpy(terminal->plugins[terminal->plugin_count].name, "ps");
    terminal->plugins[terminal->plugin_count].function = plugin_process_list;
    strcpy(terminal->plugins[terminal->plugin_count].description, "List running processes");
    terminal->plugin_count++;

    strcpy(terminal->plugins[terminal->plugin_count].name, "netscan");
    terminal->plugins[terminal->plugin_count].function = plugin_network_scan;
    strcpy(terminal->plugins[terminal->plugin_count].description, "Perform basic network scan");
    terminal->plugin_count++;

    strcpy(terminal->plugins[terminal->plugin_count].name, "files");
    terminal->plugins[terminal->plugin_count].function = plugin_file_explorer;
    strcpy(terminal->plugins[terminal->plugin_count].description, "Explore current directory");
    terminal->plugin_count++;
}

void plugin_help(int argc, char **argv) {
    printf("%sMukuvi Terminal - Available Plugins:%s\n", COLOR_BLUE, COLOR_RESET);
    printf("-----------------------------\n");
    MukuviTerminal *terminal = malloc(sizeof(MukuviTerminal));
    initialize_terminal(terminal);
    for (int i = 0; i < terminal->plugin_count; i++) {
        printf("%s%-10s%s: %s\n", COLOR_GREEN, terminal->plugins[i].name, COLOR_RESET, terminal->plugins[i].description);
    }
    free(terminal);
}

void plugin_system_info(int argc, char **argv) {
    FILE *fp;
    char path[1035];
    printf("%sSystem Information:%s\n", COLOR_BLUE, COLOR_RESET);
    printf("%sCPU Info:%s\n", COLOR_GREEN, COLOR_RESET);
    fp = popen("cat /proc/cpuinfo | grep 'model name' | uniq", "r");
    if (fp == NULL) return;
    while (fgets(path, sizeof(path), fp) != NULL) printf("%s", path);
    pclose(fp);
    printf("\n%sMemory Info:%s\n", COLOR_GREEN, COLOR_RESET);
    fp = popen("free -h", "r");
    if (fp == NULL) return;
    while (fgets(path, sizeof(path), fp) != NULL) printf("%s", path);
    pclose(fp);
}

void plugin_process_list(int argc, char **argv) {
    FILE *fp;
    char path[1035];
    printf("%sRunning Processes:%s\n", COLOR_BLUE, COLOR_RESET);
    fp = popen("ps aux | head -n 10", "r");
    if (fp == NULL) return;
    while (fgets(path, sizeof(path), fp) != NULL) printf("%s", path);
    pclose(fp);
}

void plugin_network_scan(int argc, char **argv) {
    FILE *fp;
    char path[1035];
    printf("%sNetwork Interfaces:%s\n", COLOR_BLUE, COLOR_RESET);
    fp = popen("ip addr", "r");
    if (fp == NULL) return;
    while (fgets(path, sizeof(path), fp) != NULL) printf("%s", path);
    pclose(fp);
}

void plugin_file_explorer(int argc, char **argv) {
    DIR *dir;
    struct dirent *entry;
    printf("%sDirectory Contents:%s\n", COLOR_BLUE, COLOR_RESET);
    dir = opendir(".");
    if (dir == NULL) return;
    while ((entry = readdir(dir)) != NULL) printf("%s\n", entry->d_name);
    closedir(dir);
}

void handle_command(MukuviTerminal *terminal, char *input) {
    char *args[MAX_ARGS];
    int arg_count = 0;
    char *token = strtok(input, " \n");
    while (token != NULL && arg_count < MAX_ARGS - 1) {
        args[arg_count++] = token;
        token = strtok(NULL, " \n");
    }
    args[arg_count] = NULL;
    if (strcmp(args[0], "exit") == 0) {
        printf("%sExiting Mukuvi Terminal%s\n", COLOR_YELLOW, COLOR_RESET);
        exit(0);
    }
    for (int i = 0; i < terminal->plugin_count; i++) {
        if (strcmp(args[0], terminal->plugins[i].name) == 0) {
            terminal->plugins[i].function(arg_count, args);
            return;
        }
    }
    printf("%sUnknown command: %s%s\n", COLOR_RED, args[0], COLOR_RESET);
}

void display_welcome() {
    printf("%s", COLOR_BLUE);
    printf("========================================\n");
    printf("  Welcome to Mukuvi Terminal v1.0.0    \n");
    printf("========================================\n");
    printf("%s", COLOR_RESET);
    printf("Type 'help' to see available commands\n");
}

int main() {
    MukuviTerminal terminal;
    char input[MAX_COMMAND_LENGTH];
    initialize_terminal(&terminal);
    display_welcome();
    while (1) {
        printf("%s", terminal.prompt);
        if (fgets(input, sizeof(input), stdin) == NULL) break;
        if (input[0] == '\n') continue;
        handle_command(&terminal, input);
    }
    return 0;
}
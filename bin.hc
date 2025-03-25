#define MAX_COMMAND_LENGTH 256
#define MAX_ARGS 64
#define MAX_PLUGINS 16

U0 PrintRed(Str msg) {
    "$FG,4$%s$FG$", msg;
}

U0 PrintGreen(Str msg) {
    "$FG,2$%s$FG$", msg;
}

U0 PrintBlue(Str msg) {
    "$FG,1$%s$FG$", msg;
}

class MukuviPlugin {
    Str name;
    U0 (*function)(I64 argc, Str *argv);
    Str description;
};

class MukuviTerminal {
    Str prompt;
    I64 debug_mode;
    MukuviPlugin *plugins[MAX_PLUGINS];
    I64 plugin_count;
};

MukuviTerminal *gTerminal;

U0 PluginHelp(I64 argc, Str *argv);
U0 PluginSystemInfo(I64 argc, Str *argv);
U0 PluginProcessList(I64 argc, Str *argv);
U0 PluginResourceMonitor(I64 argc, Str *argv);
U0 PluginFileExplorer(I64 argc, Str *argv);

U0 InitializeTerminal(MukuviTerminal *terminal) {
    terminal->prompt = "mukuvi> ";
    terminal->debug_mode = 0;
    terminal->plugin_count = 0;

    for (I64 i = 0; i < MAX_PLUGINS; i++) {
        terminal->plugins[i] = CAlloc(sizeof(MukuviPlugin));
    }

    {
        terminal->plugins[terminal->plugin_count]->name = "help";
        terminal->plugins[terminal->plugin_count]->function = &PluginHelp;
        terminal->plugins[terminal->plugin_count]->description = "Display available commands";
        terminal->plugin_count++;

        terminal->plugins[terminal->plugin_count]->name = "sysinfo";
        terminal->plugins[terminal->plugin_count]->function = &PluginSystemInfo;
        terminal->plugins[terminal->plugin_count]->description = "Display system information";
        terminal->plugin_count++;

        terminal->plugins[terminal->plugin_count]->name = "ps";
        terminal->plugins[terminal->plugin_count]->function = &PluginProcessList;
        terminal->plugins[terminal->plugin_count]->description = "List running processes";
        terminal->plugin_count++;

        terminal->plugins[terminal->plugin_count]->name = "resources";
        terminal->plugins[terminal->plugin_count]->function = &PluginResourceMonitor;
        terminal->plugins[terminal->plugin_count]->description = "Monitor system resources";
        terminal->plugin_count++;

        terminal->plugins[terminal->plugin_count]->name = "files";
        terminal->plugins[terminal->plugin_count]->function = &PluginFileExplorer;
        terminal->plugins[terminal->plugin_count]->description = "Explore file system";
        terminal->plugin_count++;
    }
}

U0 PluginHelp(I64 argc, Str *argv) {
    PrintBlue("Mukuvi Terminal - Available Plugins\n");
    PrintBlue("-----------------------------\n");

    for (I64 i = 0; i < gTerminal->plugin_count; i++) {
        PrintGreen(gTerminal->plugins[i]->name);
        "$FG$: %s\n", gTerminal->plugins[i]->description;
    }
}

U0 PluginSystemInfo(I64 argc, Str *argv) {
    PrintBlue("System Information\n");
    PrintBlue("------------------\n");

    "$FG,2$Memory Information:$FG$\n";
    "Total Memory: %d KB\n", MemMax;
    "Free Memory: %d KB\n", MemAvail;

    "$FG,2$CPU Information:$FG$\n";
    "Processor: TempleOS HolyC Kernel\n";
    "Clock Speed: %d MHz\n", GetCPUHz;
}

U0 PluginProcessList(I64 argc, Str *argv) {
    PrintBlue("Running Processes\n");
    PrintBlue("----------------\n");
    "Total Processes: %d\n", TaskGetNum;
    
    for (CTask *task = sys_task_list; task; task = task->next) {
        "%s (PID: %d)\n", task->task_name, task->task_num;
    }
}

U0 PluginResourceMonitor(I64 argc, Str *argv) {
    PrintBlue("System Resource Monitor\n");
    PrintBlue("----------------------\n");

    "$FG,2$Memory Usage:$FG$\n";
    "Total: %d KB\n", MemMax;
    "Used: %d KB\n", MemMax - MemAvail;
    "Free: %d KB\n", MemAvail;

    "$FG,2$CPU Load:$FG$\n";
    "Current Load: Approximately %d%%\n", (GetCPULoad * 100) / GetCPUHz;
}

U0 PluginFileExplorer(I64 argc, Str *argv) {
    PrintBlue("File System Explorer\n");
    PrintBlue("-------------------\n");

    CDirEntry *entry = FilesFind("/");
    while (entry) {
        "%s\n", entry->name;
        entry = entry->next;
    }
}

U0 HandleCommand(MukuviTerminal *terminal, Str input) {
    Str argv[MAX_ARGS];
    I64 argc = 0;

    Str token = StrFirstOcc(input, " ");
    while (token && argc < MAX_ARGS - 1) {
        argv[argc++] = token;
        token = StrFirstOcc(token + 1, " ");
    }
    argv[argc] = NULL;

    if (StrCmp(argv[0], "exit") == 0) {
        PrintGreen("Exiting Mukuvi Terminal\n");
        Exit;
    }

    for (I64 i = 0; i < terminal->plugin_count; i++) {
        if (StrCmp(argv[0], terminal->plugins[i]->name) == 0) {
            terminal->plugins[i]->function(argc, argv);
            return;
        }
    }

    PrintRed("Unknown command: %s\n", argv[0]);
}

U0 DisplayWelcome() {
    PrintBlue("========================================\n");
    PrintBlue("  Welcome to Mukuvi Terminal v1.0.0    \n");
    PrintBlue("========================================\n");
    "Type 'help' for available commands\n";
}

U0 MukuviTerminalMain() {
    gTerminal = CAlloc(sizeof(MukuviTerminal));
    InitializeTerminal(gTerminal);
    DisplayWelcome();
    Str input[MAX_COMMAND_LENGTH];

    while (TRUE) {
        "%s", gTerminal->prompt;
        GetS(input, MAX_COMMAND_LENGTH);
        if (StrLen(input) == 0)
            continue;
        HandleCommand(gTerminal, input);
    }
}

U0 Main() {
    MukuviTerminalMain;
}
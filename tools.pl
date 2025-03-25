% Mukuvi Terminal in Prolog

:- module(mukuvi_terminal, [
    start_terminal/0,
    process_command/1,
    load_plugins/1
]).

:- use_module(library(http/http_open)).
:- use_module(library(filesex)).
:- use_module(library(readutil)).

% Dynamic predicates for plugin management
:- dynamic plugin/3.

% Color definitions
color(red, '\033[31m').
color(green, '\033[32m').
color(yellow, '\033[33m').
color(blue, '\033[34m').
color(reset, '\033[0m').

% Terminal configuration
terminal_version('1.0.0').

% Plugin structure predicate
plugin_info(Name, Description, Handler) :-
    plugin(Name, Description, Handler).

% Initialize plugins
initialize_plugins :-
    assertz(plugin(help, 'Display available commands', help_handler)),
    assertz(plugin(system_info, 'Show system information', system_info_handler)),
    assertz(plugin(network_scan, 'Perform network scanning', network_scan_handler)),
    assertz(plugin(process_list, 'List running processes', process_list_handler)),
    assertz(plugin(file_explore, 'Explore file system', file_explore_handler)).

% Help handler
help_handler(_) :-
    color(blue, Blue),
    color(green, Green),
    color(reset, Reset),
    format('~wMukuvi Terminal - Available Plugins~w~n', [Blue, Reset]),
    format('-----------------------------~n'),
    findall(Name, plugin(Name, Description, _), Plugins),
    print_plugins(Plugins).

print_plugins([]).
print_plugins([Plugin|Rest]) :-
    plugin(Plugin, Description, _),
    color(green, Green),
    color(reset, Reset),
    format('~w~w~w: ~w~n', [Green, Plugin, Reset, Description]),
    print_plugins(Rest).

% System information handler
system_info_handler(_) :-
    color(blue, Blue),
    color(green, Green),
    color(reset, Reset),
    format('~wSystem Information~w~n', [Blue, Reset]),
    format('------------------~n'),
    
    % CPU Information
    (catch(shell('lscpu | grep "Model name"', _), _, fail) -> true ; 
        format('Could not retrieve CPU info~n')),
    
    % Memory Information
    (catch(shell('free -h'), _), _ -> true ; 
        format('Could not retrieve memory info~n')).

% Network scan handler
network_scan_handler(_) :-
    color(blue, Blue),
    color(green, Green),
    color(reset, Reset),
    format('~wNetwork Scan~w~n', [Blue, Reset]),
    format('------------~n'),
    
    % Perform network scan
    (catch(shell('ip addr'), _, fail) -> true ; 
        format('Network scan failed~n')).

% Process list handler
process_list_handler(_) :-
    color(blue, Blue),
    color(green, Green),
    color(reset, Reset),
    format('~wRunning Processes~w~n', [Blue, Reset]),
    format('----------------~n'),
    
    % List top processes
    (catch(shell('ps aux | head -n 10'), _, fail) -> true ; 
        format('Process list retrieval failed~n')).

% File exploration handler
file_explore_handler(_) :-
    color(blue, Blue),
    color(green, Green),
    color(reset, Reset),
    format('~wFile System Explorer~w~n', [Blue, Reset]),
    format('-------------------~n'),
    
    % Current directory listing
    current_directory(Dir),
    format('Current Directory: ~w~n', [Dir]),
    (catch(shell('ls -la'), _, fail) -> true ; 
        format('File listing failed~n')).

% Command processing
process_command(Command) :-
    % Trim whitespace
    string_trim(Command, TrimmedCommand),
    
    % Exit condition
    (TrimmedCommand == 'exit' -> 
        color(yellow, Yellow),
        color(reset, Reset),
        format('~wExiting Mukuvi Terminal~w~n', [Yellow, Reset]),
        halt
    ;
        % Plugin matching
        split_string(TrimmedCommand, " ", " ", [PluginName|Args]),
        (plugin(PluginName, _, Handler) ->
            Handler(Args)
        ;
            color(red, Red),
            color(reset, Reset),
            format('~wUnknown command: ~w~w~n', [Red, PluginName, Reset])
        )
    ).

% Read user input
read_input(Command) :-
    color(green, Green),
    color(reset, Reset),
    format('~wmukuvi> ~w', [Green, Reset]),
    read_line_to_string(user_input, Command).

% Terminal main loop
terminal_loop :-
    read_input(Command),
    (Command == end_of_file -> 
        true 
    ;
        process_command(Command),
        terminal_loop
    ).

% Display welcome message
display_welcome :-
    terminal_version(Version),
    color(blue, Blue),
    color(green, Green),
    color(reset, Reset),
    format('~w========================================~w~n', [Blue, Reset]),
    format('  Welcome to Mukuvi Terminal v~w~n', [Version]),
    format('~w========================================~w~n', [Blue, Reset]),
    format('Type "help" to see available commands~n').

% Start terminal
start_terminal :-
    initialize_plugins,
    display_welcome,
    terminal_loop.

% Main entry point
:- initialization(start_terminal, main).
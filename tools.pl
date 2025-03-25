:- module(mukuvi_terminal, [start_terminal/0]).

:- use_module(library(readutil)).
:- use_module(library(socket)).

:- dynamic plugin/3.
:- dynamic connection/1.

color(red, '\033[31m').
color(green, '\033[32m').
color(yellow, '\033[33m').
color(blue, '\033[34m').
color(reset, '\033[0m').

terminal_version('1.0.1').

initialize_plugins :-
    assertz(plugin(help, 'Display commands', help_handler)),
    assertz(plugin(connect, 'Connect to C terminal', connect_handler)),
    assertz(plugin(listen, 'Start server', listen_handler)).

help_handler(_) :-
    color(blue, Blue),
    color(reset, Reset),
    format('~wMukuvi Terminal~w~n', [Blue, Reset]),
    findall(Name, plugin(Name, Description, _), Plugins),
    print_plugins(Plugins).

print_plugins([]).
print_plugins([Plugin|Rest]) :-
    plugin(Plugin, Description, _),
    color(green, Green),
    color(reset, Reset),
    format('~w~w~w: ~w~n', [Green, Plugin, Reset, Description]),
    print_plugins(Rest).

connect_handler([Host, PortStr]) :-
    catch(
        (atom_number(PortStr, Port),
        tcp_connect(Host:Port, Stream, [type(text)]),
        assertz(connection(Stream)),
        color(green, Green),
        color(reset, Reset),
        format('~wConnected to ~w:~w~w~n', [Green, Host, Port, Reset])),
        _,
        (color(red, Red),
        color(reset, Reset),
        format('~wConnection failed~w~n', [Red, Reset]))).

listen_handler([PortStr]) :-
    catch(
        (atom_number(PortStr, Port),
        tcp_bind(Port, Socket),
        tcp_listen(Socket, 5),
        color(green, Green),
        color(reset, Reset),
        format('~wListening on port ~w~w~n', [Green, Port, Reset]),
        accept_connections(Socket)),
        _,
        (color(red, Red),
        color(reset, Reset),
        format('~wFailed to start server~w~n', [Red, Reset])).

accept_connections(Socket) :-
    tcp_accept(Socket, Client, _),
    tcp_open_socket(Client, In, Out),
    assertz(connection(Out)),
    thread_create(handle_client(In, Out), _),
    accept_connections(Socket).

handle_client(In, Out) :-
    read_line_to_string(In, Command),
    (Command == end_of_file -> 
        close(In),
        close(Out),
        retract(connection(Out))
    ;
        process_remote(Command),
        handle_client(In, Out)).

process_remote(Command) :-
    string_trim(Command, TrimmedCommand),
    (TrimmedCommand == "exit" -> true
    ;
        split_string(TrimmedCommand, " ", " ", [PluginName|Args]),
        (plugin(PluginName, _, Handler) ->
            Handler(Args)
        ;
            color(red, Red),
            color(reset, Reset),
            format('~wUnknown command~w~n', [Red, Reset])
        )
    ).

process_command(Command) :-
    string_trim(Command, TrimmedCommand),
    (TrimmedCommand == "exit" -> 
        color(yellow, Yellow),
        color(reset, Reset),
        format('~wExiting~w~n', [Yellow, Reset]),
        halt
    ;
        split_string(TrimmedCommand, " ", " ", [PluginName|Args]),
        (plugin(PluginName, _, Handler) ->
            Handler(Args)
        ;
            color(red, Red),
            color(reset, Reset),
            format('~wUnknown command~w~n', [Red, Reset])
        )
    ).

read_input(Command) :-
    color(green, Green),
    color(reset, Reset),
    format('~wmukuvi> ~w', [Green, Reset]),
    read_line_to_string(user_input, Command).

terminal_loop :-
    read_input(Command),
    (Command == end_of_file -> true
    ;
        process_command(Command),
        terminal_loop
    ).

display_welcome :-
    terminal_version(Version),
    color(blue, Blue),
    color(reset, Reset),
    format('~wMukuvi Terminal v~w~w~n', [Blue, Version, Reset]).

start_terminal :-
    initialize_plugins,
    display_welcome,
    terminal_loop.

:- initialization(start_terminal, main).
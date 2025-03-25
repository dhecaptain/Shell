module MukuviErrorCapture

using Sockets
using Distributed
using Process

const ERROR_CAPTURE_PORT = 9090
const MAX_ERROR_LENGTH = 4096
const PROMPT = "mukuvi(julia)> "

mutable struct ErrorData
    timestamp::DateTime
    source::String
    error_type::String
    message::String
    stacktrace::String
end

mutable struct TerminalSession
    errors::Vector{ErrorData}
    bash_pid::Union{Int, Nothing}
    c_program::Union{String, Nothing}
    socket_server::Union{TCPServer, Nothing}
end

function new_session()
    TerminalSession([], nothing, nothing, nothing)
end

function capture_bash_errors(session::TerminalSession, cmd::String)
    try
        session.bash_pid = run(pipeline(`bash -c "$cmd"`, stderr=stderr), wait=false).pid
        true
    catch e
        push!(session.errors, ErrorData(now(), "bash", "execution", sprint(showerror, e), ""))
        false
    end
end

function compile_c_program(session::TerminalSession, source_path::String)
    try
        compile_cmd = `gcc -o $(tempname()) $source_path`
        run(compile_cmd)
        session.c_program = replace(compile_cmd.exec[3], ".c" => "")
        true
    catch e
        push!(session.errors, ErrorData(now(), "c", "compilation", sprint(showerror, e), ""))
        false
    end
end

function run_c_program(session::TerminalSession, args::String="")
    isnothing(session.c_program) && return false
    try
        run_cmd = `$(session.c_program) $args`
        proc = run(pipeline(run_cmd, stderr=stderr), wait=false)
        sleep(0.1)
        if !process_running(proc)
            exit_code = proc.exitcode
            exit_code != 0 && push!(session.errors, ErrorData(now(), "c", "runtime", "Exit code $exit_code", ""))
        end
        true
    catch e
        push!(session.errors, ErrorData(now(), "c", "execution", sprint(showerror, e), ""))
        false
    end
end

function start_error_server(session::TerminalSession)
    try
        server = listen(ERROR_CAPTURE_PORT)
        session.socket_server = server
        @async begin
            while isopen(server)
                conn = accept(server)
                data = read(conn, MAX_ERROR_LENGTH)
                push!(session.errors, ErrorData(now(), "remote", "socket", String(data), ""))
                close(conn)
            end
        end
        true
    catch e
        push!(session.errors, ErrorData(now(), "system", "server", sprint(showerror, e), ""))
        false
    end
end

function format_error(error::ErrorData)
    ts = Dates.format(error.timestamp, "HH:MM:SS")
    """
    [$ts] $(error.source) - $(error.error_type)
    Message: $(error.message)
    $(isempty(error.stacktrace) ? "" : "Stacktrace:\n$(error.stacktrace)")
    """
end

function show_errors(session::TerminalSession)
    if isempty(session.errors)
        println("No errors captured")
    else
        println("\nCaptured Errors:")
        for err in session.errors
            println(format_error(err))
        end
    end
end

function process_command(session::TerminalSession, input::String)
    input = strip(input)
    isempty(input) && return true

    if startswith(input, "!")
        cmd = chop(input, head=1, tail=0)
        capture_bash_errors(session, cmd)
    elseif startswith(input, "c ")
        source = chop(input, head=2, tail=0)
        compile_c_program(session, source) && run_c_program(session)
    elseif input == "run"
        !isnothing(session.c_program) && run_c_program(session)
    elseif input == "errors"
        show_errors(session)
    elseif input == "clear"
        session.errors = []
    elseif input == "server"
        start_error_server(session)
    elseif input in ["exit", "quit"]
        return false
    else
        try
            Core.eval(Main, Meta.parse(input))
        catch e
            st = sprint(stacktrace, catch_backtrace())
            push!(session.errors, ErrorData(now(), "julia", "runtime", sprint(showerror, e), st))
        end
    end
    true
end

function run_terminal()
    session = new_session()
    println("Mukuvi Error Capture Terminal")
    println("Commands: !<bash>, c <file>, run, errors, clear, server, exit")

    while true
        print(PROMPT)
        input = readline()
        isempty(input) && continue
        process_command(session, input) || break
    end

    println("Closing Mukuvi Terminal")
end

export run_terminal

end

using .MukuviErrorCapture
MukuviErrorCapture.run_terminal()
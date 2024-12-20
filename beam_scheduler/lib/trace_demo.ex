defmodule TraceDemo do
  @moduledoc """
  Demonstration of using the modern tracing approach as documented in:
  https://www.erlang.org/doc/apps/kernel/trace

  Each function below:
    1. Starts a tracer process.
    2. Creates a trace session using `:trace.session_create/3`.
    3. Sets a process-level trace on `self()` with the given trace flags.
    4. Executes some code intended to trigger the traced events.
    5. Destroys the session.

  Note: The documentation does not provide detailed examples for every flag.
  Here, we follow the same approach as the provided documentation snippet,
  applying each flag individually and calling known functions or actions that
  can produce relevant trace events. Actual output may depend on runtime conditions.
  """

  # This function spawns a tracer process that prints received trace events
  def start_tracer do
    spawn(fn ->
      loop = fn f ->
        receive do
          msg ->
            IO.inspect(msg, label: "Trace event")
            f.(f)
        end
      end
      loop.(loop)
    end)
  end

  # Helper to create a session and set tracing on the current process
  def setup_session(flags) do
    tracer = start_tracer()
    session = :trace.session_create(:my_session, tracer, [])
    # Enable tracing on the current process
    :trace.process(session, :all, true, flags)
    {session, tracer}
  end

  # Helper to clean up the session
  def teardown_session(session) do
    :trace.session_destroy(session)
  end

  # Helper function to call something (like lists:seq/2) to produce call events.
  def trigger_call do
    :lists.seq(1, 5)
  end

  # Helper function to send and receive messages
  def trigger_message_send_and_receive do
    send(self(), :hello)
    receive do
      _ -> :ok
    end
  end

  # Helper function to spawn a short-lived process (for exiting)
  def trigger_process_exit do
    spawn(fn -> :ok end)
  end

  # ---------------------------------------------------------------------------
  # Demonstrations for each trace info flag (one per function)
  # ---------------------------------------------------------------------------

  # call: Trace when the process calls a function
  def demo_call do
    {session, _tracer} = setup_session([:call])
    require IEx; IEx.pry
    trigger_call()
    teardown_session(session)
  end

  # return_to: Trace when returning to a function (useful with :call)
  def demo_return_to do
    {session, _tracer} = setup_session([:call, :return_to])
    trigger_call()
    teardown_session(session)
  end

  # exiting: Trace when a process exits
  def demo_exiting do
    {session, _tracer} = setup_session([:exiting])
    trigger_process_exit()
    teardown_session(session)
  end

  # send: Trace when the process sends a message
  def demo_send do
    {session, _tracer} = setup_session([:send])
    send(self(), :test_msg)
    # Just receive the message to clear it out
    receive do
      _ -> :ok
    end
    teardown_session(session)
  end

  # receive: Trace when the process receives a message
  def demo_receive do
    {session, _tracer} = setup_session([:'receive'])
    # Triggering a receive event by sending a message then receiving it
    send(self(), :hello)
    receive do
      _ -> :ok
    end
    teardown_session(session)
  end

  # running: Trace when a traced entity starts running on a scheduler
  def demo_running do
    {session, _tracer} = setup_session([:running])
    # Calling a function may schedule the process
    trigger_call()
    teardown_session(session)
  end

  # running_procs: Like running, but only for processes
  def demo_running_procs do
    {session, _tracer} = setup_session([:running_procs])
    trigger_call()
    teardown_session(session)
  end

  # running_ports: Like running, but only for ports (not demonstrated extensively)
  def demo_running_ports do
    {session, _tracer} = setup_session([:ports, :running_ports])
    # Interacting with a port could trigger this, for example opening a file
    # Actual events depend on internal scheduling of ports
    File.open("demo_file", [:write]) |> case do
      {:ok, file} -> IO.binwrite(file, "hello"); File.close(file)
      _ -> :ok
    end
    teardown_session(session)
  end

  # arity: Shows function arity when combined with call
  def demo_arity do
    {session, _tracer} = setup_session([:call, :arity])
    trigger_call()
    teardown_session(session)
  end

  # garbage_collection: Trace garbage collection events
  def demo_garbage_collection do
    {session, _tracer} = setup_session([:garbage_collection])
    # Force GC by creating and discarding data
    _ = :lists.seq(1, 1_000_000)
    :erlang.garbage_collect(self())
    teardown_session(session)
  end

  # timestamp: Adds timestamps to trace messages
  def demo_timestamp do
    {session, _tracer} = setup_session([:call, :timestamp])
    trigger_call()
    teardown_session(session)
  end

  # monotonic_timestamp: Use monotonic time for timestamps
  def demo_monotonic_timestamp do
    {session, _tracer} = setup_session([:call, :monotonic_timestamp])
    trigger_call()
    teardown_session(session)
  end

  # strict_monotonic_timestamp: Strictly monotonic timestamps
  def demo_strict_monotonic_timestamp do
    {session, _tracer} = setup_session([:call, :strict_monotonic_timestamp])
    trigger_call()
    teardown_session(session)
  end

  # set_on_spawn: When a traced process spawns another, the child is also traced
  def demo_set_on_spawn do
    {session, _tracer} = setup_session([:call, :set_on_spawn])
    spawn(fn -> trigger_call() end)
    teardown_session(session)
  end

  # set_on_first_spawn: Like set_on_spawn, but only the first spawned process is traced
  def demo_set_on_first_spawn do
    {session, _tracer} = setup_session([:call, :set_on_first_spawn])
    spawn(fn -> trigger_call() end)
    spawn(fn -> trigger_call() end) # This second one may not be traced
    teardown_session(session)
  end

  # set_on_link: When a traced process links to another, that process is traced
  def demo_set_on_link do
    {session, _tracer} = setup_session([:call, :set_on_link])
    pid = spawn(fn -> trigger_call() end)
    Process.link(pid)
    teardown_session(session)
  end

  # set_on_first_link: Like set_on_link, but only for the first linked process
  def demo_set_on_first_link do
    {session, _tracer} = setup_session([:call, :set_on_first_link])
    pid1 = spawn(fn -> trigger_call() end)
    Process.link(pid1)
    pid2 = spawn(fn -> trigger_call() end)
    Process.link(pid2) # May not propagate tracing
    teardown_session(session)
  end

  # silent: Suppress default formatting of trace messages
  def demo_silent do
    {session, _tracer} = setup_session([:call, :silent])
    trigger_call()
    teardown_session(session)
  end
end

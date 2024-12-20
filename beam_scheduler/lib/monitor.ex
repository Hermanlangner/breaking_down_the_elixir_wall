defmodule A do
  def o, do: :observer.start()
  def g, do: BeamScheduler.Monitor.start_link()
  def s, do: spawn(fn -> Enum.sum(1..10000); IO.puts("Hello from spawned process") end)
end

defmodule T do

  def t do
    spawn(fn ->
      # Define a recursive loop to continuously receive and print messages
      receive_loop = fn receive_loop ->
        receive do
          msg ->
            IO.inspect(msg, label: "Trace event")
            receive_loop.(receive_loop)
        end
      end
      receive_loop.(receive_loop)
    end)
  end

  def s(tracer) do
    :trace.session_create(:my_session, tracer, [])
  end
end
defmodule BeamScheduler.Monitor do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    # Trace all processes for:
    # :procs          -> process-related events (spawn, exit, signals)
    # :running_procs  -> when processes start running on a scheduler
    :erlang.trace(:new, true, [ :running_procs])

    # Set a system monitor to watch for long scheduling times.
    :erlang.system_monitor(self(), [{:long_schedule, 100}])


    {:ok, %{}}
  end
  def handle_info({:trace, spawning_pid, :spawn, spawned_pid, mfa}, state) do
    spawn_time = System.monotonic_time(:microsecond)
    IO.puts "I HAVE STATE"
    state = Map.put(state, spawned_pid, spawn_time)
    {:noreply, state}
  end

  def handle_info({:trace, pid, :running_procs, []}, state) do
    raise "error"
    start_time = System.monotonic_time(:microsecond)
    IO.inspect(state)
    case Map.pop(state, pid) do
      {spawn_time, new_state} ->
        wait_time = start_time - spawn_time
        IO.puts("Process #{inspect(pid)} waited ~#{wait_time} µs before running.")
        {:noreply, new_state}
      {nil, new_state} ->
        # This means we didn't record a spawn time. Might be a system process.
        {:noreply, new_state}
    end
  end
  def handle_info({:trace, _spawning_pid, :spawn, spawned_pid, mfa}) do
      IO.puts "I WAS HERE"

      IO.puts("Spawn trace: Spawned #{inspect(spawned_pid)} with #{inspect(mfa)}")

    end
  # Handle trace messages for when processes start running
  def handle_info({:trace, pid, :running_procs, _any}, state) do
    raise "error"
    IO.puts("Process #{inspect(pid)} started running on a scheduler.")
    {:noreply, state}
  end

  def handle_info({:trace, _spawning_pid, :spawn, spawned_pid, mfa}, state) do
    IO.puts "I WAS HERE"

    IO.puts("Spawn trace: Spawned #{inspect(spawned_pid)} with #{inspect(mfa)}")
    {:noreply, state}
  end

  # Handle process-related trace events, such as spawn
  def handle_info({:trace, parent_pid, :spawn, [new_pid, mod, fun, args]}, state) do
    IO.puts("Process #{inspect(parent_pid)} spawned #{inspect(new_pid)} by calling #{mod}.#{fun}/#{length(args)}")
    {:noreply, state}
  end
  def handle_info({:trace, _, _in_or_out, {:proc_lib, :sync_start, 2}}, s), do: {:noreply, s}

  # Handle long_schedule messages from system_monitor
  def handle_info({:monitor, :long_schedule, pid, time}, state) do
    IO.puts("Long schedule warning: Process #{inspect(pid)} waited #{time} microseconds before running.")
    {:noreply, state}
    end
  def handle_info({:trace, _, _in_or_out, {:code_server, :loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:prim_file, :read_file_nif, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:erlang, :bif_return_trap, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:code_server, :call, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {IEx.Server, :wait_eval, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {IEx.Evaluator, :loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {IEx.Server, :wait_input, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:user_drv, :handle_req, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:group, :log_io_request, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:gen_statem, :loop_receive_result, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:disk_log, :loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:group, :server_loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:erts_internal, :dirty_nif_finalizer, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:prim_tty, :writer_loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:gen_statem, :loop_receive, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:group, :more_data, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, :getting_unlinked}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:prim_file, :write_nif, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:prim_tty, :write_nif, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:io, :execute_request, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:erts_dirty_process_signal_handler, :msg_loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:group, :get_unicode_state, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:group, :get_terminal_state, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:group, :get_tty_geometry, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:gen_server, :loop, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, :normal}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:erlang, :hibernate, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:code, :ensure_loaded, _i}}, s), do: {:noreply, s}
  def handle_info({_any, _, _in_or_out, {:prim_tty, _any2, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:erlang, :++, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:user_drv, :server, _i}}, s), do: {:noreply, s}
  def handle_info({:trace, _, _in_or_out, {:lists, :flatmap_1, _i}}, s), do: {:noreply, s}

  def handle_info({:trace, spawning_pid, :spawned, spawned_pid, mfa}, state) do
    IO.puts("Spawned: #{inspect(spawned_pid)} with #{inspect(mfa)} from #{inspect(spawning_pid)}")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    #{trace, _pid, _where, pattern} = msg

    #IO.puts(inspect(msg))
    #IO.puts("def handle_info({#{inspect(trace)}, _, _in_or_out, #{inspect(pattern)}}, s), do: {:noreply, s}")
    IO.puts("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end

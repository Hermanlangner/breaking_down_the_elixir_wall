defmodule BeamScheduler do
  use Application

  def start(_type, _args) do
    # Start the Observer tool to inspect the BEAM runtime (GUI will open if environment supports it)
    :observer.start()

    # Start our Monitor GenServer that sets up the tracing and monitoring
    BeamScheduler.Monitor.start_link()

    # In this simple example, we have no supervised children besides the monitor process.
    children = [{}]
    opts = [strategy: :one_for_one, name: BeamScheduler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

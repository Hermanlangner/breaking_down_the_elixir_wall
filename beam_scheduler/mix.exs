defmodule BeamScheduler.MixProject do
  use Mix.Project
  @doc """
#https://hexdocs.pm/observer_cli/
#:erlang.system_info(:scheduler_id)
:erlang.system_info(:garbage_collection)
:erlang.system_info(:scheduler_bindings)
:erlang.system_info(:logical_processors_online)
:erlang.statistics(:scheduler_wall_time)
:erlang.system_info(:schedulers_online)
:erlang.system_info(:schedulers)
all_schedulers = :erlang.statistics(:scheduler_wall_time)

# Suppose we want the info for scheduler with ID == 2
specific_scheduler_info =
  Enum.find(all_schedulers, fn {id, _active, _total} -> id == 2 end)

IO.inspect(specific_scheduler_info, label: "Scheduler #2 info")
"""
  def project do
    [
      app: :beam_schedueler,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx, :observer, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

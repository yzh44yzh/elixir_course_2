defmodule ChatServer do
  use Application

  @impl true
  def start(_start_type, _args) do
    IO.puts("Start ChatServer")
    child_specs = [
      SessionManager
    ]
    Supervisor.start_link(child_specs, strategy: :one_for_one) 
  end
end

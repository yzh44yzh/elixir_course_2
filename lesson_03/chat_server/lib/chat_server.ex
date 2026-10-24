defmodule ChatServer do
  use Application

  @impl true
  def start(_start_type, args) do
    IO.puts("ChatServer.start args: #{inspect(args)}")
    child_specs = [
      SessionManager
    ]
    Supervisor.start_link(child_specs, strategy: :one_for_one) 
  end
end

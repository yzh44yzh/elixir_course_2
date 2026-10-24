defmodule ClientSession do
  use GenServer, restart: :transient

  def start_link({client_id, registry, options}) do
    name = {:via, Registry, {registry, client_id}}
    args = {client_id, options}  
    GenServer.start_link(ClientSession, args, name: name)
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  @impl true
  def init({client_id, options}) do
    state = %{
      client_id: client_id,
      heartbeat: Map.get(options, :heartbeat)
    }
    IO.puts("Start ClientSession pid:#{inspect self()}, state: #{inspect state}")
    {:ok, state}
  end

  @impl true
  def handle_cast(:stop, state) do
    %{client_id: client_id} = state
    IO.puts("Stop ClientSession pid:#{inspect self()}, client_id: #{client_id}")
    {:stop, :normal, state}
  end
  
end

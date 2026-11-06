defmodule SessionManager do
  use DynamicSupervisor

  @sup_name :session_manager
  @registry :session_manager_registry

  def start_link(_) do
    Registry.start_link(keys: :unique, name: @registry)
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @sup_name)
  end

  def start_session(client_id) do
    options = %{
      heartbeat: Application.get_env(:chat_server, :connection_heartbeat)
    }
    args = {client_id, @registry, options}
    child_spec = {ClientSession, args}
    DynamicSupervisor.start_child(@sup_name, child_spec)
  end

  @spec stop_session(integer()) :: :ok | {:error, :not_found}
  def stop_session(client_id) do
    case Registry.lookup(@registry, client_id) do
      [{pid, _}] ->
        ClientSession.stop(pid)
        :ok
      [] ->
        {:error, :not_found}
    end
  end

  @impl true
  def init(:no_args) do
    IO.puts("Start SessionManager")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

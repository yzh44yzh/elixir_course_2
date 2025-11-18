defmodule SessionManager do

  defmodule Session do
    @type t :: %Session{
      username: String.t(),
      shard: non_neg_integer(),
      node: String.t()
    }
    
    defstruct [:username, :shard, :node]
  end

  @type state() :: [Session.t()]

  @spec add_session(pid(), String.t()) :: :ok
  def add_session(manager_pid, username) do
    shard = 1
    node = "Node-1"
    # {shard, node} = ShardManager.settle(username)
    session = %Session{username: username, shard: shard, node: node}
    Agent.update(manager_pid, fn(state) -> [session | state] end)
    :ok
  end

  @spec get_sessions(pid()) :: [Session.t()]
  def get_sessions(manager_pid) do
    Agent.get(manager_pid, fn(state) -> state end)
  end

  @spec get_session_by_name(pid(), String.t()) :: {:ok, Session.t()} | {:error, :not_found}
  def get_session_by_name(manager_pid, name) do
    Agent.get(manager_pid, fn(state) -> find_session(state, name) end)
  end

  @spec start() :: pid()
  def start() do
    state = []
    Agent.start(fn() -> state end)
  end

  @spec stop(pid()) :: :ok
  def stop(pid) do
    Agent.stop(pid)
  end

  # function works inside Agent process
  @spec find_session([Session.t()], String.t()) :: {:ok, Session.t()} | {:error, :not_found}
  defp find_session(sessions, name) do
    Enum.find(sessions, fn(session) -> session.username == name end)
    |> case do
      %Session{} = s -> {:ok, s}
      nil -> {:error, :not_found}
    end
  end
  
end

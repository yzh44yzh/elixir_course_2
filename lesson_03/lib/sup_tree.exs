defmodule App do

  def start() do
    IO.puts("App.start #{inspect self()}")
    App.RootSup.start_link(:no_args)
  end
  
  defmodule RootSup do
    use Supervisor

    def start_link(_) do
      IO.puts("RootSup.start_link #{inspect self()}")
      Supervisor.start_link(__MODULE__, :no_args)
    end
    
    @impl true
    def init(_) do
      IO.puts("RootSup.init #{inspect self()}")
      child_spec = [
        App.AgentSup,
        App.PathFinderSup
      ]
      Supervisor.init(child_spec, strategy: :one_for_all)
    end
  end

  defmodule AgentSup do
    use Supervisor

    def start_link(_) do
      IO.puts("AgentSup.start_link #{inspect self()}")
      Supervisor.start_link(__MODULE__, :no_args)
    end
    
    @impl true
    def init(_) do
      IO.puts("AgentSup.init #{inspect self()}")

      nodes_1 = ["node-a1", "node-a2", "node-a3", "node-a4"]
      nodes_2 = ["node-b1", "node-b2", "node-b3", "node-b4"]
      child_spec = [
        %{
          id: :agent_a,
          start: {ShardManager, :start_link, [{:agent_a, nodes_1, 10}]}
        },
        %{
          id: :agent_b,
          start: {ShardManager, :start_link, [{:agent_b, nodes_2, 16}]}
        }
      ]
      Supervisor.init(child_spec, strategy: :one_for_all)
    end
  end

  defmodule PathFinderSup do
    use Supervisor

    def start_link(_) do
      IO.puts("PathFinderSup.start_link #{inspect self()}")
      Supervisor.start_link(__MODULE__, :no_args)
    end
    
    @impl true
    def init(_) do
      IO.puts("PathFinderSup.init #{inspect self()}")
      child_spec = [
        %{
          id: :pf_ru,
          start: {PathFinder, :start_link, [:pf_ru, "./data/cities_ru.csv"]}
        },
        %{
          id: :pf_eu,
          start: {PathFinder, :start_link, [:pf_eu, "./data/cities_eu.csv"]}
        }
      ]
      Supervisor.init(child_spec, strategy: :one_for_all)
    end
  end
  
end

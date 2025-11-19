defmodule ShardManager do

  defmodule ShardRange do
    @type t :: {
      node :: String.t(),
      from_shard :: non_neg_integer(), 
      to_shard :: non_neg_integer() 
    }

    defstruct [:node, :from_shard, :to_shard]
  end

  defmodule State do
    @type t :: %State{
      num_shards: pos_integer(),
      shard_ranges: [ShardRange.t()]
    }
    
    defstruct [:num_shards, :shard_ranges]
  end

  def start() do
    nodes = ["node-1", "node-2", "node-3", "node-4"]
    start(nodes, 32)
  end

  @spec start([String.t()], pos_integer()) :: State.t()
  def start(nodes, num_shards) do
    num_nodes = length(nodes)
    shards_per_node = ceil(num_shards / num_nodes)
    {_, shard_ranges} =
      Enum.reduce(nodes, {1, []},
        fn (node, {from_shard, acc}) ->
          to_shard = from_shard + shards_per_node - 1
          to_shard = if to_shard > num_shards, do: num_shards, else: to_shard
          range = %ShardRange{node: node, from_shard: from_shard, to_shard: to_shard}
          {to_shard + 1, [range | acc]}
        end)
    state = %{num_shards: num_shards, shard_ranges: shard_ranges}
    Agent.start(fn () -> state end, [name: :shard_manager])
    state
  end

  @spec get_node(non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found}
  def get_node(shard) do
    Agent.get(:shard_manager, fn(state) -> get_node(state, shard) end)
  end

  # function works inside Agent process
  @spec get_node(State.t(), non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found}
  defp get_node(state, shard) do
    Enum.filter(state.shard_ranges,
      fn(%ShardRange{from_shard: from, to_shard: to}) ->
        shard >= from and shard <= to
      end)
    |> case do
      [] -> {:error, :not_found}
      [%ShardRange{node: node}] -> {:ok, node}
    end
  end

  @spec settle(String.t()) :: {non_neg_integer(), String.t()}
  def settle(username) do
    num_shards = Agent.get(:shard_manager, fn(state) -> state.num_shards end)
    shard = :erlang.phash2(username, num_shards) + 1
    {:ok, node} = get_node(shard)
    {shard, node}
  end
       
end

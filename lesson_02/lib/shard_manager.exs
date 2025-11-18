defmodule ShardManager do

  defmodule ShardsRange do
    @type t :: {
      from_shard :: non_neg_integer(), 
      to_shard :: non_neg_integer(), 
      node :: String.t()
    }

    defstruct [:from_shard, :to_shard, :node]
  end

  defmodule State do
    @type t :: %State{
      num_shards: pos_integer(),
      shards_ranges: [ShardsRange.t()]
    }
    
    defstruct [:num_shards, :shards_ranges]
  end

  def start() do
    state = %State{
      num_shards: 32,
      shards_ranges: [
        %ShardsRange{from_shard: 0, to_shard: 7, node: "node-1"},
        %ShardsRange{from_shard: 8, to_shard: 15, node: "node-2"},
        %ShardsRange{from_shard: 16, to_shard: 23, node: "node-3"},
        %ShardsRange{from_shard: 24, to_shard: 31, node: "node-4"}
      ]
    }
    Agent.start(fn () -> state end, [name: :shard_manager])
    :ok
  end

  @spec get_node(non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found}
  def get_node(shard) do
    Agent.get(:shard_manager, fn(state) -> get_node(state, shard) end)
  end

  # function works inside Agent process
  @spec get_node(State.t(), non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found}
  defp get_node(state, shard) do
    Enum.reduce(state.shards_ranges, {:error, :not_found},
      fn
        (_, {:ok, node}) -> {:ok, node}
        (%ShardsRange{from_shard: from_shard, to_shard: to_shard, node: node}, acc) ->
          if shard >= from_shard and shard <= to_shard do
            {:ok, node}
          else
            acc
          end
      end)
  end

  @spec settle(String.t()) :: {non_neg_integer(), String.t()}
  def settle(username) do
    num_shards = Agent.get(:shard_manager, fn(state) -> state.num_shards end)
    shard = :erlang.phash2(username, num_shards)
    {:ok, node} = get_node(shard)
    {shard, node}
  end

  @spec reshard([String.t()], pos_integer()) :: State.t()
  def reshard(nodes, num_shards) do
    num_nodes = length(nodes)
    shards_per_node = ceil(num_shards / num_nodes)
    num_shards = num_shards - 1
    {_, new_shards_ranges} =
      Enum.reduce(nodes, {0, []},
        fn (node, {from_shard, acc}) ->
          to_shard = from_shard + shards_per_node
          to_shard = if to_shard > num_shards, do: num_shards, else: to_shard
          range = %ShardsRange{from_shard: from_shard, to_shard: to_shard, node: node}
          {to_shard, [range | acc]}
        end)
    new_state = %{num_shards: num_shards, shards_ranges: new_shards_ranges}
    Agent.update(:shard_manager, fn(_old_state) -> new_state end)
    new_state
  end
       
end

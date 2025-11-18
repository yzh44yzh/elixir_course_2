defmodule ShardManager do

  def start() do
    state = %{
      num_shards: 32,
      shards: [
        {0, 7, "node-1"},
        {8, 15, "node-2"},
        {16, 23, "node-3"},
        {24, 31, "node-4"}
      ]
    }
    Agent.start(fn () -> state end, [name: :shard_manager])
    :ok
  end

  @spec get_node(integer()) :: {:ok, String.t()} | {:error, :not_found}
  def get_node(shard_num) do
    Agent.get(:shard_manager, fn(state) -> get_node(state, shard_num) end)
  end

  # function works inside Agent process
  defp get_node(state, shard_num) do
    Enum.reduce(state.shards, {:error, :not_found},
      fn
        (_, {:ok, res}) -> {:ok, res}
        ({min_shard, max_shard, node_name}, res) ->
          if shard_num >= min_shard and shard_num <= max_shard do
            {:ok, node_name}
          else
            res
          end
      end)
  end

  @spec settle(String.t()) :: {integer(), String.t()}
  def settle(username) do
    num_shards = Agent.get(:shard_manager, fn(state) -> state.num_shards end)
    shard = :erlang.phash2(username, num_shards)
    {:ok, node} = get_node(shard)
    {shard, node}
  end

  def reshard(nodes, num_shards) do
    num_nodes = length(nodes)
    shards_per_node = ceil(num_shards / num_nodes)
    {_, new_shards} =
      Enum.reduce(nodes, {0, []},
        fn (node, {from_shard, acc}) ->
          to_shard = from_shard + shards_per_node
          to_shard = if to_shard > num_shards, do: num_shards, else: to_shard
          {to_shard, [{from_shard, to_shard - 1, node} | acc]}
        end)
    new_state = %{num_shards: num_shards, shards: new_shards}
    Agent.update(:shard_manager, fn(_old_state) -> new_state end)
    new_state
  end
       
end

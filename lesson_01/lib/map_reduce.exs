defmodule MapReduce do 

  def start() do
    tree = {:reducer, [
      {:reducer, [
        {:mapper, "/home/yury-zhloba/edu/elixir_course_2/lesson_01/01_01_processes.md"},
        {:mapper, "/home/yury-zhloba/edu/elixir_course_2/lesson_01/01_02_mailbox.md"},
        {:mapper, "/home/yury-zhloba/edu/elixir_course_2/lesson_01/01_03_link.md"}
      ]},
      {:reducer, [
        {:mapper, "/home/yury-zhloba/edu/elixir_course_2/lesson_01/01_04_monitor.md"},
        {:mapper, "/home/yury-zhloba/edu/elixir_course_2/lesson_01/01_05_map_reduce.md"}
      ]}
    ]}
    pid = start_process(tree)
    receive do
      {:result, pid, result} ->
        result
      unknown_msg ->
        IO.puts("MapReduce #{inspect(self())} got unknown message #{inspect(unknown_msg)}")
    after
      1000 -> IO.puts("MapReduce #{inspect(self())} got not messages")
    end
  end

  def start_process({:reducer, children}) do
    spawn(MapReduce.Reducer, :run, [self(), children])
  end

  def start_process({:mapper, file}) do
    spawn(MapReduce.Mapper, :run, [self(), file])
  end

  defmodule Reducer do
    defmodule State do
      defstruct [:parent, :children, :results]
    end

    def run(parent, tree_nodes) do
      IO.puts("Reducer #{inspect(self())} with parent #{inspect(parent)} and #{length(tree_nodes)}")
      children = Enum.map(tree_nodes, fn(node) -> MapReduce.start_process(node) end)
      IO.puts("child processes started #{inspect(children)}")
      state = %State{parent: parent, children: children, results: []}
      loop(state)
    end

    def loop(%State{parent: parent, children: [], results: results}) do
      IO.puts("Reducer #{inspect(self())} got results #{inspect(results)}")
      result = Enum.sum(results)
      send(parent, {:result, self(), result})
    end

    def loop(%State{children: mappers, results: results} = state) do
      IO.puts("Reducer #{inspect(self())} are in loop with #{length(mappers)} children left")
      receive do
        {:result, mapper, result} ->
          IO.puts("Reducer #{inspect(self())} got result #{result} from #{inspect(mapper)}")
          state = %State{state |
            children: List.delete(mappers, mapper),
            results: [result | results]
          }
          loop(state)
        unknown_msg ->
          IO.puts("Reducer #{inspect(self())} got unknown message #{inspect(unknown_msg)}")
      after
        1000 -> IO.puts("Reducer #{inspect(self())} got not messages")
      end
    end
  end

  defmodule Mapper do
    def run(parent, file) do
      IO.puts("Mapper #{inspect(self())} with parent #{inspect(parent)} and file #{file}")
      count = words_cound(file)
      send(parent, {:result, self(), count})
    end 

    def words_cound(file) do
      {:ok, content} = File.read(file)
      String.split(content) |> length()
    end
  end

end

defmodule MapReduce do

  def start() do
    processes_tree = 
    {:reducer, [
        {:reducer, [
            {:mapper, "./02_01_task.md"},
            {:mapper, "./02_02_agent.md"}
          ]},
        {:reducer, [
            {:mapper, "./02_03_create_gen_server.md"},
            {:mapper, "./02_04_gen_server_module.md"}
          ]}
      ]}
    start(processes_tree)
  end
  
  def start(processes_tree) do
    map_reduce(processes_tree)
  end

  
  def map_reduce({:mapper, file}) do
    IO.puts("do_map file '#{file}'")
    {:ok, content} = File.read(file)
    res = String.split(content) |> length()
    IO.puts("mapper result #{res}")
    res
  end

  
  def map_reduce({:reducer, children}) do
    IO.puts("do_reduce #{inspect children}")
    result_stream = Task.async_stream(children, &map_reduce/1)
    res = Enum.reduce(result_stream, 0, fn ({:ok, num}, acc) -> num + acc end)
    IO.puts("reducer result #{res}")
    res
  end
  
end

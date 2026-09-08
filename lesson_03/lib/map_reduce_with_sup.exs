defmodule MapReduce do

  def start() do
    processes_tree = 
    {:reducer, [
        {:reducer, [
            {:mapper, "../03_01_supervisor.md"},
            {:mapper, "../03_02_use_supervisor.md"},
            {:mapper, "../03_03_dynamic_supervisor.md"}
          ]},
        {:reducer, [
            {:mapper, "../03_04_application.md"},
            {:mapper, "../03_05_application_configuration.md"},
            {:mapper, "../03_06_observer.md"}
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

    # result_stream = Task.async_stream(children, &map_reduce/1)
    {:ok, sup_pid} = Task.Supervisor.start_link()
    result_stream = Task.Supervisor.async_stream(sup_pid, children, &map_reduce/1)

    res = Enum.reduce(result_stream, 0, fn ({:ok, num}, acc) -> num + acc end)
    IO.puts("reducer result #{res}")
    res
  end
  
end

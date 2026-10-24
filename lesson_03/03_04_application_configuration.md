# Конфигурирование Application

Каждое приложение имеет свои собственные настройки и АПИ для доступа к ним.

```
$ cd chat_server
$ iex -S mix
> Application.get_all_env(:chat_server)
[]
> Application.put_env(:chat_server, :param1, 42)
:ok
> Application.put_env(:chat_server, :param2, :some_val)
:ok
> Application.get_all_env(:chat_server)
[param1: 42, param2: :some_val]

> Application.get_env(:chat_server, :param1)
42
> Application.fetch_env(:chat_server, :param1)
{:ok, 42}
> Application.fetch_env(:chat_server, :param3)
:error
> Application.get_env(:chat_server, :param3)
nil
```

Настройки хранятся в application environment, это быстрое in-memory key-value хранилище. Оно находится в глобальной области видимости, и к нему можно обращаться из любого места в коде.

В нашем приложении пока нет настроек, их можно добавить в **mix.exs**:

```
def application do
  [
    extra_applications: [:logger],
    mod: {ChatServer, [:hello, :world]},
    registered: [:session_manager],
    env: [param1: 42, param2: "hello"]
  ]
end
```

И тогда настройки появятся сразу после запуска приложения:

```
$ iex -S mix
iex(1)> Application.get_all_env(:chat_server)
[param1: 42, param2: "hello"]
```

Однако настройки удобнее задавать не в mix.exs, а в отдельных файлах. mix позволяет указать настройки в файле **config/config.exs**:

```
import Config

config :chat_server,
  param1: 42,
  param2: "hello",
  param3: true
```

Настройки в этом файле переопределяют настройки в mix.exs:

```
iex(1)> Application.get_all_env(:chat_server)
[param1: 42, param3: true, param2: "hello"]
```

Давайте запустим в нашем приложении SessionManager и ClientSession. И добавим полезную настройку `connection_heartbeat`, которая будет задавать интервал запуска heartbeat -- проверки, что соединение активно.

```
config :chat_server,
  connection_heartbeat: 2_000
```

Запустим `SessionManager` в корневом супервизоре `ChatServer`:

```
    child_specs = [
      SessionManager
    ]
    Supervisor.start_link(child_specs, strategy: :one_for_one) 
```

И при создании `ClientSession` будем передавать ему настройку `connection_heartbeat`:
```
  def start_session(client_id) do
    options = %{
      heartbeat: Application.get_env(:chat_server, :connection_heartbeat)
    }
    args = {client_id, @registry, options}
    child_spec = {ClientSession, args}
    DynamicSupervisor.start_child(@sup_name, child_spec)
  end
```

А в `ClientSession` будем принимать эту настройку:
```
  def init({client_id, options}) do
    state = %{
      client_id: client_id,
      heartbeat: Map.get(options, :heartbeat)
    }
    IO.puts("Start ClientSession pid:#{inspect self()}, state: #{inspect state}")
    {:ok, state}
  end
```

Проверяем, как это работает:

```
$ iex -S mix  
ChatServer.start args: [:hello, :world]
Start SessionManager

> SessionManager.start_session(1)
Start ClientSession pid:#PID<0.166.0>, state: %{client_id: 1, heartbeat: 2000}
{:ok, #PID<0.166.0>}

> SessionManager.start_session(2)
Start ClientSession pid:#PID<0.167.0>, state: %{client_id: 2, heartbeat: 2000}
{:ok, #PID<0.167.0>}

> SessionManager.stop_session(1)
:ok
Stop ClientSession pid:#PID<0.166.0>, client_id: 1

> SessionManager.stop_session(1)
{:error, :not_found}
```

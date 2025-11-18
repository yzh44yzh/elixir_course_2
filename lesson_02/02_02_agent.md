# Agent

[Agent](https://hexdocs.pm/elixir/1.12/Agent.html) -- это процесс, который хранит в своей памяти какую-то информацию, которая нужна другим процессам. 

Например, у нас есть чат-сервер, в котором есть список пользователей, находящихся онлайн (подключенных к серверу) в данный момент. 

Эта информация имеет три особенности: 
- она должна храниться столько, сколько живет вся система;
- она нужна многим процессам;
- она постоянно меняется.

В BEAM системах такого рода информацию хранят специальные процессы -- Agent или GenServer. Информация хранится в одном месте и не дублируется, так её проще обновлять. Информация живет столько, сколько живет процесс-владелец. Другие процессы запрашивают информацию у владельца через механизм обмена сообщениями.


## Простой пример

Посмотрим, как это работает. 

Мы запускаем Agent и передаём ему функцию, которая должна сформировать начальное состояние. В данном случае это пустой список:
  
```elixir
{:ok, agent_pid} = Agent.start(fn () -> [] end)
```

Затем мы обновляем состояние агента, передавая ему функцию, которая принимает текущее состояние и возвращает новое. Агент выполняет эту функцию в своём процессе:

```elixir
Agent.update(agent_pid, fn (online_users) -> ["Bob" | online_users] end)
Agent.update(agent_pid, fn (online_users) -> ["Kate" | online_users] end)
```

Мы можем запросить текущее состояние (или его часть), снова передав агенту функцию, которую он выполнит в своём процессе:

```elixir
Agent.get(agent_pid, fn (online_users) -> online_users end)
```

Обновление списка пользователей удобнее обернуть в некое АПИ:

```elixir
add_user = fn(name) ->
  Agent.update(agent_pid, fn (online_users) -> [name | online_users] end)
end

add_user.("John")
```

Запрос списка пользователей тоже удобнее обернуть в АПИ:

```elixir
get_users = fn() ->
  Agent.get(agent_pid, fn (online_users) -> online_users end)
end

get_users.()
```

И дальше с этим можно работать:

```elixir
add_user.("Helen")
add_user.("Bill")
get_users.()
```


## Агент, обернутый в модуль

Недостаток агента в том, что сторонний код имеет полный доступ к его состоянию. Это легко исправить, если обернуть агент в модуль, и реализовать доступ через АПИ модуля.

Рассмотрим этот подход на примере.


### Первый пример -- SessionManager

```elixir
$ iex session_manager.exs
iex(1)> pid = SessionManager.start()
{:ok, #PID<0.118.0>}
iex(2)> {:ok, pid} = SessionManager.start()
{:ok, #PID<0.119.0>}
iex(3)> SessionManager.add_session(pid, "Bob")
:ok
iex(4)> SessionManager.add_session(pid, "Kate")
:ok
iex(5)> SessionManager.add_session(pid, "Bill")
:ok
iex(6)> SessionManager.get_sessions(pid)
[
  %SessionManager.Session{username: "Bill", num_shard: 1, node_name: "Node-1"},
  %SessionManager.Session{username: "Kate", num_shard: 1, node_name: "Node-1"},
  %SessionManager.Session{username: "Bob", num_shard: 1, node_name: "Node-1"}
]
iex(7)> SessionManager.get_session_by_name(pid, "Bob")
%SessionManager.Session{username: "Bob", num_shard: 1, node_name: "Node-1"}
iex(8)> SessionManager.get_session_by_name(pid, "Bobob")
nil
```

### Второй пример -- ShardManager

Допустим, наш чат-сервер представляет собой кластер из четырех узлов. Мы хотим распределить онлайн пользователей равномерно между узлами и для этого применяем шардинг -- делим всех пользователей на 48 групп (шардов). С помощью некой хеширующей функции мы для каждого пользователя вычисляем, к какому шарду он относится. А затем подключаем пользователя к нужному узлу кластера.

Для этого нам нужно знать, за какой диапазон шард отвечает каждый узел. Эту информацию можно хранить в списке:

```elixir
[
  { 0, 11, "Node-1"},
  {12, 23, "Node-2"},
  {24, 35, "Node-3"},
  {36, 47, "Node-4"}
]
```

А список мы будем хранить в агенте. Мы помним, что процесс можно зарегистрировать под определенным именем, чтобы обращаться к нему по имени, а не по pid. Агента тоже можно зарегистрировать таким образом.

```elixir
state = [
  { 0, 11, "Node-1"},
  {12, 23, "Node-2"},
  {24, 35, "Node-3"},
  {36, 47, "Node-4"}
]
Agent.start(fn () -> state end, [name: :sharding_info])
```

Обернем агента в модуль, реализуем АПИ для доступа к информации о шардах и посмотрим, как это работает:

```elixir-iex
iex(1)> c "lib/shard_manager.exs"
iex(2)> alias ShardManager, as: SM
iex(3)> SM.start
:ok
iex(4)> SM.find_node(1)
{:ok, "Node-1"}
iex(5)> SM.find_node(10)
{:ok, "Node-1"}
iex(6)> SM.find_node(12)
{:ok, "Node-2"}
iex(7)> SM.find_node(30)
{:ok, "Node-3"}
iex(8)> SM.find_node(300)
{:error, :not_found}
```


#### Решардинг

Иногда бывает нужно перераспределить шарды между узлами (выполнить решардинг). Обычно это бывает, когда у нас меняется количество узлов в кластере.

Добавим в наш модуль такое АПИ:

```elixir-iex
> r SM
> nodes = ["Node-1", "Node-2", "Node-3", "Node-4", "Node-5"]
> SM.reshard(nodes, 48)
[
  {40, 47, "Node-5"},
  {30, 39, "Node-4"},
  {20, 29, "Node-3"},
  {10, 19, "Node-2"},
  {0, 9, "Node-1"}
]
> SA.find_node(30)
{:ok, "Node-4"}
```


## Взаимодействие двух агентов

Теперь, когда у нас есть два агента, давайте организуем взаимодействие между ними.

Сделаем так, чтобы каждый пользователь был привязан к определенному шарду и узлу.

Добавим в ShardManager функцию `settle/1`, которая по имени пользователя определяет, в какой шард и узел он должен быть добавлен:

```elixir
defmodule ShardManager do
  ...
  @spec settle(String.t()) :: {integer(), String.t()}
  def settle(username) do
    num_shards = Agent.get(:shard_manager, fn(state) -> state.num_shards end)
    shard = :erlang.phash2(username, num_shards)
    {:ok, node} = get_node(shard)
    {shard, node}
  end
```
Функция `:erlang.phash2/2` позволяет получить хеш от любого значения в виде целого числа в заданом диапазоне. 

И вызовем `settle` в SessionManager:
```elixir
defmodule SessionManager do
  ...
  @spec add_session(pid(), String.t()) :: :ok
  def add_session(manager_pid, username) do
    {shard, node} = ShardManager.settle(username)
    session = %Session{username: username, num_shard: shard, node_name: node}
    Agent.update(manager_pid, fn(state) -> [session | state] end)
    :ok
  end
```

Нужно запустить оба агента прежде, чем вызывать их АПИ:
  
```elixir
> c "session_manager.exs"
> c "shard_manager.exs"
> ShardManager.start
> SessionManager.start
> SessionManager.add_user("Helen")
> SessionManager.add_user("Bob")
> SessionManager.add_user("Kate")
> SessionManager.get_sessions()
[{"Kate", 17, "Node-2"}, {"Bob", 33, "Node-3"}, {"Helen", 13, "Node-2"}]
```

На этом месте опытные разработчики заметят, что если теперь выполнить решардинг, то данные об узлах в списке пользователей станут невалидными. Это верно. Решардинг часто бывает сложной задачей. Это тема для курса "Elixir Expert", а не "Elixir Junior" :)

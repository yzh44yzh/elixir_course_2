# Динамический супервизор

В прошлом уроке мы создали статичное дерево супервизоров. Все процессы в нем запускаются на старте узла (виртуальной машины) и живут столько, сколько живет сам узел. 

Во многих системах этого достаточно. Например, если у вас веб-сервис, который обслуживает клиентов по HTTP API, то достаточно создать пул процессов, которые будут обслуживать HTTP запросы. И этот пул запускается на страте узла и живёт вместе с узлом.

Но бывает нужно запускать и останавливать процессы в связи с какими-нибудь событиями. Например, если ваш сервис работает не по HTTP, а через долгоживущие TCP-сокеты, то здесь разумнее запускать новый процесс при открытии сокета и останавливать его при закрытии сокета.

В Эликсире для этого есть специальный вид супервизора -- динамический супервизор [DynamicSupervisor](https://elixir.hexdocs.pm/1.20.4/DynamicSupervisor.html)

Способность держать много долгоживущих сокетов является сильной стороной Эликсир и делает его хорошим выбором для систем, где есть много одновременно подлючённых клиентов с долгоживующими сессиями. Классический пример такой системы -- чат-сервер.


## Задача 

Мы сделаем процесс `ClientSession`, который должен держать открытый сокет (или веб-сокет) и через него обмениваться данными с клиентом. Работу с сокетом мы реализуем позже в нашем курсе. А сейчас мы сделаем только запуск и остановку такого процесса.

И мы сделаем процесс `SessionManager`, который реализует `DynamicSupervisor`. Он будет запускать и останавливать процессы `ClientSession` по необходимости.


## Реализация ClientSession

[[./lib/chat_server.exs]]

Важные нюансы: 
- `restart: :transient`
- Регистрация процесса в `Registry`.

Динамические процессы мы не можем регистрировать под статическими именами. И нам нужно где-то хранить pid, чтобы взаимодейтсовать с процессом. Для этого в Эликсир есть модуль [Registry](https://elixir.hexdocs.pm/1.20.4/Registry.html). 

Шаг 1-й, `start_link` и `init`.

Шаг 2-й, `stop` и `handle_cast(:stop, ...)`

```
$ iex lib/chat_server.exs
iex(1)> ChatServer.ClientSession.child_spec(:no_args)
%{
  id: ChatServer.ClientSession,
  restart: :transient,
  start: {ChatServer.ClientSession, :start_link, [:no_args]}
}

iex(2)> Registry.start_link(keys: :unique, name: :session_manager_registry)
{:ok, #PID<0.121.0>}

iex(3)> ChatServer.ClientSession.start_link(1)
Start ClientSession pid:#PID<0.123.0>, state: %{client_id: 1}
{:ok, #PID<0.123.0>}

iex(4)> [{pid, _}] = Registry.lookup(:session_manager_registry, 1)
[{#PID<0.123.0>, nil}]

iex(6)> ChatServer.ClientSession.stop(pid)
Stop ClientSession pid:#PID<0.123.0>, client_id: 1
:ok
```


## Реализация SessionManager

Шаг 1-й, `start_link` и `init`.

Шаг 2-й, `start_session` и `stop_session`.

```
$ iex lib/chat_server.exs                          
iex(1)> ChatServer.SessionManager.start()
Start SessionManager
{:ok, #PID<0.123.0>}

iex(2)> ChatServer.SessionManager.start_session(1)
Start ClientSession pid:#PID<0.124.0>, state: %{client_id: 1}
{:ok, #PID<0.124.0>}

iex(3)> ChatServer.SessionManager.start_session(2)
Start ClientSession pid:#PID<0.125.0>, state: %{client_id: 2}
{:ok, #PID<0.125.0>}

iex(4)> ChatServer.SessionManager.stop_session(2)
Stop ClientSession pid:#PID<0.125.0>, client_id: 2
:ok
```

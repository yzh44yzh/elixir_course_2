# Динамический супервизор

Мы создали статичное дерево супервизоров. Все процессы в нем запускаются на старте узла (виртуальной машины) и живут столько, сколько живет сам узел. 

Часто бывают нужны и короткоживущие процессы. Их можно запускать и под обычным супервизором с настройкой restart: `transient` или `temporary`. Но в Эликсире для этого есть специальный вид супервизора -- динамический супервизор [DynamicSupervisor](https://hexdocs.pm/elixir/1.12/DynamicSupervisor.html)

Задача: ChatServer, ClientSession, SessionManager as DynSup

Нюансы: restart: :transient

Сперва без регистрации, затем добавить Registry

try Process.exit() for ClientSession с разными причинами (штатное и нештатное завершение)
смотреть за рестартами и за Registry.lookup

defmodule ChatServerTest do
  use ExUnit.Case
  doctest ChatServer

  test "greets the world" do
    assert ChatServer.hello() == :world
  end
end

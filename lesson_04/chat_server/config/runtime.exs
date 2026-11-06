import Config

config :chat_server,
  param_a: System.get_env("PARAM_A", "a-default")

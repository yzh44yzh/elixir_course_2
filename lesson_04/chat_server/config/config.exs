import Config

config :chat_server,
  connection_heartbeat: 2_000,
  param_a: "a",
  param_b: "b"

import_config "#{config_env()}.exs"

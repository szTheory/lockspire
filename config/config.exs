import Config

config :lockspire,
  repo: nil,
  account_resolver: nil,
  issuer: nil,
  mount_path: "/lockspire",
  oban: []

import_config "#{config_env()}.exs"

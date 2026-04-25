import Config

config :lockspire,
  repo: nil,
  account_resolver: nil,
  issuer: nil,
  mount_path: "/lockspire",
  oban: [],
  jar_max_age_seconds: 600

import_config "#{config_env()}.exs"

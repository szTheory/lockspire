import Config

config :lockspire,
  repo: <%= @app_module %>.Repo,
  account_resolver: <%= @resolver_module %>,
  issuer: "https://example.com",
  mount_path: "<%= @mount_path %>"

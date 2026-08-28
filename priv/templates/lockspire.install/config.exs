import Config

# Import this file from your main config entrypoint:
#   import_config "lockspire.exs"
#
# Keep the Lockspire runtime contract explicit and host-owned here.
config :lockspire,
  repo: <%= @app_module %>.Repo,
  account_resolver: <%= @resolver_module %>,
  issuer: "https://example.com",
  mount_path: "<%= @mount_path %>",
  # Host-owned logout route. Lockspire redirects here; it never owns your logout UX.
  logout_path: "/logout",
  storage_prefix: "<%= @storage_prefix %>",
  oban_prefix: "<%= @oban_prefix %>"

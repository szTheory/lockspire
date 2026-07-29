import Config

# Import this file from your main config entrypoint:
#   import_config "lockspire.exs"
#
# Keep the Lockspire runtime contract explicit and host-owned here.
config :lockspire,
  repo: <%= @app_module %>.Repo,
  account_resolver: <%= @resolver_module %>,
  # Change this to your real issuer host. The path suffix must match mount_path
  # below, or Lockspire's issuer/mount-path consistency check raises at boot.
  issuer: "https://example.com<%= @mount_path %>",
  mount_path: "<%= @mount_path %>",
  storage_prefix: "<%= @storage_prefix %>",
  oban_prefix: "<%= @oban_prefix %>",
  # Accept the standard OIDC scopes out of the box. Add your own host-specific
  # scopes here as your integration grows.
  known_scopes: ["openid", "email", "profile"],
  # Sign tokens with RSA-SHA256.
  signing_alg: "RS256",
  # Generate a real secret with `mix phx.gen.secret` and set it via an environment
  # variable or your secrets manager. Never commit a real secret_key_base literal.
  secret_key_base: "REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE"

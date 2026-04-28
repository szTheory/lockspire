defmodule GeneratedHostAppWeb.LockspireVerificationHTML do
  use Phoenix.Component
  use Phoenix.VerifiedRoutes,
    endpoint: GeneratedHostAppWeb.Endpoint,
    router: GeneratedHostAppWeb.Router,
    statics: GeneratedHostAppWeb.static_paths()

  embed_templates "lockspire_verification_html/*"
end

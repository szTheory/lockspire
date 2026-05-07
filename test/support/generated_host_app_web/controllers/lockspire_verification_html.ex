# Host-owned Lockspire seam
# Lockspire generates this file once, but your app owns the ongoing logic, UX, claims, and policy here.
# If you customize this file, keep those edits and reconcile future changes manually.

defmodule GeneratedHostAppWeb.LockspireVerificationHTML do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: GeneratedHostAppWeb.Endpoint,
    router: GeneratedHostAppWeb.Router,
    statics: GeneratedHostAppWeb.static_paths()

  embed_templates("lockspire_verification_html/*")
end

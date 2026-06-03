defmodule Lockspire.TestSupport.AdvancedSetupSupportTruth do
  @moduledoc false

  def assert_advanced_setup_support_contract!(content) do
    assert_includes_all(content, [
      "Bounded reactive remote-`jwks_uri` rollover support",
      "forces one refresh when verification indicates stale or unknown key material",
      "preserves the last known good cache entry when refresh fails",
      "fails the current authentication attempt closed",
      "Mutual TLS for confidential-client authentication and certificate-bound access tokens through exactly two shipped extractor patterns",
      "Lockspire.MTLS.Extractor.CowboyDirect",
      "Lockspire.MTLS.Extractor.ProxyHeader",
      "host app or deployment owns TLS termination",
      "Host Phoenix API route protection with the canonical shipped pipeline",
      "Lockspire.Plug.VerifyToken",
      "Lockspire.Plug.EnforceSenderConstraints",
      "Lockspire.Plug.RequireToken",
      "RP-initiated logout plus logout propagation from the protocol-owned `/end_session/complete` seam",
      "durable back-channel enqueueing with Oban and Req, plus front-channel iframe cleanup as best effort browser choreography only"
    ])

    assert_includes_all(content, [
      "Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope",
      "broader resource-server integration beyond Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped Phoenix plug pipeline",
      "Arbitrary custom `Lockspire.MTLS.Extractor` implementations are not first-class peers",
      "Dynamic Client Registration does not add a new logout runtime; it only manages the existing logout propagation metadata",
      "proves front-channel logout success remotely",
      # Phase 97 extensions (D-09 four non-goal patterns)
      "no introspection-at-the-RS as the host-API seam",
      "recreates gateway/CIAM productization the canon explicitly rejects",
      "no auto-detection of token shape",
      "documented ecosystem footgun",
      "no dual-verifier dispatcher",
      "hides operator-visible complexity inside the library",
      "no RAR enforcement at the RS plug",
      "RAR claims surface via `conn.assigns.access_token` for host-owned enforcement"
    ])
  end

  def assert_install_and_onboard_guide!(content) do
    assert_includes_all(content, [
      "For the full 1.0 GA support contract, see `docs/supported-surface.md`.",
      "docs/private-key-jwt-host-guide.md",
      "bounded reactive rollover truth",
      "docs/protect-phoenix-api-routes.md",
      "canonical optional host-route path",
      "mix lockspire.doctor remote-jwks --client <client_id>",
      "does not diagnose runtime remote-`jwks_uri` incidents",
      "durable back-channel delivery through Oban and Req",
      "front-channel iframe cleanup as best effort only"
    ])
  end

  def assert_private_key_jwt_host_guide!(content) do
    assert_includes_all(content, [
      "For the canonical public support contract, see `docs/supported-surface.md`.",
      "bounded reactive remote-`jwks_uri` rollover",
      "no background polling, no prefetch",
      "This is a narrow key-retrieval path for client authentication only.",
      "It is not a generic outbound metadata-ingestion feature.",
      "mix lockspire.doctor remote-jwks --client <client_id>",
      "Inline `jwks` is a deliberate fallback, not the default fix"
    ])
  end

  def assert_mtls_host_guide!(content) do
    assert_includes_all(content, [
      "Lockspire ships exactly two first-class extraction patterns",
      "Lockspire.MTLS.Extractor.CowboyDirect",
      "Lockspire.MTLS.Extractor.ProxyHeader",
      "For the canonical advanced-setup support contract, see [Supported Surface](supported-surface.md).",
      "The host app or infrastructure owns TLS termination, trusted forwarding, and unconditional stripping or overwriting of forwarded certificate headers",
      "Custom `Lockspire.MTLS.Extractor` implementations remain available as an escape hatch",
      "they are not first-class peers to the shipped Cowboy direct and trusted proxy-header patterns"
    ])
  end

  def assert_protected_routes_guide!(content) do
    assert_includes_all(content, [
      "For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md).",
      "Lockspire.Plug.VerifyToken",
      "Lockspire.Plug.EnforceSenderConstraints",
      "Lockspire.Plug.RequireToken",
      "no-op for unconstrained bearer tokens",
      "error=\"use_dpop_nonce\"",
      "business authorization",
      "tenant checks",
      # Phase 97 extensions (D-06, D-07)
      "Lockspire issues RFC 9068 `at+jwt` access tokens by default.",
      "`Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes.",
      "Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable.",
      "To opt a client back to opaque, see the admin Client Detail page.",
      "after the v1.27 runtime narrowing and default-issuance flip"
    ])
  end

  def assert_operator_admin_guide!(content) do
    assert_includes_all(content, [
      "For the canonical advanced-setup support contract, see `docs/supported-surface.md`.",
      "Back-channel logout is the durable path.",
      "Front-channel logout is best effort only.",
      "Dynamic Client Registration now manages the same existing logout propagation metadata"
    ])
  end

  def assert_dynamic_registration_guide!(content) do
    assert_includes_all(content, [
      "For the canonical public support contract, see `docs/supported-surface.md`.",
      "These metadata fields manage the existing shipped logout runtime; they do not create a second logout system.",
      "Back-channel logout is the durable server-to-server path.",
      "Front-channel logout is best effort only"
    ])
  end

  def assert_maintainer_release_deference!(content) do
    assert_includes_all(content, [
      "docs/supported-surface.md",
      "does not define a second public support contract",
      "docs/mtls-host-guide.md",
      "docs/protect-phoenix-api-routes.md",
      "should not invent broader trust equivalence, automatic proxy trust, or generic deployment automation language here"
    ])
  end

  def assert_security_policy_deference!(content) do
    assert_includes_all(content, [
      "`docs/supported-surface.md` is the canonical public support contract.",
      "does not define a second feature or topology matrix",
      "the bounded reactive remote-`jwks_uri` verification path on the shipped direct-client surfaces",
      "the two shipped mTLS extraction patterns plus certificate-bound token enforcement after certificate extraction",
      "host Phoenix API route protection for Lockspire-issued access tokens through the documented `Lockspire.Plug.VerifyToken -> Lockspire.Plug.EnforceSenderConstraints -> Lockspire.Plug.RequireToken` pipeline",
      "Guarded remote JWKS fetch",
      "This fetch path exists only to verify `private_key_jwt` client assertions on Lockspire-owned direct-client endpoints.",
      "It is not a general outbound metadata-ingestion capability.",
      "Both DPoP and mTLS are supported sender-constraining mechanisms for FAPI 2.0."
    ])
  end

  def refute_broadened_security_non_claims!(content) do
    refute_includes_any(content, [
      "generic gateway protected-resource middleware is supported",
      "custom `Lockspire.MTLS.Extractor` implementations are first-class peers",
      "mTLS client authentication, and generic JWT client-auth support outside Lockspire-owned direct-client endpoints"
    ])
  end

  defp assert_includes_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      unless String.contains?(content, snippet) do
        raise "expected content to include #{inspect(snippet)}"
      end
    end)
  end

  defp refute_includes_any(content, snippets) do
    Enum.each(snippets, fn snippet ->
      if String.contains?(content, snippet) do
        raise "expected content to exclude #{inspect(snippet)}"
      end
    end)
  end
end

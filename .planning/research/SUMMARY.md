# Project Research Summary

**Project:** Lockspire v1.48 Client Authentication Key Isolation & Rotation (SEC-01)
**Researched:** 2026-10-25
**Source:** Product tree `1917aa61c589d25d3e2668f6ef0672f32ef0a388`; planning start `eb10874d`.
**Confidence:** High for inspected seams and the synthetic Plug.Crypto result; production compatibility/concurrency and main acceptance remain unverified.

## Key Findings

Use existing OTP/Plug/Ecto facilities; add no dependency or platform upgrade. Dedicated verifier keys must be independent of endpoint/session keys and signing-key KEKs. Current signing-envelope code is a useful implementation pattern but has a signing-specific label and binary format. Verifier storage is text, so use a distinct versioned text-safe envelope and authenticated canonical client identity. Direct registration and DCR currently generate secret material before client IDs; all writer paths must be adjusted coherently.

Keep explicit reader-first deployment and writer activation. A new node must not produce unreadable rows while old code remains. Maintenance must rewrap only verifier ciphertext under a real shared store/transaction authority, with per-row safety, unchanged hash/lifetime fields, truthful all-row status and typed unsupported-adapter failure. No request-time automatic migration or generic secrets platform is needed.

One synthetic probe against installed Plug.Crypto 2.2.1 confirmed a two-day-old authenticated payload fails the default age check. This qualifies a legacy-compatibility risk, not an observed adopter outage. Freeze its disposition before promising migration success; do not silently bypass age or change configured client/secret expiry. Preserve existing recovery by authorized secret rotation/reprovision.

## Implications for Roadmap

The owner approved four dependent outcomes as Phases 175–178 on 2026-10-25:

1. Accepted implementation baseline and finite custody/legacy-age/rollout/storage contract, with acceptance ownership.
2. Dedicated key custody and canonical production readers/writers, preserving existing crypto and protocol behavior.
3. Safe rewrap/check/status, concurrent update protection, install/upgrade guidance and key-loss recovery.
4. Package-installed fresh/upgrade/rotation/mixed-version proof, focused security/review, required contributor/CI gates and accepted-main delivery.

The owner has approved SEC-01-first selection and focused research. All 18 requirements and the four-phase roadmap are approved. Next: `$gsd-discuss-phase 175`; implementation entry remains gated on fresh exact-main acceptance. Inline investigation replaces subagent fan-out because no explicit subagent authorization was supplied; no independent agent review is claimed.

## Sources

- [Stack and representation](v1.48-client-auth-key-isolation/STACK.md), [capability scope](v1.48-client-auth-key-isolation/FEATURES.md), [architecture and alternatives](v1.48-client-auth-key-isolation/ARCHITECTURE.md), [failure modes and synthetic probe](v1.48-client-auth-key-isolation/PITFALLS.md), [entry baseline](v1.48-client-auth-key-isolation/BASELINE.md).
- [OTP 28 AEAD API](https://www.erlang.org/docs/28/apps/crypto/crypto.html#crypto_one_time_aead/7), [tagged Plug.Crypto v2.2.1 source](https://raw.githubusercontent.com/elixir-plug/plug_crypto/v2.2.1/lib/plug/crypto.ex), [PostgreSQL 14 text](https://www.postgresql.org/docs/14/datatype-character.html) and [locking](https://www.postgresql.org/docs/14/explicit-locking.html).
- [OIDC Core client authentication](https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication), [RFC 7523](https://www.rfc-editor.org/rfc/rfc7523.html), [NIST GCM](https://csrc.nist.gov/pubs/sp/800/38/d/final) and [key-management guidance](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final). These inform the design; no compliance/certification claim follows.
- Local files cited in the dimension reports, current `docs/supported-surface.md`, standing train/ranking/guide and retained v1.47 evidence. No package, browser, full product-test, hosted CI or fresh exact-main gate ran in this research.

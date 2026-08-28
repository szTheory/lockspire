---
phase: 133
slug: clean-room-saas-journey
status: secured
threats_total: 28
threats_closed: 28
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-27
---

# Phase 133 — Security Audit

## SECURED

**Phase:** 133 — Clean-Room SaaS Journey  
**Threats Closed:** 28/28  
**ASVS Level:** 1

Audit scope is the implementation through `7359d36`. This is an ASVS L1
presence-and-boundary audit. The prior DPoP post-restart flake is repaired:
the harness proves protected-resource readiness with a fresh proof, then sends
the unchanged original proof for the separate durable-replay assertion. Three
consecutive fresh focused DPoP journeys and the root full alias passed with the
restart-ready and durable-replay markers.

### Closed

| Threat ID | Category | Severity | Disposition | Evidence |
|---|---|---:|---|---|
| T-133-01 | package provenance | high | mitigate | `scripts/acceptance/clean_room/package_input.py:72-156` rejects symlinks/test support/checkouts, copies inventory, preserves manifests/locks, and invokes `deps.get --check-locked`. |
| T-133-02 | diagnostics/evidence disclosure | high | mitigate | `scripts/acceptance/clean_room/redaction.py:43-101` registers all secret classes and redacts free/structured headers; `clean_room_saas_journey.py:368-376` scrubs and sentinel-scans retained logs. |
| T-133-03 | process lifecycle DoS | medium | mitigate | `clean_room_saas_journey.py:195-230, 862-909` uses bounded readiness, process groups, TERM/KILL waits, database teardown, and signal handling. |
| T-133-04 | origin spoofing | medium | mitigate | `clean_room_saas_journey.py:155-163, 257-267` allocates distinct loopback ports and readiness checks hit the expected client/provider endpoints. |
| T-133-05 | provider-boundary privilege escalation | high | mitigate | `build_provider.py:118-162, 218-247` installs through public Mix/API seams then rejects internal protocol/storage/test-support/replacement-router seams. |
| T-133-06 | bootstrap credential disclosure | high | mitigate | `bootstrap.ex:22-56` creates separate bearer/DPoP channels at mode 0600; runner registers both before diagnostics (`clean_room_saas_journey.py:354-365`). |
| T-133-07 | protected-route privilege escalation | high | mitigate | `router_patch.exs:17-28` applies exact audience/scope verification, sender constraints, then token requirement; `billing_controller.ex:7-28` makes host policy separate. |
| T-133-08 | redirect-URI tampering | high | mitigate | `bootstrap.ex:34-46` registers one explicit callback per client and `clean_room_saas_journey.py:574-584` exercises live redirect drift rejection. |
| T-133-09 | callback state spoofing/tampering | critical | mitigate | `transactions.ex:27-42` atomically transitions matching unexpired pending state before exchange; `oauth_controller.ex:57-106` consumes it before `complete_journey/3`. |
| T-133-10 | ID-token spoofing | critical | mitigate | `oidc_verifier.ex:5-48` pins issuer/discovery algorithms, excludes `none`, selects exact `kid`, verifies strictly, and checks aud/exp/nonce/sub. |
| T-133-11 | userinfo spoofing | high | mitigate | `oauth_controller.ex:143-148, 196-201` fetches userinfo after ID-token validation and requires exact subject equality. |
| T-133-12 | transaction/error disclosure | high | mitigate | `oauth_controller.ex:92-105, 211-214` retains only fixed stage names; runner `safe_oauth_error_code/1` allowlists OAuth error tokens and never renders raw response bodies. |
| T-133-13 | cross-origin callback spoofing | critical | mitigate | `clean_room_saas_journey.py:379-435` follows distinct-origin cookie/login/consent redirects; `:consume` before exchange is enforced at `oauth_controller.ex:57-78`. |
| T-133-14 | protected-API escalation | high | mitigate | `oauth_controller.ex:124-156` reaches resource only after discovery/JWKS/ID-token/userinfo; provider route and host policy are independently enforced at `router_patch.exs:17-40`. |
| T-133-15 | journey-assertion disclosure | high | mitigate | `clean_room_saas_journey.py:437-447, 693-706` allowlists safe receipt fields and rejects confidential keys; redaction is centralized. |
| T-133-16 | refresh-family escalation | critical | mitigate | `clean_room_saas_journey.py:518-552` performs live rotation, old-token replay, invalid-grant, and inactive-family introspection checks. |
| T-133-17 | code/state/nonce/redirect tampering | critical | mitigate | `clean_room_saas_journey.py:565-629` exercises live redirect, code reuse, pre-exchange state, nonce, missing-token, audience, and scope rejection. |
| T-133-18 | audience/scope escalation | high | mitigate | `router_patch.exs:17-26` declares exact audience/scope; `clean_room_saas_journey.py:618-629` asserts 401 invalid-token and 403 insufficient-scope challenges. |
| T-133-19 | lifecycle repudiation | medium | mitigate | `clean_room_saas_journey.py:518-552` asserts authorization-server rotation/introspection/revocation behavior only; it makes no offline-JWT invalidation claim. |
| T-133-20 | DPoP proof spoofing/elevation | critical | mitigate | `dpop.ex:24-43` constructs exact `htu`/`htm`/`ath`/nonce proofs; `journey_controller.ex:17-83` performs fresh resource proof then stored exact-proof replay; `clean_room_saas_journey.py:785-819` separately asserts exact and post-restart rejection. Three fresh focused passes and `mix test.clean-room.e2e` passed. |
| T-133-21 | replay-persistence tampering | high | mitigate | Provider resources select Ecto `Repository` by default (`protected_resource_dpop.ex:139-170,293-297`; `repository.ex:465-515`). After restart, `clean_room_saas_journey.py:719-819` waits only for a fresh-proof protected-resource readiness receipt, then submits the original encrypted proof; all reported focused/full runs rejected it. |
| T-133-22 | CI evidence disclosure | high | mitigate | `redaction.py:43-101` plus `clean_room_saas_journey.py:368-376` redact before retained evidence and reject raw Authorization/Cookie values. |
| T-133-23 | CI teardown DoS | medium | mitigate | `clean_room_saas_journey.py:50-58, 195-230, 862-909` traps signals, owns process groups/temporary roots, uses bounded waits, and drops both databases. |
| T-133-24 | DPoP-client selection escalation | high | mitigate | `bootstrap.ex:14-28` updates only the dedicated DPoP client through `Lockspire.Admin`; fixed routes and `@profiles` in `oauth_controller.ex:5-23` never accept caller-selected credentials. |
| T-133-25 | child dependency-cache tampering | high | mitigate | `package_input.py:111-156` confines cache below an allowed root and role-scopes it; CI cache key includes both child locks (`.github/workflows/ci.yml:293-314`). |
| T-133-26 | DPoP material disclosure | critical | mitigate | `dpop.ex:18-51` encrypts key/token state; `transactions.ex:70-104` clears terminal copies; `journey_controller.ex:17-83` returns only safe receipts. |
| T-133-27 | DPoP nonce-domain spoofing | critical | mitigate | `oauth_controller.ex:218-291` generates endpoint-specific token/userinfo proofs and nonce retries; `journey_controller.ex:17-51` stores and consumes only the resource nonce with fresh proof/ath. |
| T-133-28 | opaque DPoP-session escalation | high | mitigate | `transactions.ex:70-91, 106-135` atomically transfers to a random handle and clears transaction key material; `journey_controller.ex:85-91` resolves only the session handle from server session state. |

### Threat Flags

No `## Threat Flags` section is present in any Phase 133 plan summary. No
unregistered implementation flag was found during this register-based audit.

### OAuth/OIDC and Harness Defaults Checked

- PKCE S256 is generated by the client (`oauth_controller.ex:318-333`) and
  live lifecycle requests use `code_challenge_method=S256`.
- Redirect URIs are exact registered callbacks; the negative journey rejects a
  drifted URI before authorization.
- Client secrets are written to distinct 0600 files and are absent from safe
  receipts/evidence scans.
- Browser and DPoP operation routes fetch a server session and run
  `protect_from_forgery` (`router.ex:5-42`); the DPoP runner asserts a missing
  CSRF token receives 403 before resource operations.
- Dynamic origins are loopback-only and allocate per run; run-root markers
  prevent another runner from owning teardown.
- Child provider/client databases, processes, logs, cache paths, and temporary
  roots are all run-owned and released in `finally` cleanup.
- CI uses no Phase 133 plaintext OAuth credential; only the bounded,
  lock-hashed external dependency cache is retained.

**threats_open:** 0

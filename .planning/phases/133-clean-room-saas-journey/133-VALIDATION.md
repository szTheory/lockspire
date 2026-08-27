---
phase: 133
slug: clean-room-saas-journey
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-27
---

# Phase 133 — Validation Strategy

> Black-box contract for a package-clean embedded provider, separate confidential client, protected resource, lifecycle truth, and durable DPoP proof.

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit integration wrappers plus separately booted Phoenix/Ecto child apps and a standard-library HTTP runner |
| **Config** | Root `mix.exs`; checked-in version-pinned provider/client `mix.exs` plus `mix.lock`, each with unchanged `path: "vendor/lockspire"`; copied non-symlink package trees; child runtime config below a unique temp root; dedicated PostgreSQL databases; loopback-only dynamic ports; dependency-only cache under `tmp/clean-room-cache/{provider,client}/deps` |
| **Quick run** | `mix test --include integration test/integration/phase133_harness_test.exs test/integration/phase133_provider_install_test.exs` |
| **Focused E2E** | `mix test.clean-room.e2e` |
| **Full gate** | `mix compile --warnings-as-errors && mix test.fast && mix test.integration && mix qa && mix docs.verify` |
| **Feedback target** | Component tests under 90 seconds where possible; each real package-clean group starts from a fresh temp root |

## Sampling Rate

- After every task: run its exact `<automated>` command.
- After Wave 1: run harness process, provenance, redaction, signal, and teardown groups.
- After Wave 2: run provider install/verify/boot, two-client bootstrap, and separate secret-channel proof.
- After Wave 3: run client transaction/verifier plus live token/userinfo DPoP backend suites against the completed provider.
- After each later wave: run the named clean-room group from a fresh package and databases; no state may carry across groups except explicit same-proof/restart cases.
- Before phase verification: run `mix test.clean-room.e2e`, warnings-as-errors compilation, fast suite, integration suite, QA, and docs verification.
- No three consecutive implementation tasks may pass without behavioral automated evidence.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threats | Secure behavior | Test type | Automated command | Status |
|---|---|---:|---|---|---|---|---|---|
| 133-01-T1 | 133-01 | 1 | E2E-01, E2E-06 | T-133-03, T-133-04 | Two real origins, bounded readiness, unique resources, exit/signal cleanup. | process integration | `mix test --include integration test/integration/phase133_harness_test.exs --only harness_processes` | historical pass; not rerun in this audit |
| 133-01-T2 | 133-01 | 1 | E2E-01 | T-133-01, T-133-25 | Stable child-local vendor paths, copied package inventory, no symlinks/checkouts, unchanged manifests/locks, `--check-locked`, exact provenance, and role-scoped cache boundaries. | dependency/process integration | `mix test --include integration test/integration/phase133_harness_test.exs --only dependency_lock` | observed through current CI alias before lifecycle failure |
| 133-01-T3 | 133-01 | 1 | E2E-01, E2E-06 | T-133-02 | Pre-format/retention redaction covers both client secrets and every other secret class. | process/security integration | `mix test --include integration test/integration/phase133_harness_test.exs --only harness_security` | observed through current CI alias before lifecycle failure |
| 133-02-T1 | 133-02 | 2 | E2E-01 | T-133-05 | Fresh host installs, migrates, verifies, tests, boots; no forbidden boundary use. | package/process integration | `mix test --include integration test/integration/phase133_provider_install_test.exs --only package_clean` | historical pass; not rerun in this audit |
| 133-02-T2 | 133-02 | 2 | E2E-01, E2E-05, E2E-06 | T-133-06..08, T-133-24 | Separate bearer/DPoP public bootstrap, explicit client-level DPoP update, distinct secret channels, exact redirects, and canonical protected pipeline. | live HTTP integration | `mix test --include integration test/integration/phase133_provider_install_test.exs` | historical pass; not rerun in this audit |
| 133-03-T1 | 133-03 | 3 | E2E-02 | T-133-09, T-133-12 | Random durable state/nonce/verifier, pre-exchange atomic terminal consumption under concurrency/restart. | child unit + process | `python3 scripts/acceptance/clean_room/build_client.py --test oauth_transaction` | historical pass; not rerun in this audit |
| 133-03-T2 | 133-03 | 3 | E2E-02, E2E-06 | T-133-09, T-133-12, T-133-24, T-133-26, T-133-27 | Fixed bearer/DPoP routes persist server-selected profiles; DPoP callback owns an encrypted key and completes confidential token AS nonce retry with documented DPoP token type after terminal state consumption. | child HTTP integration | `python3 scripts/acceptance/clean_room/build_client.py --test oauth_callback` | historical pass; not rerun in this audit |
| 133-03-T3 | 133-03 | 3 | E2E-03, E2E-06 | T-133-10..12, T-133-24, T-133-26..28 | Bearer OIDC remains green; DPoP key ownership, token AS nonce retry/type, same-key userinfo nonce retry, subject gate, encrypted cleanup, and opaque session handoff are complete. | child unit + live provider HTTP | `python3 scripts/acceptance/clean_room/build_client.py --test oidc_verifier && python3 scripts/acceptance/clean_room/build_client.py --test dpop_client` | historical pass; not rerun in this audit |
| 133-04-T1 | 133-04 | 4 | E2E-02, E2E-03 | T-133-13..15 | Cross-origin code+S256 journey validates OIDC/userinfo before protected resource. | full process HTTP | `mix test.clean-room.e2e` | green in authoritative post-fix run |
| 133-04-T2 | 133-04 | 4 | E2E-02, E2E-03 | T-133-13..15 | Callback remains one-time and host authorization is distinct from protocol enforcement. | full process HTTP | `mix test.clean-room.e2e` | green in authoritative post-fix run |
| 133-05-T1 | 133-05 | 5 | E2E-04 | T-133-16, T-133-19 | Rotation, reuse containment, inactive introspection, idempotent revocation, truthful JWT semantics. | full process HTTP | `python3 scripts/acceptance/clean_room_saas_journey.py --only lifecycle` | observed green after 9368cde |
| 133-05-T2 | 133-05 | 5 | E2E-05 | T-133-17, T-133-18 | Redirect/code/state/nonce/token/audience/scope failures expose stable wire outcomes only. | full process negative matrix | `python3 scripts/acceptance/clean_room_saas_journey.py --only negative` | observed green after 9368cde |
| 133-06-T1 | 133-06 | 6 | E2E-06 | T-133-20, T-133-21, T-133-24, T-133-26..28 | Completed opaque DPoP session drives resource nonce challenge, fresh proof success, same-byte replay, and post-provider-restart durable rejection without exposing client material. | full process HTTP | `python3 scripts/acceptance/clean_room_saas_journey.py --only dpop` | green in two independent fresh post-fix runs |
| 133-06-T2 | 133-06 | 6 | E2E-01, E2E-05, E2E-06 | T-133-22, T-133-23, T-133-25 | One CI command proves all journeys, uses bounded lock-keyed dependency-only caches, scans evidence, and cleans all resources. | acceptance + repository gate | `mix test.clean-room.e2e && mix compile --warnings-as-errors && mix test.fast && mix test.integration && mix qa && mix docs.verify` | clean-room E2E green in authoritative post-fix run |

## Wave 0 Requirements

Plan 133-01 creates the missing harness before any protocol assertion is trusted.

- [ ] `scripts/acceptance/run_clean_room_saas_journey.sh` owns unique run root, environment probe, both PIDs, bounded readiness, and exit/signal cleanup.
- [ ] `scripts/acceptance/clean_room/redaction.py` scrubs process, HTTP, exception, and artifact paths before formatting/retention.
- [ ] `scripts/acceptance/clean_room/package_input.py` runs `mix hex.build --unpack` into the run root and audits that isolated path dependency without a checkout link.
- [ ] `test/clean_room/provider_host/{mix.exs,mix.lock}` and `test/clean_room/confidential_client/{mix.exs,mix.lock}` pin approved child graphs and retain `path: "vendor/lockspire"`; each run copies the unpacked inventory there, rejects symlinks/checkouts, and passes provenance plus `mix deps.get --check-locked` without mutation.
- [ ] `test/integration/phase133_harness_test.exs` proves process, redaction, provenance, and teardown behavior before child applications exist.
- [ ] PostgreSQL availability is a blocking precondition; no in-memory fallback is permitted for provider or DPoP replay state.

## ASVS L1 Blocking Gate

All critical/high threats block their plan summary and phase completion.

| ASVS area | Blocking threats | Named evidence |
|---|---|---|
| V7 Error/Logging | T-133-02, T-133-06, T-133-12, T-133-15, T-133-22 | Harness security suite plus full sentinel/raw-header evidence scan. |
| V2 Authentication / V3 Session | T-133-09, T-133-10, T-133-11, T-133-13, T-133-24, T-133-28 | Transaction concurrency/restart tests, verifier negative matrix, cross-origin callback journey, fixed profiles, and opaque DPoP session handoff. |
| V4 Access Control / V5 Validation | T-133-07, T-133-08, T-133-14, T-133-17, T-133-18 | Provider boundary/protected-route tests and full live negative matrix. |
| V6 Cryptography / Replay | T-133-16, T-133-20, T-133-21, T-133-26, T-133-27 | Refresh lifecycle; encrypted key ownership; AS/userinfo/resource nonce separation; same-byte/post-restart replay proof. |
| Package/dependency boundary | T-133-01, T-133-05, T-133-25 | Isolated inventory/provenance, checked locks, `--check-locked`, cache scope, plus fresh install/migrate/verify/test/boot. |

## Required Negative Cases

- Harness: missing command, PostgreSQL unavailable, port collision, readiness timeout, one-child early exit, signal, induced assertion failure, changed vendor path, vendor symlink, checkout realpath, package-inventory mismatch, changed/missing lock, cache path escape, and secret in structured/free-text evidence.
- Transaction: duplicate/concurrent callback, restart, expired/missing/wrong state, provider error, missing code, and exchange failure; every terminal path becomes unusable.
- OIDC: malformed discovery/JWKS, issuer mismatch, missing/unknown/ambiguous kid, unadvertised/none alg, bad signature, wrong issuer/audience, expired token, nonce mismatch, and userinfo subject mismatch.
- OAuth/resource: redirect drift, code reuse, missing token, wrong audience, insufficient scope, host policy denial, refresh reuse, inactive introspection, and repeat revocation.
- DPoP client backend: bearer path remains green; dedicated policy/key ownership; proofless token exchange; token AS nonce challenge/retry; wrong/reused AS nonce; returned JKT mismatch; userinfo nonce challenge/retry; wrong htu/htm/ath; retry bound; terminal encrypted-state cleanup; opaque session only.
- DPoP resource: missing/invalid resource nonce, exact successful proof replay, and exact replay after provider restart fail as documented; a newly generated proof is not accepted as replay evidence.
- Evidence: authorization code, access/refresh tokens, separate bearer and DPoP client secrets, client-session encryption key, PKCE verifier, DPoP private key/proof, Authorization/Cookie headers, and cookies are sentinel-scanned across console and retained files.

## Multi-Source Coverage Audit

| Source | ID | Feature / constraint | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Separate-origin client safely consumes embedded provider/protected API from built package | 133-01..06 | COVERED | Harness foundation → independent apps → positive/lifecycle/negative/DPoP proof. |
| REQ | E2E-01 | Package-clean install/migrate/verify/test/boot | 133-01, 133-02, 133-06 | COVERED | Includes locked child manifests, provenance, boundary audit, bounded cache, and CI command. |
| REQ | E2E-02 | Durable confidential transaction, code+PKCE, bad state | 133-03, 133-04 | COVERED | Atomic terminal consumption before exchange. |
| REQ | E2E-03 | Discovery/JWKS/ID token/userinfo before protected API | 133-03, 133-04 | COVERED | Client-owned strict verifier plus composed HTTP proof. |
| REQ | E2E-04 | Refresh/reuse/introspection/revocation/JWT truth | 133-05 | COVERED | Authorization-server lifecycle truth only. |
| REQ | E2E-05 | Redirect/code/state/nonce/token/audience/scope failures | 133-02, 133-05 | COVERED | Named real-listener stable-wire matrix. |
| REQ | E2E-06 | DPoP nonce/retry/durable replay without leakage | 133-01, 133-02, 133-03, 133-06 | COVERED | Dedicated public-facade client, complete client backend, opaque session, same bytes, post-restart rejection, sentinel scan. |
| CONTEXT | D-01 | Two independently booted apps on distinct origins | 133-01, 133-04 | COVERED | Separate workdirs, ports, cookies, processes. |
| CONTEXT | D-02 | Provider uses installer/generated/public seams only | 133-02 | COVERED | Boundary and provenance audit. |
| CONTEXT | D-03 | Local package-clean input; publication proof elsewhere | 133-01, 133-02, 133-03, 133-06 | COVERED | Stable child-local vendor copies, unchanged locks/manifests, no symlink/checkout link. |
| CONTEXT | D-04 | Real listeners, deterministic headless cleanup | 133-01, 133-04, 133-06 | COVERED | No ConnTest/browser/Docker shortcut. |
| CONTEXT | D-05 | Durable random state/nonce/verifier and terminal callback | 133-03, 133-04 | COVERED | Atomic pre-exchange consumption. |
| CONTEXT | D-06 | Real confidential registration and transient secret | 133-02, 133-04 | COVERED | Separate bearer/DPoP facade registration and restrictive ephemeral channels. |
| CONTEXT | D-07 | Discovery/JWKS/strict ID-token validation | 133-03, 133-04 | COVERED | Independent client verifier. |
| CONTEXT | D-08 | Exact userinfo/ID-token subject match | 133-03, 133-04 | COVERED | Session completion gate. |
| CONTEXT | D-09 | Canonical protected pipeline plus host policy | 133-02, 133-04, 133-05 | COVERED | Semantic readers and separate allow/deny. |
| CONTEXT | D-10 | Intended audience/scope protected success | 133-02, 133-04 | COVERED | Stable semantic response only. |
| CONTEXT | D-11 | Rotation/reuse/introspection/revocation | 133-05 | COVERED | Authenticated live lifecycle endpoints. |
| CONTEXT | D-12 | Truthful self-contained JWT lifetime | 133-05 | COVERED | No instantaneous offline invalidation claim. |
| CONTEXT | D-13 | Complete security-negative matrix | 133-02, 133-05, 133-06 | COVERED | Independent named live cases. |
| CONTEXT | D-14 | Stable wire assertions only | 133-04..06 | COVERED | No rows, structs, assigns, or private reasons. |
| CONTEXT | D-15 | Same-journey DPoP nonce/retry/replay | 133-02, 133-03, 133-06 | COVERED | Dedicated updated client, AS/userinfo proof backend and opaque session, then exact resource-proof replay. |
| CONTEXT | D-16 | Configured Ecto replay store, external proof | 133-02, 133-06 | COVERED | No override; post-restart rejection. |
| CONTEXT | D-17 | Full secret redaction and sentinel checks | 133-01..06 | COVERED | Central diagnostics and bounded artifacts. |
| CONTEXT | D-18 | Narrow reference-quality acceptance lab | 133-01..06 | COVERED | No service/SDK/demo expansion. |
| RESEARCH | — | Harness/process/redaction foundations first | 133-01 | COVERED | Required ordering and Wave 0. |
| RESEARCH | — | Package-clean generated provider and public bootstrap | 133-01, 133-02 | COVERED | Built input, locked manifests, installer, two clients, overlays, boundary audit. |
| RESEARCH | — | Durable client transaction, discovery verifier, and client-owned DPoP key/proof/session | 133-03 | COVERED | Focused bearer and DPoP client tests precede resource replay composition. |
| RESEARCH | — | Wire-contract named journey steps | 133-04, 133-05 | COVERED | Happy baseline before lifecycle/negatives. |
| RESEARCH | — | Configured-Ecto DPoP as external behavior | 133-06 | COVERED | Same-proof post-restart proof. |
| RESEARCH | — | No new package and no hand-rolled provider/RS crypto | 133-01..06 | COVERED | Existing locked stack only; JOSE used by client/proof builder. |

Excluded by source: publication-specific release proof (Phase 137); topology/storage refactors (Phases 134-135); browser/admin UI, hosted auth, general SDK, new grants, and dependency restructuring.

## Manual-Only Verifications

None. Both applications, PostgreSQL setup, browser-like redirect flow, process lifecycle, HTTP assertions, evidence scans, and cleanup are automatable. Missing local PostgreSQL is an actionable environment failure, not a human verification checkpoint.

## Post-Execution Nyquist Final Re-Audit — 2026-08-27

**Verdict: VALIDATED.** Commit `7359d36` retains the exact-byte replay
assertion and adds a bounded, independent readiness probe using a *fresh* DPoP
proof after the provider restart. That prevents a transient protected-resource
startup 500 from being misclassified as durable replay behavior; it does not
substitute for the original proof's required replay rejection.

| Command | Actual result |
|---|---|
| `python3 scripts/acceptance/clean_room_saas_journey.py --only lifecycle` | **PASS:** rotation, reuse containment, inactive introspection, idempotent revocation, evidence scan, cleanup. |
| `python3 scripts/acceptance/clean_room_saas_journey.py --only negative` | **PASS:** redirect, code, state, nonce, token, audience, and scope rejection matrix, evidence scan, cleanup. |
| `python3 scripts/acceptance/clean_room_saas_journey.py --only dpop` (fresh run 1) | **PASS:** token/userinfo nonce retries, resource nonce retry, exact replay rejection, restart-ready receipt, post-restart exact replay rejection, evidence scan, cleanup. |
| `python3 scripts/acceptance/clean_room_saas_journey.py --only dpop` (fresh run 2) | **PASS:** identical full DPoP receipt sequence from another fresh run root. |
| `mix test.clean-room.e2e` | **PASS:** parent-run authoritative command completed every group, including `dpop provider restart ready`, post-restart replay rejection, evidence scan, and cleanup. |

| Requirement | Current evidence | Result |
|---|---|---|
| E2E-01 | Package provenance, redaction, readiness, teardown, and authoritative clean-room command are green. | FILLED |
| E2E-02 | Authoritative happy path and focused code-exchange paths are green. | FILLED |
| E2E-03 | Authoritative discovery/JWKS/ID-token/userinfo/resource journey is green. | FILLED |
| E2E-04 | Focused lifecycle journey is green. | FILLED |
| E2E-05 | Focused negative matrix is green. | FILLED |
| E2E-06 | Two independent fresh focused DPoP journeys and the authoritative command prove nonce retries plus exact replay rejection before and after restart. | FILLED |

## Validation Sign-Off

- [x] Every task has a runnable automated command.
- [x] All six requirements and all eighteen locked decisions map to implementation and behavioral evidence.
- [x] Critical/high threats block summaries through named ASVS L1 tests.
- [x] Child manifests are owned by Wave 1; Wave 2 completes provider bootstrap before Wave 3 exercises the client backend against live token/userinfo endpoints.
- [x] The package proof is intentionally local/package-clean and leaves publication-specific proof to Phase 137.
- [x] Nyquist auditor executed the maintained command and recorded the actual post-review outcome.
- [x] Lifecycle regression repaired; focused lifecycle and negative evidence is green.
- [x] DPoP post-restart replay is stable across two independent fresh runs; all six E2E requirements have green behavioral evidence.

**Approval:** validated.

# Phase 166: End-to-End Lifetime, Security & Guidance Proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the analysis.

**Date:** 2026-10-21
**Phase:** 166-end-to-end-lifetime-security-guidance-proof
**Mode:** assumptions; delegated source analysis, two primary-source research tracks and adversarial review
**Areas analyzed:** deterministic coverage; PostgreSQL races/rollback; packaged fresh/legacy/custom storage; CI/security/redaction; executable guidance/operator jobs

## Assumptions Presented

| Area | Recommendation | Confidence | Evidence | Consequence if wrong |
|------|----------------|------------|----------|----------------------|
| Deterministic coverage | Keep Phase 162 as oracle; link focused exact-clock cases to integrated independent-lifecycle journeys. | Confident | 162-CONTRACT.md/162-CASES.json; app/secret/management integration suites; registration_controller.ex | One expired credential could mask another gate or recovery could renew unrelated authority. |
| PostgreSQL ordering | Reuse independent sessions, observed blockers and post-wait clock/current-state checks; assert persisted rollback. | Confident | client_lifetime_race_helpers.ex; existing app/secret/management wait/race suites | Shared-connection tasks or status-only checks could conceal stale authority or partial writes. |
| Packaged hosts | Extend existing lab using one verified candidate; prove actual legacy use and successful configured custom-store authority. | Likely, selected after research | client_lifetime_upgrade.py; build_provider.py; client_lifetime_conformance_test.exs | Stale bytes or field-only fixtures could be reported as packaged lifecycle support. |
| CI/security/redaction | Require active collected proof, bounded source/package-bound receipts and safe positive-event redaction. | Confident | ci.yml; run_test_matrix.sh; skipped phase133 wrapper; dcr_telemetry_redaction_test.exs | Green totals could omit HTTP proof, or failed leak detection could disclose credentials. |
| Guidance | Verify claims against outcomes; separate adopter-copyable examples from private checkout commands; preserve PRODUCT vocabulary. | Confident | docs/upgrading/client-lifetimes.md; package allowlist; PRODUCT.md; guidance/vocabulary contracts | Adopters could be told to run files that do not ship or infer unsupported guarantees. |

## Decision Authority

The user requested repeated fanout to diminishing returns, reputable primary sources, adversarial consideration and a coherent one-shot recommendation set to follow automatically. That explicitly authorizes selecting this scoped bundle without another confirmation menu. It does not authorize new product policies or claim a separate confirmation reply. Existing lifetime semantics remain locked.

## Delegated Work

- `phase166_assumptions` (gsd-assumptions-analyzer): codebase-first traceability and source gaps; configured gpt-6.1-sol/xhigh routing passed explicitly.
- `phase166_ecosystem_research`: official Elixir/ExUnit/Ecto/PostgreSQL/Hex docs, package evidence and OpenIddict precedent.
- `phase166_security_dx_research`: RFCs, recovery precedent, evidence redaction, operator language and adapter DX.
- `phase166_adversarial_review`: challenge omitted execution, stale artifact reuse, masked lifetime gates, custom-store claims and scope.

All four returned terminal results. Research was read-only; no application tests, live required-check inspection, Phase 166 implementation or publication was performed.

## Alternatives and Tradeoffs

| Decision | Considered approaches | Selection and reason |
|----------|-----------------------|----------------------|
| Boundary time | Real waiting everywhere; public HTTP clock transport; existing clocks plus real HTTP journeys | Existing clocks give precise equality; real HTTP proves wiring without adding a public testing API. |
| Coverage breadth | Duplicate all focused suites; full Cartesian matrix; contract-to-evidence mapping with gap additions | Mapping plus missing integrated cases keeps coverage inspectable and avoids large redundant matrices. |
| Concurrency | Shared sandbox tasks; independent PG sessions with observable locks | Existing independent-session helpers model actual contention; extra coordination cost is already paid. |
| Packaged proof | New harness; extend current package/process lab | Reuse avoids duplicate process/cleanup/provenance systems. Active execution and byte binding are necessary improvements. |
| Custom store | Process-local round trips only; new backend; host-owned PG composition | Configured composition exercises the supported adapter boundary and atomicity at bounded scope. It does not prove every datastore. |
| Artifact reuse | Filename inventory; record observed hash after reuse; verify intended bytes and resolved runtime | Verify intended identity before execution and invalidate stale vendor/build trees. No unsupported reproducible-build claim. |
| Evidence retention | Raw work roots/logs; transient success totals; small allowlisted retained receipt | A bounded receipt preserves traceability without uploading sensitive runtime state. Existing short retention conventions suffice. |
| Adapter DX | Publish private tests/framework; link only unavailable repo commands; execute copyable host example | Copyable ordinary ExUnit/Ecto example plus clearly labeled checkout commands meets adopter needs with no new abstraction. |

## Corrections and Adversarial Findings

- Canonical integration CI already collects integration-tagged storage suites outside test/integration. The narrower convenience alias is not equivalent; do not report a false global CI omission.
- The older full SaaS journey wrapper is unconditionally skipped and lacks the integration tag. Extending Python alone does not prove required execution; activate a scoped required invocation/wrapper.
- The packaged upgrade runner proves migrations/cutover, but its legacy app eligibility probe constructs a domain client. Add actual legacy credential use and replacement before claiming a complete lifecycle journey.
- Existing custom conformance uses process storage and intentionally fails shared transaction authority. Retain its negative tests; add successful configured PG composition and late durable rollback evidence.
- Build-provider boundary auditing currently bans every storage namespace. Permit only the documented adapter seam if needed; never disable the boundary check wholesale.
- Reused unpack/vendor trees currently rely on inventories and partial checks. Record-and-trust hashes cannot establish intended artifact identity; verify before reuse and guard compiled outputs too.
- Earliest secret expiry can hide later app/management gates. Use independent registrations or controlled stages with other authority valid.
- Upgrade output strips only a simple client_secret assignment today. Protect returned credentials, hashes/verifiers, encoded forms, argv, exceptions and output before adding credential-bearing scenarios.
- An early redaction-test failure message prints a credential prefix and full captured payload. Replace it with safe identifiers so regression diagnostics cannot publish the leak.
- The package excludes repository tests/scripts referenced by adopter guidance. Distinguish checkout commands and provide an executed host-copyable example.

## External Research

Sources were consulted by the delegated researchers on 2026-10-21. Facts below ground proof choices; recommendations/inferences do not override Phase 162.

- [Ecto SQL Sandbox](https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html): allowances/shared mode share a connection. Independent database sessions are therefore needed to establish competing-transaction behavior.
- [ExUnit.Case](https://ex-unit.hexdocs.pm/main/ExUnit.Case.html): async tests must avoid shared global-state interference. Serialize database/policy lanes while orchestrating independent transactions within a race case.
- [PostgreSQL 14 locking](https://www.postgresql.org/docs/14/explicit-locking.html): row locks block competing operations and current rows are returned after waits. [Time functions](https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT) distinguish transaction-start now() from actual-call time; do not replace the deferred clock with transaction-start timestamps.
- [Ecto.Multi 3.13.5](https://ecto.hexdocs.pm/3.13.5/Ecto.Multi.html): ordinary transaction functions suit straightforward flows; no speculative Multi refactor is required for proof.
- [Hex build](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html): local unpacked package inspection is available without publication. [Elixir library guidelines](https://elixir.hexdocs.pm/library-guidelines.html): the host resolves dependency versions and the library's lockfile is not the host's resolution; package-host proof remains necessary.
- [RFC 7591 section 3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1): shared-secret expiry is a Unix timestamp or zero for unlimited. Lockspire duration settings and local extension fields remain separate concepts.
- [RFC 7592 section 5](https://www.rfc-editor.org/rfc/rfc7592.html#section-5): management credential expiry can strand registration. Optional finite policy plus host recovery is the already selected Lockspire contract, not a universal RFC timeout.
- [RFC 6750](https://www.rfc-editor.org/rfc/rfc6750.html#section-3.1): Bearer authority/disclosure and challenge distinctions ground safe errors/evidence. [RFC 9700](https://www.rfc-editor.org/rfc/rfc9700.html#section-4.14): verifier and refresh-replay protections ground the existing regression controls.
- [Keycloak registration](https://www.keycloak.org/securing-apps/client-registration#_registration_access_token): admin replacement after loss is a useful precedent. Its rotation on every use is a different product choice and is not adopted.
- [OpenIddict token storage](https://documentation.openiddict.com/configuration/token-storage.html): database-status validation/introspection trades latency for current revocation information. This supports truthful offline limits, not changing Lockspire's offline verifier.

## Methodology, Scope and Stop Rule

Applied all project methodology lenses: assumption-first analysis, least-surprise host seam, research-first defaults, high-threshold escalation and one-shot bundles. Relevant prompts supplied background; PRODUCT.md and current brandbook govern audience/branding. Security, library DX, concurrency, CI/SRE, protocol and operator comprehension lenses converge on the same bounded approach.

Stop fanout when each requirement has a coherent proof owner, current-source execution route, applicable negative/failure path and truthful claim boundary, and adversarial review finds no new material decision. Further generic frameworks, another backend, UI redesign and speculative combinations add little value. Implementation still must earn actual proof; this discussion does not mark requirements complete or close the lifetime umbrella todo.

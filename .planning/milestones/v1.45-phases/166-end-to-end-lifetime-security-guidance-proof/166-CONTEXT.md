# Phase 166: End-to-End Lifetime, Security & Guidance Proof - Context

**Gathered:** 2026-10-21 (assumptions mode; delegated analysis, primary-source research and adversarial review)
**Status:** Ready for planning
**Decision authority:** The user requested broad/deep subagent research, a coherent recommendation bundle and automatic adoption of the recommendations. These decisions use that authority; they do not imply a separate confirmation response. No Phase 166 implementation or verification has been performed by this discussion.

<domain>
## Phase Boundary

Close DCR-15 through DCR-19 with reproducible cross-phase lifetime journeys, real PostgreSQL ordering/rollback evidence, packaged fresh/legacy/custom-storage hosts, preserved security defaults and redaction, required CI and truthful adopter/operator guidance. The verified Phase 162 contract is the oracle; Phases 163–165 supply implemented behavior and focused proof. Preserve Lockspire's embedded-library shape and host-owned accounts, staff authorization, account UX and policy. Package publication is a separate step.
</domain>

<decisions>
## Implementation Decisions

### Contract coverage and deterministic time

- **D-01:** Use `162-CONTRACT.md` and `162-CASES.json` as the fixed expected behavior. Build a compact traceability matrix from DCR-15–19 and the applicable contract cases to focused tests, cross-phase journeys, race schedules and retained evidence. Distinguish inherited focused proof from new integrated proof; rerun applicable evidence against the final candidate. Add only demonstrated missing cases, avoiding duplicate suites and a Cartesian product of every dimension.
- **D-02:** Cover all three independent lifetimes across nil/zero/positive policy, before/equality/after expiry, issuance-time policy snapshots, changed-policy replacement, non-secret methods, provenance, legacy promotion and disabled-versus-expired apps. Prove interactions: management replacement/recovery does not renew app/secret deadlines; secret rotation does not renew app/management deadlines; reads do not renew; enabling does not clear expiry. Preserve the distinct secret-rotation and management-token contention contracts.
- **D-03:** Use existing injectable protocol clocks for exact equality and post-lock decision time. Pair that deterministic proof with real packaged HTTP behavior. The registration controller has no caller-supplied clock: do not add public time headers, replace production routes or introduce a time library solely for acceptance. Any lab-only setup/time control stays isolated to the host test environment, uses documented seams where available, and must not masquerade as an adopter API or as real-time boundary proof.
- **D-04:** Use separate registrations or controlled stages so an earlier secret/token deadline cannot mask the app or other credential gate being tested. Include valid management GET/DELETE versus forbidden PUT for naturally expired enabled apps, disabled-app denial, recovery preserving unrelated deadlines, rejected redemption preserving the grant/code, and matching stored/wire/enforced expiry. Keep independent JWT assertion timing/replay controls and online-versus-offline token behavior visible.

### PostgreSQL authority, races and rollback

- **D-05:** Reuse existing independent-session PostgreSQL helpers and focused suites. Show distinct backend sessions and the actual blocking relationship before releasing a lock holder; evaluate time and current identity/state after all relevant waits. Coordination polling may observe locks, but sleeps cannot establish expiry or race ordering. Shared SQL Sandbox tasks are not independent-transaction proof.
- **D-06:** Link each required schedule to durable assertions: expiry during client/grant waits, committed disablement/rotation before stale issuance or management, competing replacements, and late write/audit failures. Inspect credentials, verifier, lifecycle version/deadlines, enabled state, intended metadata, grant/token state and audit as applicable. Rejection must not consume or resurrect authority. Reuse existing coverage when sufficient; add only uncovered cross-phase schedules. Serialize lanes that mutate shared policy or the same dedicated database.

### Packaged fresh, upgrade and custom-store journeys

- **D-07:** Extend the existing clean-room package/process/HTTP lab. Prove registration, actual use, independent expiry, secret rotation, successful management PUT and authorized host recovery using the candidate package through real production routes. Keep fresh install, pinned legacy upgrade and configured custom-store evidence distinct and link each to the contract. Reuse the existing public/custom-prefix migration scenarios and historical migration checksum checks. Do not create another harness or storage backend.
- **D-08:** Build one identified candidate artifact per proof run and feed that identity to the proof legs. Verify package bytes, extracted/vendor contents and resolved dependency provenance before execution; reject or recreate stale unpacked, vendored or compiled host state. Same filenames and a digest recorded only after reuse are insufficient. Add a focused negative check for same-filename changed bytes/stale candidate reuse. Bind receipts to the source revision plus actual candidate content/artifact digest; do not assume independently rebuilt tarballs must be byte-identical.
- **D-09:** Extend legacy proof beyond schema/constructed-client probes: authenticate/use representative legacy credentials, observe grandfathered unlimited behavior despite advisory historical dates, explicitly replace credentials under current policy and verify whole-row canonicalization preserves unrelated authority. Reuse nil/creation/past/future historical-date and public/custom-prefix cases where already covered. Prove old writers have exited before authoritative v1 writes and retain the existing downgrade boundary; no guessed backfill or old-binary traffic after activation.
- **D-10:** Add a host-owned client-store adapter composition using the existing supported lifetime/shared-transaction seam and PostgreSQL authority. Prove normal configuration selects it and its callbacks actually execute during successful issuance and credential replacement. Inject a late failure and verify durable rollback across applicable client/grant/token/audit participants from an independent observation. A process-dictionary fixture remains useful field/negative conformance evidence, but cannot establish successful shared-authority storage. A delegating adapter demonstrates that named composition, not arbitrary external datastore support.
- **D-11:** Preserve the clean-room boundary audit. Its current blanket `Lockspire.Storage.` prohibition may need a narrow documented-adapter exception for D-10; permit only the explicit public seam needed by the host fixture and keep protocol internals, checkout imports and `test/support` inaccessible to the packaged runtime. Do not disable the audit or expose an internal module as supported merely to pass a test. If a required seam is not public, resolve that specific mismatch before making a support claim.

### Required execution, safe evidence and security

- **D-12:** Wire the new packaged proof into an active canonical CI path. Existing `test --only integration` includes tagged storage race/conformance files outside `test/integration`; the shorter `mix test.integration` alias does not reproduce that selection. The older Phase 133 full journey wrapper is unconditionally skipped and is not proof of execution. Use an explicit required invocation or active wrapper in the existing CI structure, with positive scenario counts and failure on omitted required proof. Preserve truthful skipped/excluded counts rather than treating aggregate green or an artifact's existence as coverage.
- **D-13:** Retain small allowlisted receipts containing source/package identity, scenario/contract identifiers, executed/passed/failed/skipped counts, observed outcomes/events and cleanup status. Use the existing CI artifact conventions and bounded retention (14 days is the current timing-artifact precedent); retain sanitized identities/outcomes in milestone records for durable traceability. Do not upload raw host roots, DB dumps, configs, credentials or raw request/process traces. Hashes prove identity, not execution; receipts need observed lifecycle results.
- **D-14:** Extend existing positive-event redaction tests to integrated app expiry and packaged success/failure paths. Require actual expected events and persisted audit rows before checking redaction. Preserve distinct host-recovery and self-management attribution and the absence of success events on rollback. Register actual returned/generated credentials and relevant encoded/verifier/hash values with the existing redactor before rendering output; allowlist receipts and guard stdout, stderr, command arguments, exceptions and assertion diagnostics. The current upgrade runner's `client_secret=...` substitution alone is insufficient.
- **D-15:** Remove credential fragments and raw captured payloads from redaction assertion failures. Report safe scenario/event/field identifiers and counts so a detector cannot publish the leak it detects. Include focused success and deliberately failing-output checks for the acceptance evidence boundary; no new logging/redaction dependency is needed.
- **D-16:** Require a scoped independent security review and current canonical required CI evidence for the final changed surfaces before merge/completion claims. Reuse and run meaningful existing gates for S256, exact redirects, hashed secrets, code single-use, refresh-family reuse revocation, algorithm restrictions/no implicit flow and storage/configuration fail-closed behavior. Add integration checks only where lifetime changes cross those controls. Local tests, old reviews and source workflow files alone cannot establish live required-check success. Preserve historical exceptions and report uncovered/blocked evidence honestly.

### Adopter/operator jobs and guidance truth

- **D-17:** Reconcile configuration, DCR, storage, migration, recovery, operator and supported-surface guidance against the completed case/evidence matrix. Change pending-proof statements only after their evidence exists. Clearly distinguish expired app, expired secret, expired management token, disabled app and unavailable/unsupported storage. Explain issuance-time policy and renewal events, no-overlap/lost-response recovery, legacy grandfathering, maintenance cutover and post-v1 rollback limits. Do not imply app renewal, host-session logout, universal immediate offline JWT revocation or production migration-duration guarantees.
- **D-18:** Make custom-adapter guidance executable for adopters. Repository-private tests/scripts are maintainer checkout commands and do not ship in the package. Provide a bounded copyable host-test example exercising the supported seam with ordinary ExUnit/Ecto; execute that same example in the packaged host. Cover lifecycle round trips, shared authority, current-state checks, atomic replacement/audit rollback and unsupported-state failure at the appropriate test layer. Do not ship a general conformance framework or imply that private test helpers are a public SDK.
- **D-19:** Keep existing operator tasks and host-authorized one-time credential reveal. PRODUCT.md personas/vocabulary govern changed admin copy; add new terms/retired wording and run its contracts where needed. Keep storage-version/transaction details in host-maintainer guidance. Preserve existing accessible controls, confirmations, focus behavior and themes if touched; only rendered behavior that changes needs corresponding browser evidence. Current `brandbook/` guidance supersedes older prompt branding. No broad visual refresh is justified.
- **D-20:** Close the pending DCR lifetime umbrella only after DCR-15–19 have current non-skipped evidence, applicable failure paths, package identity, required CI and scoped review. Until then preserve its `resolves_phase: 166` pending state. Stop expanding research/tests when that bounded coverage closes; no manual UAT handoff for already automated properties, no new dependency, unrelated grant, distributed activation framework or package publication.

### Agent discretion

Choose concise case IDs, receipt schema, helper names, scenario grouping, active CI invocation shape, narrowly scoped adapter-fixture configuration and host-only setup mechanics within these guarantees. Use ordinary Elixir functions/behaviours, existing repository transactions, ExUnit and existing Python acceptance helpers. Preserve public APIs where practical; a demonstrated unsupported seam or contract contradiction must be resolved explicitly rather than hidden by a test shortcut.

### Folded Todos

The matching DCR lifetime umbrella is already approved milestone scope. Its final proof/guidance portion belongs here; this discussion does not close it or repeat the historical Phase 153 audit.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/METHODOLOGY.md` — scope, DCR-15–19, automation default and reasoning lenses.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md`, `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json`, `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md` — normative semantics and acceptance examples.
- `.planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md`, `.planning/phases/163-app-lifetime-compatible-host-storage/163-VERIFICATION.md`, `.planning/phases/164-client-secret-expiry-atomic-rotation/164-CONTEXT.md`, `.planning/phases/164-client-secret-expiry-atomic-rotation/164-VERIFICATION.md`, `.planning/phases/165-management-token-lifecycle-recovery/165-CONTEXT.md`, `.planning/phases/165-management-token-lifecycle-recovery/165-VERIFICATION.md` — implemented guarantees and focused proof; rerun applicable evidence for the final candidate.
- `.planning/research/dcr-lifetimes/SCOPE.md`, `.planning/research/dcr-lifetimes/SUMMARY.md`, `.planning/research/dcr-lifetimes/PITFALLS.md`, `.planning/todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md` — original scope, known footguns and final umbrella closure gate; earlier unresolved policy is superseded by Phase 162.
- `PRODUCT.md`, `brandbook/README.md`, `brandbook/notes/decision-log.md`, `docs/dynamic-registration.md`, `docs/upgrading/client-lifetimes.md`, `docs/operator-admin.md`, `docs/supported-surface.md` — audience, current branding, adopter/maintainer jobs and support claims.
- `prompts/lockspire-elixir-oss-library-practices.md`, `prompts/lockspire-ecto-token-and-audit-model.md`, `prompts/lockspire-host-app-integration-seam.md`, `prompts/lockspire-release-engineering-and-ci.md`, `prompts/lockspire-release-readiness-and-conformance.md`, `prompts/lockspire-security-posture-and-threat-model.md`, `prompts/lockspire-telemetry-audit-and-introspection.md`, `prompts/lockspire-operator-ux-liveview.md` — relevant background; subordinate to current code, PRODUCT.md, brandbook and normative contract.
- [Ecto SQL Sandbox](https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html), [ExUnit.Case](https://ex-unit.hexdocs.pm/main/ExUnit.Case.html), [Ecto.Multi 3.13.5](https://ecto.hexdocs.pm/3.13.5/Ecto.Multi.html), [PostgreSQL 14 locking](https://www.postgresql.org/docs/14/explicit-locking.html), [PostgreSQL 14 time functions](https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT) — independent sessions, isolation and post-wait timing; existing transaction shapes need no speculative refactor.
- [Hex build](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html), [Elixir library guidelines](https://elixir.hexdocs.pm/library-guidelines.html) — package contents and host-owned dependency resolution.
- [RFC 7591 section 3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1), [RFC 7592 section 5](https://www.rfc-editor.org/rfc/rfc7592.html#section-5), [RFC 6750 section 3.1](https://www.rfc-editor.org/rfc/rfc6750.html#section-3.1), [RFC 9700](https://www.rfc-editor.org/rfc/rfc9700.html) — existing metadata, management lockout, error/disclosure and security-default grounding; do not reopen selected policy.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/support/client_lifetime_race_helpers.ex` — independent unboxed sessions, backend IDs, observed blockers and barrier clocks; existing app/secret/management storage race suites already cover many schedules.
- `test/integration/app_lifetime_packaged_upgrade_test.exs`, `test/clean_room/lifetime_upgrade_scenarios.exs`, `scripts/acceptance/clean_room/client_lifetime_upgrade.py` — active pinned-old/candidate migration, public/custom-prefix and cutover proof; extend actual credential use beyond constructed legacy/domain probes.
- `scripts/acceptance/clean_room_saas_journey.py`, `scripts/acceptance/clean_room/package_input.py`, `scripts/acceptance/clean_room/build_provider.py`, `scripts/acceptance/clean_room/redaction.py` — existing HTTP lab, package provenance, process setup and redaction. Reuse and strengthen evidence handling rather than creating a parallel system.
- `test/lockspire/protocol/dcr_telemetry_redaction_test.exs`, `test/lockspire/protocol/dcr_audit_attribution_test.exs`, `test/lockspire/client_lifetime_guidance_test.exs`, `test/lockspire/web/live/admin/vocabulary_contract_test.exs` — positive-event, attribution, guidance and vocabulary foundations.

### Established Patterns

- Exact boundaries are protocol-clock tests; HTTP wiring is a separate proof layer. The public controller does not expose injected time.
- `test/lockspire/storage/client_lifetime_conformance_test.exs` has useful process-local field/negative conformance; it deliberately rejects insufficient transaction authority and is not successful custom-store host proof.
- Current package reuse checks include inventories/checksums but do not fully bind reused candidate/build bytes to the intended invocation. Build-provider runtime boundary checks forbid all storage references today.
- `.github/workflows/ci.yml` invokes `scripts/ci/run_test_matrix.sh --integration`; it scans tagged tests across directories. The convenience alias is narrower, and `test/integration/phase133_clean_room_saas_journey_test.exs` is skipped.

### Integration Points

- Add the final case/evidence matrix beside phase proof records, active packaged execution in existing CI, and sanitized receipts through existing artifact conventions.
- Extend package-clean host fixtures through documented adapter seams while keeping runtime imports independent of checkout/test-support internals.
- Reconcile package-excluded test/script instructions and pending-proof claims in the lifetime guide only after corresponding executable results exist.
</code_context>

<specifics>
## Specific Ideas

- Preserve the selected reference sequence: issuance at 100 with app=60, secret=10, management=20 yields 160/110/120. Recovery at 125 under management=40 gives management=165 while app=160 and secret=110 remain. Use independent registrations where necessary to expose each gate, rather than allowing the earliest deadline to mask later checks.
- A reused candidate with unchanged filenames but changed bytes must fail provenance or rebuild before execution; a valid package digest beside stale vendor/compiled contents is insufficient.
- A configured host adapter must show callback participation and actual transaction rollback, not just a passing struct round trip.
- Mature ecosystem examples support narrow lessons: [Keycloak registration](https://www.keycloak.org/securing-apps/client-registration#_registration_access_token) supports admin recovery after token loss, but its rotate-on-use behavior is not Lockspire's contract; [OpenIddict token storage](https://documentation.openiddict.com/configuration/token-storage.html) explains offline JWT/status-check tradeoffs, without requiring a new online check in Lockspire's offline verifier.
- Applied lenses: adopter DX, protocol interoperability, security/adversarial review, storage/concurrency, CI/SRE/artifact handling, maintainer reproducibility, and least-technical operator comprehension. UI work stays limited to truthful existing workflows.
</specifics>

<deferred>
## Deferred Ideas

App renewal, overlapping credentials, public acceptance clock controls, alternative datastores, generalized conformance/capability frameworks, a new acceptance harness, broad admin redesign, automatic zero-downtime mixed-version activation, unrelated dependency upgrades and package publication remain outside this phase. Supplemental certification/conformance and historical verification exceptions remain separate.

### Reviewed Todos (not yet closed)

`.planning/todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md` remains pending with `resolves_phase: 166` until the final proof gates pass. No new capability was folded in.
</deferred>

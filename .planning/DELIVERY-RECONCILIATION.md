# Cumulative delivery reconciliation — 2026-10-24

## Authority and custody

The repository maintainer instructed this run to unblock delivery, follow the
review recommendations, and continue Phase 171. That delegates the current
delivery and preservation decisions to this reconciliation run. It does not
establish the identities or approvals of historical operators.

Current custodian/integrator: the authorized Codex reconciliation run in
`/Users/jon/projects/lockspire`. All preexisting tracked edits were committed in
the preceding checkpoint. This run owns its subsequent corrections and records.

| Retained history | Exact identity | Decision and next action |
| --- | --- | --- |
| Current cumulative candidate | `f8951d74c0e103f697812d070097de262beea25e` (completed v1.46 archival), descendant of remote main `a1e39a01aca258d0ac5f36414bf47c45686d92c1` | Deliver completed v1.45/v1.46 through one reconciliation PR with narrowly scoped gate corrections. Keep unfinished v1.47 planning on the original branch. |
| Original planning branch | `feat/164-client-secret-lifetimes`, reviewed inventory head `c37473156dbf03ca43d9b780671e9e97055bff61` | Preserve original commits and Phase 171 checkpoint; transport only attributed planning files after main acceptance. |
| Local main | `a1a55de0a931c641fbe176e5c3f9c4737aa62b9d` | Its 52 commits beyond remote main are contained in the cumulative candidate. Preserve this ref; use an independent owned main checkout for acceptance rather than resetting it. |
| `.claude/worktrees/agent-p2-1791320528` | `5feff7a2e444b9493d4dbea6376403de94c23c10` | Retain unchanged as separate historical release-maintenance work. Current custody assigned here; original operator unknown. No integration or removal selected. |
| `.claude/worktrees/agent-p02-1791328922` | `9912702614cf833d5930a8c42b9aab09a4e73e1e` | Retain unchanged. Descends from p2 with eight additional commits; overlapping ranges must not become two deliveries. No claim that all unique commits were integrated. |
| `.claude/worktrees/agent-p142-retry-1791337920` | `5e18d118091a47966bb29300de1fd453bb0880aa` | Retain unchanged despite containment in main. Cleanup has no benefit required by this task. |

The two older unique ranges concern release machinery and its historical
contracts, with no `lib/` product delta. Newer main release machinery supersedes
their implementation approach; that is a decision to keep them separate, not a
claim of commit containment. Phase 142/143 historical records remain unchanged.

## Review synthesis and tradeoffs

Three independent read-only reviews covered history/provenance, protocol and
security architecture, and CI/release operations. They reviewed the cumulative
source and actual repository/hosted evidence, not just commit messages. This was
a focused review, not an exhaustive fresh audit of every planning artifact.

* **Delivery:** keep the coherent completed v1.45 lifetime and v1.46 host
  integration delivery together. Its production/build/workflow/script/docs/test
  inputs match audited source `b625572ed0308f75a25db84657683ed99d7671c9` before
  the corrections below. Existing milestone audits corroborate provenance;
  fresh contributor and protected PR checks must establish current readiness.
* **Security:** no new high/critical defect found in lifetime/DCR authentication,
  guarded issuance, refresh rotation, online eligibility, admin boundaries, or
  installer containment. Preserve transaction participation checks, credential
  fingerprints, and revalidation after lock waits. These prevent stale
  authorization and partial credential/grant/audit writes.
* **Adopter/product:** retain explicit legacy timestamp migration semantics and
  deny-first host-owned operator authorization. No support widening, dependency
  addition, or public API change is part of reconciliation. A narrowly targeted
  patch update of an existing transitive dependency may be required by the
  current security audit, as recorded below.
* **History:** normal protected squash integration satisfies linear-history
  policy while the original branch and historical worktrees preserve all
  original commits. Do not import old finalizer implementations or reset local
  main merely to make branch identities match.
* **Release:** the sole acceptance script expected five push Release jobs, but
  the checked-in workflow and observed run `39500039371` have six. Correct the
  expected graph to require `Record terminal release outcome` completed/skipped,
  retain exact count and fail-closed graph validation, and test missing,
  duplicate, running, and publishing-shaped outcomes. This is a separate narrow
  release-hygiene prerequisite, not Phase 171 protocol implementation.
* **Contributor gate:** initial `mix ci` stopped at 15 Credo violations in the
  installer/admin code and tests. Apply behavior-preserving local refactoring;
  keep lint thresholds and security checks unchanged, then rerun the gate.

Existing debt remains explicit: v1.45 undefined probes/descriptor-less
prohibitions and historical summary metadata. The historically acknowledged
v1.46 fixture warnings are corrected below; archived evidence stays unchanged.
The security review also noted inconsistent attribution of malformed app lifetime
configuration (`invalid_client_metadata` versus `server_error` for the other
lifetime policies). No new exploit was identified; keep that classification
consistency improvement separate from this prerequisite and Phase 171.

## No-publication control

Before integration the existing repository Actions variable
`LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` was observed `true`, set to `false`, and
read back `false`. No queued/running Release or automatic release-merge run was
observed. Push Release maintains the Release Please PR; publishing jobs require
dispatch. The auto-merge workflow can later merge that PR and dispatch release,
so a successful push alone is not sufficient publication isolation.

Keep this reversible pause through acceptance and Phase 171. Do not restore it
blindly: the release owner must review any pending release PR/automation before
reenabling. No publication workflow, release authorization SHA, tag, or package
is changed by this control.

## Evidence and continuation

Original main observation: `a1e39a01aca258d0ac5f36414bf47c45686d92c1`.
Protected main requires all seven canonical checks, strict up-to-date status,
linear history, and resolved conversations; administrator enforcement is on,
required human review count is zero. Internal review here does not waive checks.

The first sandboxed contributor attempt failed writing the existing Hex cache
(`eperm`), before validation. The authorized retry reached Credo and failed with
15 violations; neither attempt is an accepted-main receipt. Runtime was
Elixir 1.19.5 / OTP 28.5. Follow-up exact candidate, PR, main and acceptance
identities/results will be appended when observed. No Phase 171 qualification
is authorized by this record alone.

Prerequisite repair evidence:

* `253ff0a1`: release graph corrected; existing focused hygiene suite ran
  10 tests / 0 failures, shell syntax and formatting passed. No historical RED
  result is claimed; the real hosted six-job graph exposed the drift.
* `5dda7328`: installer/admin lint corrected; complete Credo found no issues,
  and the affected installer, upgrade, verification, generated-host integration
  and route suites ran 82 tests / 0 failures. Existing safety assertions remain.
* The next contributor attempt passed formatting, compilation, architecture,
  Credo, Sobelow and docs, then correctly blocked on `plug_crypto 2.2.0` advisory
  CVE-2026-105963. The maintainer's
  [changelog](https://github.com/elixir-plug/plug_crypto/blob/main/CHANGELOG.md)
  and [Hex release](https://hex.pm/packages/plug_crypto/2.2.1) identify 2.2.1 as
  the patch preventing secret-key exposure in wrong-argument stack traces.
  Select only that existing transitive package for update, retain the dependency
  tree and direct manifests, and rerun the full contributor gate. The public
  advisory URL was not available when queried; no suppression is selected.

The Phase 171 roadmap also needed an explicit versioned milestone heading:
without it, GSD warned it could not safely scope progress to v1.47. The heading
now identifies the same existing scope without changing the phase sequence.

The patched contributor run against the preexisting `lockspire_test` database
failed 13 admin count/plural assertions. Read-only investigation found two
`lifetime-client-wait-*` clients inserted on October 21, three days before this
run. Those historical rows explain the extra counts; the UI and assertions are
correct. Preserve that database and its rows. The authoritative rerun uses the
new run-owned database `lockspire_171_delivery_20261024a` through the existing
`LOCKSPIRE_TEST_DB_NAME` seam. No UI or assertion adjustment was made. Its fast
suite passed 2 properties and 2,031 tests with zero failures (6 existing skips,
497 excluded integration tests). The integration suite then passed 199 tests,
zero failures (46 excluded), and the architecture check passed 15 tests. The
complete `mix ci` exited zero: 2,245 tests and 2 properties, no failures, with
formatting, compilation, architecture, Credo, Sobelow, docs, dependency audit
and package build passing. Command: `LOCKSPIRE_TEST_DB_NAME=lockspire_171_delivery_20261024a ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix ci`.
The tested source bytes are committed at `ddb9237d`; the only dependency change
is the `plug_crypto` lock entry, 2.2.0 to 2.2.1. The temporary database is owned
only by this run and may be retired after its evidence is retained.

The first PR check run `40117908804` then found two additional repository-only
prerequisites that the local contributor alias did not exercise:

* The Release Please npm audit rejected existing `undici 6.29.0`. The upstream
  [EventSource advisory](https://github.com/nodejs/undici/security/advisories/GHSA-4qv8-2p9j-2685)
  and [content-encoding advisory](https://github.com/nodejs/undici/security/advisories/GHSA-xjj6-f33q-929c)
  both prescribe 6.29.1 on this major line. Commit `1177aa33` changes only that
  lock entry, preserving the dependency count and direct manifest. Clean
  `npm ci --ignore-scripts`, moderate-threshold npm audit (zero vulnerabilities),
  the actual ESM import, and all three release-runtime contract tests pass.
  An owned `/tmp` npm cache avoids changing global cache permissions.
* Clean test-environment compilation uses `--warnings-as-errors` in hosted CI.
  Remove the duplicate unreachable trace helper and normalize only the router
  scope's empty prefix to `/`; keep the logical session prefix unchanged.
  `MIX_ENV=test mix compile --force --warnings-as-errors` passed, followed by
  34 admin-route inventory/compilation/integration regression tests with zero
  failures. This repairs fixture debt without changing product behavior or
  weakening CI warning policy.

The corrected PR head must receive fresh protected checks; the first run's
partial successes do not authorize merging a later head.

### All maintained host lockfiles and the historical framework floor

The demo and compatibility hosts also locked `plug_crypto 2.2.0` and
`decimal 3.1.1`. Commit `ece7e94a` advances only those existing transitive
entries to 2.2.1 and 3.1.2. Decimal's maintainer
[3.1.2 security changelog](https://github.com/ericmj/decimal/blob/main/CHANGELOG.md#v312-2026-10-10)
identifies CVE-2026-97853; use that patch rather than its broader 3.2 minor.
An isolated temporary Mix project with an exact 3.1.2 requirement generated the
signed lock identity; neither host's direct manifest or framework version was
changed. Both hosts compiled with warnings-as-errors. The demo's complete Hex
audit passed; the root audit had already passed.

The exact historical compatibility pair Phoenix 1.8.5 / LiveView 1.1.28 retains
four upstream framework advisories: Phoenix channel-join exhaustion, long-poll
allocation and Presence key collisions, plus LiveView local redirect validation.
The compatibility host's audit remains **failing**. The independent security
review recommended preserving this exact compatibility experiment, disclosing
the advisories in `docs/supported-surface.md`, and keeping it isolated from
deployment. Current delegated custody accepts only the bounded test exposure:
disposable proof hosts bind loopback, use synthetic credentials, and receive no
production traffic/secrets. No advisory is suppressed or called resolved, and
no compatibility-audit pass is claimed. Root/source acceptance remains its own
existing exact-SHA contract using the maintained patched framework pair.

Repository maintainer owns a separate secure-supported-floor policy decision
before any deployment recommendation involving the historical pair. This run
does not silently raise the public compatibility floor or widen Phase 171.
The public caveat and unchanged integration boundaries passed docs generation
and 18 documentation/support/compatibility contract tests.

### Packaged-journey prerequisite resolved

Run `40118254627` passed Release Hygiene, Dialyzer, Fast Checks, Minimum
Supported Elixir/OTP and Adoption Demo Smoke. Integration's 199 source tests
passed, but the package-only upgrade and HTTP journeys failed after provider
readiness; Complete Coverage was consequently skipped. Separate prerequisite
diagnosis established two proof-host integration bugs, not protocol defects:

1. The pinned old installer references host pipeline `:require_operator`, which
   the newer overlay omitted. The real checksum-pinned old template fails in
   0.38 seconds with that pipeline missing; adding only the existing denying
   operator plug makes it compile in 0.63 seconds.
2. The current fixture account resolver reads `Plug.Conn.get_session/2` on an
   endpoint connection whose session is installed but not fetched. Repeated
   HTTP tests observed authorization 500 instead of 302. A pure actual-resolver
   probe reproduces `ArgumentError`; fetching that same session first returns
   the expected login redirect in 0.46 seconds. A secondary absent error renderer
   had masked the original exception. Diagnostics retained only numeric status,
   exception type and source locations, never bodies or argument values.

Commit `4fcb7486` restores the host-owned denying legacy admin pipeline and
fetches the session immediately before the host resolver's own cookie read.
It changes no runtime library, generator, route policy or CSRF behavior. A new
real-resolver regression failed before the fix and passed afterward; both
mount integrations passed (2 tests total), the legacy compile loop passed, and
strict Credo found no issues. No broad browser/CSRF middleware was added to
public token or DCR routes.

The original complete package regression command then passed at that source:
`CLEAN_ROOM_CACHE_ROOT=/tmp/lockspire-171-package-debug-cache LOCKSPIRE_TEST_DB_NAME=lockspire_171_delivery_20261024a ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test --include lifetime_package test/integration/client_lifetime_packaged_journey_test.exs test/integration/app_lifetime_packaged_upgrade_test.exs`.
Exit zero, 244.7 seconds, **3 tests / 0 failures**, including both candidate
HTTP journeys and the pinned old/candidate public and tenant-prefix upgrade.
Every live diagnostic attempt and the final verification completed owned
provider/database/run-root cleanup. Debug hooks were confined to owned `/tmp`
paths. These corrections still require fresh exact-head protected checks;
no main integration, acceptance or Phase 171 completion is claimed here.

### Generated-dependency lint false positive

At corrected PR head `8e6a0acd`, minimum-runtime CI found one non-product
failure: the repository shell-lint contract recursively selected an untracked
Git hook inside `tmp/lockspire-compatibility-fixture/deps/lazy_html/.../.git`.
ShellCheck correctly warned about that third-party sample, but it is outside
the maintained repository inventory. Commit `ff935001` changes discovery to
NUL-delimited `git ls-files`, preserving tracked extensionless shebang scripts,
filenames with spaces, and the old regular-file-only behavior. Actual
actionlint/ShellCheck severity and failure policy stay unchanged; generated
dependencies and unknown files are preserved rather than edited or deleted.

The regression failed before the inventory fix and passed afterward. The
existing hygiene suite passed **11 tests / 0 failures**; real-root workflow and
shell lint, formatting, shell syntax and diff checks passed. This is another
separate CI-hygiene prerequisite, not Phase 171 protocol work. All seven
protected checks remain mandatory at the next published candidate head.

## Lessons applied

1. Separate historical ownership from current delegated custody, containment,
   review, and acceptance. Preserve exact refs when the old operator is unknown;
   do not let unnecessary cleanup create an ownership deadlock.
2. Deliver completed milestones before starting dependent baseline work. Keep
   unfinished planning on its original branch until the accepted-base branch
   exists, and carry only attributed files forward.
3. Bind release gate fixtures to the checked-in workflow graph. A mock and its
   validator can agree while both drift from actual hosted jobs.
4. Inspect indirect release automation before merging. Pause the existing
   switch rather than creating a second publication mechanism or depending on
   an accidentally absent authorization variable.
5. Run the complete contributor gate before declaring delivery ready. Static
   reviews and archived green reports cannot reveal current lint/gate drift.
6. Stop fan-out when independent reviews converge on the same bounded route;
   spend the remaining effort on corrections and executable evidence.
7. Give authoritative local gates their own test database. Historical unboxed
   fixtures can invalidate count assertions without indicating a UI regression;
   diagnose provenance before changing copy or weakening assertions. Register
   cleanup before constructing partially committing fixtures in future test
   hardening; the historical leak's exact cause was not proven here.
8. Distinguish the local contributor alias from every hosted job. In particular,
   exercise a clean test-environment warnings-as-errors compile and the
   privileged release runtime's npm audit; cached local compilation can hide
   acknowledged warnings that correctly block a clean hosted build.
9. Audit all maintained host lockfiles together when applying a security patch.
   Separate a deliberately historical compatibility experiment from a production
   security recommendation, preserve failing audit facts, and document the
   isolation and owner of any unresolved floor-policy decision.
10. Preserve host adapter contracts across installer generations. Test the
    actual cookie-reading callback with the endpoint's lazy session state,
    and keep legacy admin pipelines denying by default. A safe structural
    exception probe can locate a masked error without retaining raw logs or
    weakening redaction. Reuse the original packaged regressions as final proof.
11. Discover maintained lint targets from the repository index rather than the
    entire working filesystem. Generated dependency trees and their Git hooks
    are not repository-owned source; keep checking tracked extensionless files
    and preserve safe filename handling instead of weakening the linter.

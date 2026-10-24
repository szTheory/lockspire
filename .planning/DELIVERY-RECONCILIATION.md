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
prohibitions and historical summary metadata; v1.46 duplicate fixture warnings.
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

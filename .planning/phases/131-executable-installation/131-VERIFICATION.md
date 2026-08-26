---
phase: 131-executable-installation
verified: 2026-08-26T22:46:00Z
status: gaps_found
score: 8/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The generated host consent UI provides the approved populated, empty, loading, submitting, and safe error states."
    status: failed
    reason: "The installer-rendered LiveView loads context synchronously in mount/3 and has only normal and error render clauses; it never renders the UI-SPEC-required non-interactive loading status before context resolution."
    artifacts:
      - path: "priv/templates/lockspire.install/consent_live.ex"
        issue: "No loading assign, async context-loading path, role=status element, or loading render clause exists."
    missing:
      - "Add a host-styled, non-interactive loading state and exercise it in the rendered-template/fixture test without weakening the authoritative ConsentContext boundary."
---

# Phase 131: Executable Installation Verification Report

**Phase Goal:** A Phoenix SaaS team can install the packaged library and use the documented generated integration path without replacing Lockspire internals.
**Verified:** 2026-08-26T22:46:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A generated host mounts real host, guarded-admin, consent, and public protocol routes in the documented order. | VERIFIED | `priv/templates/lockspire.install/router.ex` exports an imported `defmacro`; the generated fixture calls it, and `test/integration/install_generator_test.exs` compiles it and inspects `Phoenix.Router.routes/1`. The rerun passed. |
| 2 | The generated admin mount requires the host-owned operator pipeline at compile time and precedes public forwarding. | VERIFIED | The emitted macro contains `pipe_through([:browser, :require_operator])`; the generator test compiles a router without that pipeline and asserts compilation fails. The fixture plug returns 403 unless the host marks the user as an operator. |
| 3 | A host-branded consent LiveView receives authoritative, redacted interaction state and completes through the existing interaction endpoint. | VERIFIED | `Lockspire.Web.ConsentContext.load/2` fetches stored interaction/client data, resolves the host subject, handles expiry/mismatch/reused consent, and returns only display-safe fields plus the completion path. The installer template consumes it; the Phase 6 generated-host test mounts, approves, posts to the existing completion controller, and exchanges the authorization code. |
| 4 | The generated host consent UI provides the approved populated, empty, loading, submitting, and safe error states. | FAILED | The template has populated/empty/submitting/error branches, but no loading assign, `role="status"`, or loading render clause. `mount/3` synchronously calls `ConsentContext.load/2`; therefore it cannot render the UI-SPEC-required pre-resolution loading state. |
| 5 | Install and upgrade copy only missing migrations, preserve host files, identify collisions, and recover safely from ordinary/interrupted transaction failures. | VERIFIED | `Migrations.plan/1` performs complete version/name/content preflight; `OperationPlan` uses `FileTransaction` for staged manifest-last writes. Focused tests passed for migration collisions, atomic snapshots, ordinary rollback/retry, interrupted recovery, and symlinked `.lockspire` refusal. This independently confirms the `ce35107` and `d9ba50f` transaction behavior rather than accepting the review report. |
| 6 | Generated configuration and `mix lockspire.verify` expose required seams with safe, actionable remediation. | VERIFIED | Generated config includes `logout_path`; resolver uses it in `redirect_for_logout/2`. `Verify.run/1` independently checks repo, resolver, issuer, mount path, logout path, Oban, seam modules, compiled route shape/order, host migration delivery, and migration state. Docs explicitly say route shape is verified while host operator policy needs host request tests. |
| 7 | A generated host proves default secure behavior by default; FAPI remains explicit and persistent through upgrades. | VERIFIED | Default smoke template uses S256, exact redirect checks, `openid profile` authorization scope with only `profile` registered, and default `:none` policy. FAPI template is optional, excluded from normal discovery, uses `:crypto.strong_rand_bytes/1` values, and install/upgrade preserve the manifest flag. Render/compile/execute tests passed. |
| 8 | The documented Claims example compiles with real public fields only. | VERIFIED | Rendered resolver uses `%Lockspire.Host.Claims{subject:, id_token:, userinfo:}`; generator test compiles the rendered module and verifies configured logout behavior. |
| 9 | Phase 131 stays within the embedded, additive installation boundary. | VERIFIED | Diff contains installer/templates/tests/docs and narrow consent/transaction support only. No standalone service, admin redesign, new grant, or breaking public API was introduced; separate-origin/resource-server work remains in Phases 132–133. |

**Score:** 8/9 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `priv/templates/lockspire.install/router.ex` | Imported, ordered Phoenix router macro | VERIFIED | Substantive macro emits host routes, admin forward, consent route, and public forward. |
| `priv/templates/lockspire.install/consent_live.ex` | Host-owned safe consent presentation | PARTIAL / GAP | Substantive and wired to `ConsentContext`, but lacks required loading state. |
| `lib/lockspire/web/consent_context.ex` | Stable authoritative render-context API | VERIFIED | Real repository/authorization-flow data path with redaction boundary. |
| `lib/lockspire/install/migrations.ex` | Deterministic migration inventory/preflight/apply | VERIFIED | Real byte checks, collision diagnostics, and transactional application. |
| `lib/lockspire/install/file_transaction.ex` | Journaled staged transaction and recovery | VERIFIED | Ordinary rollback/retry and journal-ancestor symlink tests independently pass. |
| `lib/lockspire/install/verify.ex` | Aggregate install verification | VERIFIED | Compiled router, migration, config, and seam checks are all wired. |
| `priv/templates/lockspire.install/default_smoke_e2e_test.exs` | Default secure generated behavioral smoke | VERIFIED | Real host endpoint calls and protocol assertions; rendered test is executed by generator integration coverage. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Generated host router | Generated router macro | import plus `lockspire_routes()` | WIRED | Fixture router imports `GeneratedHostAppWeb.Router.Lockspire` and invokes the macro. |
| Router macro | Admin/public routers | ordered Phoenix DSL forwards | WIRED | Route-table test confirms consent/admin appear before public forward. |
| Generated consent LiveView | `Lockspire.Web.ConsentContext` | `mount/3` `ConsentContext.load(socket, interaction_id)` | WIRED | Safe context flows into LiveView assigns and HEEx. |
| Generated consent forms | `Lockspire.Web.InteractionController` | context-provided `/interactions/:id/complete` POST | WIRED | Phase 6 test proves approval through native POST then token exchange. |
| Install/upgrade operation plan | Migration and managed artifacts | `FileTransaction.apply/3`, manifest last | WIRED | Lifecycle and transaction tests exercise actual public installer/upgrade operations. |
| `mix lockspire.verify` | Compiled host router/migrations | `Phoenix.Router.routes/1` and host `priv/repo/migrations` inventory | WIRED | Focused verifier and Mix-task tests pass. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated consent LiveView | `client_name`, scopes, detail types, completion path | Stored interaction/client → `ConsentContext.load/2` → socket assigns | Yes; Phase 6 persists interaction/client, mounts the generated LiveView, and completes the token flow | FLOWING |
| Migration delivery | planned operations | Packaged/host filesystem inventory → `Migrations.plan/1` → `OperationPlan` → `FileTransaction` | Yes; focused lifecycle tests use temporary source roots and real public install/upgrade commands | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated router, config, claims, smoke, and FAPI selection/behavior | `mix test test/integration/install_generator_test.exs` | Passed in focused suite | PASS |
| Migration collision/idempotency and public upgrade lifecycle | `mix test test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` | Passed in focused suite | PASS |
| Journal rollback/retry and symlink refusal | `mix test test/lockspire/install/file_transaction_test.exs` | Passed in focused suite | PASS |
| Safe consent state and generated approval-to-token flow | `mix test test/lockspire/web/consent_context_test.exs test/lockspire/web/live/consent_live_test.exs && mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` | Passed | PASS |
| Independent diagnostics and documentation | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs && mix compile --warnings-as-errors && mix docs.verify` | Passed | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| INST-01 | 131-01 | Generated host router mounts actual ordered routes | SATISFIED | Macro/route-table and negative missing-pipeline compilation tests. |
| INST-02 | 131-03 | Host-branded consent LiveView backed by real interaction state and supported completion | BLOCKED | Core data flow and completion pass, but the approved loading UI state is absent. |
| INST-03 | 131-02, 131-04 | Idempotent safe migration install/upgrade | SATISFIED | Complete preflight, immutable combined operation plan, transaction/recovery tests. |
| INST-04 | 131-01, 131-06 | Required config seams and actionable verification | SATISFIED | Logout is generated/used; independent aggregated checks and truthful docs pass. |
| INST-05 | 131-05 | Default secure generated tests and explicit FAPI proof | SATISFIED | Executed rendered smokes, strict opt-in, persistent upgrade selection, randomized FAPI values. |
| INST-06 | 131-01 | Claims example compiles against real fields | SATISFIED | Actual rendered resolver is compiled and uses only subject/id_token/userinfo. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `priv/templates/lockspire.install/consent_live.ex` | `mount/3` / render clauses | Missing approved loading state | BLOCKER | Installer output does not meet its UI integration contract. |

## Gaps Summary

Phase 131’s executable installation, consent completion, migration transaction, diagnostics, documentation, and smoke boundaries are substantively implemented and independently passing. However, the approved generated-consent UI contract explicitly requires a non-interactive loading status before authoritative context resolves. The rendered template has no such state or behavioral proof, so the phase cannot be marked complete.

Next action: add the loading state to the generated consent template/fixture and a focused rendered-template LiveView test, then re-run the consent and generator installation suites.

---

_Verified: 2026-08-26T22:46:00Z_
_Verifier: the agent (gsd-verifier)_

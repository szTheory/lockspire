---
phase: 102-generated-host-scaffolding-telemetry-migration
verified: 2026-05-29T11:00:00Z
status: passed
score: 4/4 roadmap success criteria verified (+ 5/5 requirement IDs satisfied)
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
---

# Phase 102: Generated-Host Scaffolding + Telemetry + Migration Verification Report

**Phase Goal:** The install template, operator telemetry, migration guide, and doctor task all reflect the now-proven blessed path so new adopters land on a working pipeline by default and existing adopters can migrate the issuance-default flip safely. (LAST phase of v1.27; deliberately MIRRORS already-shipped behavior — must NOT lead the contract or add protocol breadth.)
**Verified:** 2026-05-29T11:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | New adopter `mix lockspire.install` not asked about token format; router ships commented `:lockspire_protected_api` pipeline ready to uncomment; two regression guards fence this (real assertions; uncomment guard reads RAW bytes) | ✓ VERIFIED | `release_readiness_contract_test.exs:764-777` refutes `access_token_format\|token_format\|:jwt\|:opaque` over task+generator source ONLY (template excluded — legitimately carries `audience:`). `:779-798` reads `File.read!(@install_template_router_path)` RAW (line 784, NOT `extract_canonical_pipeline!/2`) and asserts every non-blank canonical-block body line matches `~r/^\s*#/`. Sources confirmed clean (grep returned no matches); template block fully commented (`router.ex:11-18`). Both real, non-tautological. |
| 2 | Operator subscribes `[:lockspire, :rs, :token_format]` → on VerifyToken sees `:jwt \| :"opaque-rejected"` value + metadata (client_id, audience, binding_type) via direct `:telemetry.execute/3` at two sites (NOT Observability.emit/4); capture test exists and passes | ✓ VERIFIED | `verify_token.ex` SITE B `:114-125` (opaque-reject, literal `:"opaque-rejected"`, all-nil metadata), SITE A `:141-154` (`:jwt`, claims-sourced metadata, audience from `Map.get(claims,"aud")`), both call `emit_token_format/1` → `:telemetry.execute([:lockspire,:rs,:token_format],%{count:1},metadata)` at `:525-526`. NO `Observability.emit` for this event (grep confirmed). Capture test `verify_token_telemetry_test.exs` (2 tests, 0 failures) asserts both 4-arg tuples + literal hyphenated atom (`:139`). |
| 3 | Operator finds `docs/upgrading/v1.27.md` explaining flip + HONEST runtime opt-out `ServerPolicy.put_access_token_format(:opaque)` (NOT a config key) + nil-inherit affected-client naming; contract-test pin asserts these + refutes phantom config key | ✓ VERIFIED | `docs/upgrading/v1.27.md` (83 lines) contains `put_access_token_format(:opaque)`, names affected clients as `access_token_format is nil`, explicitly states explicit-`:opaque` clients NOT affected (`:33-34,:80`), no `config :lockspire ... access_token_format` (grep -E returned nothing). Pin `release_readiness_contract_test.exs:800-821` asserts opt-out string, `~r/access_token_format.{0,40}nil/`, opaque+:jwt flip, and `refute doc =~ ~r/config :lockspire.*access_token_format/`. |
| 4 | Operator `mix lockspire.doctor token_format` gets read-only per-client diagnostic flagging every `access_token_format: nil` client — diagnostic not enforcement (no Mix.raise, no non-zero exit); subtask + dispatcher clause exist, resolve_format precedence reproduced inline (signer fn private), test proves read-only | ✓ VERIFIED | `lockspire.doctor.token_format.ex` defines `Mix.Tasks.Lockspire.Doctor.TokenFormat`; report path `:58-66` is `with {:ok,_}<-...{:ok,_}<-...` with calm `{:error,_}` branch — no Mix.raise (only OptionParser invalid-opts guard `:29`), no System.halt. `effective_format/2` `:104-113` reproduces signer `resolve_format/2` (`access_token_signer.ex:88-98`) byte-equivalently, comment-anchored, no call to the private fn (grep confirmed). Dispatcher `lockspire.doctor.ex:15-16` + help line `:25`. Test (5 tests, 0 failures) asserts CHANGED flag on nil, refutes on opaque, parity flip, help line. |

**Score:** 4/4 ROADMAP success criteria verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/lockspire/release_readiness_contract_test.exs` | 3 new clauses (SCAFFOLD-01/02 + MIGRATE-01 pin) + 3 constants | ✓ VERIFIED | `@install_task_path:93`, `@install_generator_path:94`, `@upgrading_v1_27_path:80`; clauses at `:764`, `:779`, `:800`. 34+ contract tests pass. |
| `lib/lockspire/plug/verify_token.ex` | 2 direct `:telemetry.execute/3` sites | ✓ VERIFIED | +48 lines, zero deletions (purely additive). Helper `:525-526`, two call sites. |
| `test/lockspire/plug/verify_token_telemetry_test.exs` | attach_many capture test, both sites + literal atom | ✓ VERIFIED | 2 tests, 0 failures; 4-arg handler `:37`. |
| `docs/upgrading/v1.27.md` | migration guide (flip + runtime opt-out + nil-inherit) | ✓ VERIFIED | 83 lines, all required strings present, no phantom config key. |
| `lib/mix/tasks/lockspire.doctor.token_format.ex` | read-only diagnostic subtask | ✓ VERIFIED | 114 lines, reproduces precedence inline, no Mix.raise in report path. |
| `lib/mix/tasks/lockspire.doctor.ex` | dispatch clause + help line | ✓ VERIFIED | +5 lines, `run(["token_format"|rest])` + help. |
| `test/mix/tasks/lockspire_doctor_token_format_test.exs` | diagnostic + parity + dispatch/help test | ✓ VERIFIED | 5 tests, 0 failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| contract test | install task + generator | `File.read!` + `refute access_token_format` | ✓ WIRED | `:770-776` iterates both constants, refute regex present. |
| contract test | install template router | raw-bytes BEGIN/END capture + commented assert | ✓ WIRED | `:784-797` raw `File.read!`, marker regex, `^\s*#` assert. |
| contract test | `docs/upgrading/v1.27.md` | `File.read!` + assert opt-out/nil-inherit + refute phantom | ✓ WIRED | `:804-820`. |
| `verify_token.ex` do_verify_token | `[:lockspire,:rs,:token_format]` | direct execute `%{count:1}` `:jwt` | ✓ WIRED | SITE A `:149-154`. |
| `verify_token.ex` opaque branch | `[:lockspire,:rs,:token_format]` | direct execute `:"opaque-rejected"` | ✓ WIRED | SITE B `:120-125`. |
| `lockspire.doctor.ex` | `lockspire.doctor.token_format.ex` | `Mix.Task.run("lockspire.doctor.token_format", rest)` | ✓ WIRED | `:15-16`. |
| doctor subtask | `Clients.list_clients/1` + `ServerPolicy.get_server_policy/0` | `{:ok,_}` reads + reproduced precedence | ✓ WIRED | `:59-60`, `effective_format/2:104-113`. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 4 phase-102 test files green | `mix test <4 files>` | 114 tests, 0 failures | ✓ PASS |
| Telemetry capture test (both sites + literal atom) | `mix test verify_token_telemetry_test.exs` | 2 tests, 0 failures | ✓ PASS |
| Doctor diagnostic + parity + help | `mix test lockspire_doctor_token_format_test.exs` | 5 tests, 0 failures | ✓ PASS |
| verify_token.ex observe-only (no deletions) | `git diff ea9e577~1 HEAD -- verify_token.ex \| grep '^-'` | NO DELETIONS — purely additive | ✓ PASS |
| No runtime/protocol surface widened | `git diff --stat -- lib/ priv/` | only verify_token.ex(+48), doctor.ex(+5), doctor.token_format.ex(new) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SCAFFOLD-01 | 102-01 | commented `:lockspire_protected_api` pipeline in install template | ✓ SATISFIED | Truth 1; uncomment-ready raw-bytes guard. |
| SCAFFOLD-02 | 102-01 | install never asks about token format | ✓ SATISFIED | Truth 1; no-format-prompt refute guard. |
| TELEMETRY-01 | 102-02 | `[:lockspire,:rs,:token_format]` event on VerifyToken | ✓ SATISFIED | Truth 2; two direct emit sites + capture test. |
| MIGRATE-01 | 102-03 | v1.27 migration guide w/ nil-inherit + opt-out | ✓ SATISFIED | Truth 3; doc + contract pin. |
| MIGRATE-02 | 102-04 | `mix lockspire.doctor token_format` per-client diagnostic | ✓ SATISFIED | Truth 4; subtask + dispatcher + read-only test. |

All 5 requirement IDs map to Phase 102 in REQUIREMENTS.md (lines 141-145, 162). No orphaned requirements; no plan declared an ID outside this set.

### Drift-Correction Compliance (102-RESEARCH Citation Accuracy Audit)

| Drift correction | Respected? | Evidence |
|------------------|-----------|----------|
| `AccessToken` struct at `lib/lockspire/access_token.ex` (no `audience` field) → read audience from `claims["aud"]` | ✓ | `verify_token.ex:152` `audience: Map.get(claims, "aud")`. |
| extraction helper *defined* at line 140 (not 745) — use raw bytes for commented-state | ✓ | SCAFFOLD-01 guard uses raw `File.read!` not the normalizer (`:784`). |
| `resolve_format/2` is `defp` (private) → reproduce inline, do NOT call | ✓ | doctor `effective_format/2:104-113` reproduces clauses; grep confirms no `AccessTokenSigner.resolve_format` call. Signer public surface NOT widened. |

### Anti-Patterns Found

None. No `TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER` markers in any phase-102 file. No stubs, no empty implementations, no hardcoded-empty data feeding output.

### Human Verification Required

None. All four success criteria are programmatically verifiable: contract-test guards over repo bytes, telemetry capture test asserting delivered metadata, doc content greps, and the doctor diagnostic test exercising live ServerPolicy/Clients reads. All run green.

### Gaps Summary

No gaps. Phase goal achieved:
- New adopters get the commented uncomment-ready pipeline and are never asked about token format, both fenced by real (non-tautological, raw-bytes) regression guards.
- Operators get the `[:lockspire,:rs,:token_format]` counter via direct `:telemetry.execute/3` (not Observability.emit/4) at both the `:jwt` success and `:"opaque-rejected"` reject sites, proven by a passing capture test asserting the literal hyphenated atom and all-nil opaque metadata.
- The v1.27 migration guide documents the HONEST runtime opt-out (`put_access_token_format(:opaque)`, not a config key) and the nil-inherit affected set, pinned against drift.
- `mix lockspire.doctor token_format` is a routed, read-only diagnostic flagging every nil-format client with signer-byte-equivalent precedence, no Mix.raise / non-zero exit.

Observe-only constraint confirmed: the only runtime change to the verifier (`verify_token.ex`) is purely additive (zero deletions); no changes to signer, issuance, userinfo, or introspect. The phase mirrors already-shipped behavior without leading the contract or adding protocol breadth.

---

_Verified: 2026-05-29T11:00:00Z_
_Verifier: Claude (gsd-verifier)_

---
phase: 100
slug: sender-constraint-end-to-end-proof
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-28
---

# Phase 100 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `100-RESEARCH.md` → Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 stdlib) |
| **Config file** | none — convention-based; `test/test_helper.exs` controls `:integration` exclusion |
| **Quick run command** | `mix test <changed test file(s)>` (e.g. `mix test test/lockspire/plug/require_token_test.exs`) |
| **Full suite command** | `mix test.setup && mix test --include integration` |
| **Estimated runtime** | full suite ~tens of seconds; integration file adds the DPoP nonce dance (sub-second per case) |

---

## Sampling Rate

- **After every task commit:** Run `mix test` for the file(s) the task touched.
- **After every plan wave:** Run `mix test` (default non-integration suite) + the phase100 integration file via `mix test --include integration test/integration/phase100_sender_constraint_e2e_test.exs`.
- **Before `/gsd:verify-work`:** `mix test.setup && mix test --include integration` fully green, plus `mix compile --warnings-as-errors` clean (CI also runs credo/dialyzer/sobelow — keep clean).
- **Max feedback latency:** < 60 seconds for the quick run.

---

## Per-Requirement Verification Map

> Task IDs assigned during planning; all rows are Wave 0 (test files/clauses are net-new) except the additive struct-defaults update.

| Requirement | Wave | Observable signal (faithful proof) | Test Type | Automated Command | File Exists | Status |
|-------------|------|------------------------------------|-----------|-------------------|-------------|--------|
| BIND-01 | int | DPoP-bound `at+jwt` minted by `AccessTokenSigner.issue/3` (from `%Token{cnf: %{"jkt" => jkt}}`) → real 3-plug endpoint → genuine nonce-retry dance → `200` with `conn.assigns.access_token` populated AND `binding_type: "dpop"` AND `binding_requirements: %{dpop_jkt: jkt}` | integration | `mix test --include integration test/integration/phase100_sender_constraint_e2e_test.exs` | ❌ W0 (new file) | ⬜ pending |
| BIND-02 | int | mTLS-bound `at+jwt` minted by `issue/3` (cnf `x5t#S256`) → endpoint with `conn.private[:lockspire_mtls_cert]` matching the SAME cert string → `200` with `binding_type: "mtls"` | integration | `mix test --include integration test/integration/phase100_sender_constraint_e2e_test.exs` | ❌ W0 (new file) | ⬜ pending |
| BIND-03 (struct default) | 1 | `%AccessToken{}.binding_verified == false` (fail-closed default, D-01) | unit | `mix test test/lockspire/access_token_test.exs` | ✅ (update existing defaults test) | ⬜ pending |
| BIND-03 (positive set) | 1 | `EnforceSenderConstraints` sets `access_token.binding_verified == true` on every binding-validated success path; bearer no-op path leaves it `false` (D-02) | plug-unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` | ❌ W0 (new assertions) | ⬜ pending |
| BIND-03 (runtime negative) | 1 | Bound token (`error: nil`, `binding_requirements != nil`, `binding_verified: false`) → `RequireToken` → `403` halted, sender-constraint error (D-03) | plug-unit | `mix test test/lockspire/plug/require_token_test.exs` | ❌ W0 (new clause) | ⬜ pending |
| BIND-03 (bearer-still-passes) | 1 | Bearer token (`binding_requirements: nil`) → `RequireToken` → not halted, passes through (surprise-free guarantee) | plug-unit | `mix test test/lockspire/plug/require_token_test.exs` | ❌ W0 (new clause) | ⬜ pending |
| BIND-03 (contract ordering) | 1 | All four RECIPE-01 sites order Verify→Enforce→Require (offset/regex that genuinely fails if Enforce/Require are transposed); D-05 | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ❌ W0 (new clause; satisfied by current content) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Faithful-vs-Shallow Proof Criteria (anti-cheat lens)

| Req | Shallow (rejected) | Faithful (required) |
|-----|--------------------|---------------------|
| BIND-01 | Hand-sign the JWT with `JOSE.JWT.sign` (proves only the plug chain); skip/stub the nonce dance | Mint via `AccessTokenSigner.issue/3` so the proof exercises Phase 99's `maybe_put_cnf/2` (D-07); run the genuine `use_dpop_nonce` → retry → 200 sequence against the wired `ProtectedApiReplayStore`; use `DPoP.access_token_ath(raw_at_jwt)` on the actual minted token |
| BIND-02 | Assert only that the plug doesn't error | Assert `200` at the controller AND `binding_type: "mtls"`, with the token's `x5t#S256` derived from the SAME cert string presented via `conn.private` |
| BIND-03 negative | Assert the guard fires for ANY bound token | Assert it fires ONLY for `error: nil, binding_requirements != nil, binding_verified: false` (403) AND that a bearer token still passes (zero false-positive surface) |
| BIND-03 contract | A regex that would pass even if order were wrong | Offset/regex assertion that genuinely fails if Enforce/Require are transposed in any of the four files; reuse `extract_canonical_pipeline!/2` (no parallel extraction path) |

---

## Wave 0 Requirements

- [ ] `test/integration/phase100_sender_constraint_e2e_test.exs` — NEW; BIND-01 (DPoP) + BIND-02 (mTLS) happy-path proofs (lift phase81 harness + KeyCache publish-then-sign helper).
- [ ] `test/lockspire/plug/require_token_test.exs` — ADD bound-but-unverified→403 and bearer→pass clauses (BIND-03 runtime).
- [ ] `test/lockspire/plug/enforce_sender_constraints_test.exs` — ADD `binding_verified: true` assertions on the existing success-path tests (BIND-03 positive).
- [ ] `test/lockspire/access_token_test.exs` — UPDATE defaults test to assert `binding_verified == false` (D-01).
- [ ] `test/lockspire/release_readiness_contract_test.exs` — ADD ordering clause (D-05; passes against current content).
- [ ] (Wave-0 spike, A1) One assertion that a list-`aud` token passes `VerifyToken` audience check (signer emits list `aud`; phase81 used string).
- [ ] (Wave-0 spike, A3) Confirm the D-03 guard returns `403` via a status-explicit path (`handle_invalid_token/2` currently emits `401`).

*Framework install: none — ExUnit is built-in; `mix test.setup` already exists.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | All phase behaviors have automated verification via ExUnit (integration + plug-unit + contract). | — |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-28 (plan-checker VERIFICATION PASSED; `wave_0_complete` flips true once execute-phase creates the Wave 0 test files)

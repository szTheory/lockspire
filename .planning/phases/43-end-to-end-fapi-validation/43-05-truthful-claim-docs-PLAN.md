---
phase: 43-end-to-end-fapi-validation
plan: 05
type: execute
wave: 1
depends_on: []
files_modified:
  - SECURITY.md
  - README.md
  - docs/supported-surface.md
autonomous: true
requirements: [FAPI-05, FAPI-06]
must_haves:
  truths:
    - "SECURITY.md, README.md, and docs/supported-surface.md each contain positive FAPI 2.0 claim language describing what is enforced (D-19)"
    - "All three docs name the enforced surfaces: PAR, DPoP, ES256/PS256, exact redirect match, RFC 9207 iss on auth responses, FAPI 2.0 keys in discovery (D-19)"
    - "All three docs explicitly state what is NOT claimed: no external OIDF certification, no mTLS (D-19)"
    - "Doc edits are additive bullets in existing supported/in-scope and out-of-scope blocks — no rewrites"
    - "Exact assertion strings are pinned by Plan 07's release_readiness_contract_test (D-20)"
  artifacts:
    - path: "SECURITY.md"
      provides: "FAPI 2.0 enforcement bullets in '## Supported security surface' and a new '## FAPI 2.0 posture' section"
      contains: "FAPI 2.0"
    - path: "README.md"
      provides: "FAPI 2.0 bullets in 'What v0.1 includes' and 'What v0.1 does not include'"
      contains: "FAPI 2.0"
    - path: "docs/supported-surface.md"
      provides: "FAPI 2.0 bullets in '## Supported in scope' and '## Explicitly out of scope'"
      contains: "FAPI 2.0"
  key_links:
    - from: "Doc bullets in SECURITY.md / README.md / docs/supported-surface.md"
      to: "test/lockspire/release_readiness_contract_test.exs (Plan 07)"
      via: "Plan 07 contract test asserts each pinned string appears verbatim"
      pattern: "FAPI 2\\.0|RFC 9207|PAR|DPoP|ES256|PS256|exact-match redirect"
---

<objective>
Add positive and negative FAPI 2.0 claim language to the three public-facing docs that currently
carry effectively zero FAPI 2.0 wording despite the milestone shipping the full enforcement
stack. Per D-19/D-20, this language is locked by Plan 07's truth-in-docs contract test, so the
exact strings added here MUST appear verbatim in Plan 07's assertions.

Purpose: Truth-in-docs — the v1.10 archive cannot proceed if the public-facing docs do not
truthfully describe what Lockspire enforces (positive) and what it does NOT certify (negative).

Output: Three modified docs, additive bullets in existing supported/out-of-scope blocks. No
rewrites of existing content.

CRITICAL — String contract with Plan 07: All bracketed strings below must be reproduced
EXACTLY in both this plan's edits and Plan 07's contract test assertions. The two plans share a
single string vocabulary (defined here). Plan 07 reads from this same plan file for the exact
assertion strings.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md
@.planning/phases/43-end-to-end-fapi-validation/43-RESEARCH.md
@.planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md

<pinned_strings>
The following 8 phrases are the LOCKED string vocabulary for FAPI 2.0 claim documentation.
Each MUST appear at least once in EACH of the three docs (SECURITY.md, README.md,
docs/supported-surface.md) AND be asserted by Plan 07's contract test:

POSITIVE (enforced):
1. `FAPI 2.0 Security Profile`
2. `PAR`
3. `DPoP`
4. `ES256/PS256`
5. `exact-match redirect URIs`
6. `RFC 9207`
7. `authorization_response_iss_parameter_supported`
8. `require_pushed_authorization_requests`

NEGATIVE (not claimed):
A. The word `certified` MUST NOT appear in any of the three docs (refuted by Plan 07)
B. The phrase `mTLS` MUST appear in negative-claim context in each doc (e.g., "mTLS is out of scope")
C. The phrase `OIDF` MUST appear in negative-claim context in each doc (e.g., "no OIDF conformance certification")
</pinned_strings>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add FAPI 2.0 claim bullets to SECURITY.md (D-19)</name>
  <files>SECURITY.md</files>
  <read_first>
    - SECURITY.md (entire file — confirm existing "## Supported security surface" and "## Secure defaults" headings and bullet style)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-19 — describe enforced + NOT claimed)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Add positive FAPI 2.0 claim language" section)
    - .planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-PLAN.md (THIS plan's `<pinned_strings>` block — the string vocabulary)
  </read_first>
  <action>
    Edit `SECURITY.md` ADDITIVELY — do NOT rewrite existing text.

    1. Append these bullets to the existing "## Supported security surface" list (after the
       existing bullets, before any closing paragraph). Use the EXACT phrases from `<pinned_strings>`:
       ```
       - FAPI 2.0 Security Profile enforcement when `security_profile: :fapi_2_0_security` is set globally or per-client: PAR-required at /authorize, DPoP sender-constrained access tokens at /token and /userinfo, ES256/PS256 signing only, exact-match redirect URIs with zero tolerance for trailing slashes or query drift
       - RFC 9207 `iss` parameter on every authorization-response redirect (success, denial, and error) for all clients regardless of profile
       - Truthful FAPI 2.0 keys in `.well-known/openid-configuration`: `authorization_response_iss_parameter_supported` (always true) and `require_pushed_authorization_requests` (true only when the global server policy is `:fapi_2_0_security`)
       ```

    2. Append a NEW H2 section titled `## FAPI 2.0 posture` immediately after the existing
       "## Secure defaults" section. Use this EXACT content:
       ```
       ## FAPI 2.0 posture

       Lockspire ships the FAPI 2.0 Security Profile enforcement stack listed above and pins the
       canonical OIDF FAPI 2.0 plan (`fapi2-security-profile-final-test-plan`) plus its variant
       axes in `scripts/conformance/fapi2-plan.json` and `docs/maintainer-conformance.md`.

       Lockspire does NOT claim:

       - external OIDF FAPI 2.0 conformance suite certification (the harness is wired and pinned, but the live Docker run remains a manual maintainer step and is not a CI pass-gate)
       - mTLS client authentication or mTLS-bound access tokens (DPoP is the supported sender-constraining mechanism; mTLS is permanently out of scope)
       ```

    Do NOT remove the existing "preview" / "v0.1" wording elsewhere in the file. Do NOT add the
    word `certified` (Plan 07 will refute it).
  </action>
  <verify>
    <automated>scripts/check_fapi_doc_strings.sh SECURITY.md || mix test test/lockspire/release_readiness_contract_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "FAPI 2.0 Security Profile" SECURITY.md` returns >= 1
    - `grep -c "RFC 9207" SECURITY.md` returns >= 1
    - `grep -c "PAR" SECURITY.md` returns >= 1
    - `grep -c "DPoP" SECURITY.md` returns >= 1
    - `grep -c "ES256/PS256" SECURITY.md` returns >= 1
    - `grep -c "exact-match redirect URIs" SECURITY.md` returns >= 1
    - `grep -c "authorization_response_iss_parameter_supported" SECURITY.md` returns >= 1
    - `grep -c "require_pushed_authorization_requests" SECURITY.md` returns >= 1
    - `grep -c "## FAPI 2.0 posture" SECURITY.md` returns 1
    - `grep -c "mTLS" SECURITY.md` returns >= 1 (in negative-claim context)
    - `grep -c "OIDF" SECURITY.md` returns >= 1 (in negative-claim context)
    - `grep -wc "certified" SECURITY.md` returns 0 (the literal word "certified" must NOT appear)
  </acceptance_criteria>
  <done>
    SECURITY.md carries all 8 positive pinned strings + 2 negative claim mentions; the word "certified" is absent.
  </done>
</task>

<task type="auto">
  <name>Task 2: Add FAPI 2.0 claim bullets to README.md (D-19)</name>
  <files>README.md</files>
  <read_first>
    - README.md (entire file — confirm existing "## What v0.1 includes" and "## What v0.1 does not include" headings)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-19)
    - .planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-PLAN.md (`<pinned_strings>` block)
  </read_first>
  <action>
    Edit `README.md` ADDITIVELY — do NOT rewrite existing text.

    1. Append these bullets to the existing `## What v0.1 includes` list (after the existing bullets):
       ```
       - FAPI 2.0 Security Profile enforcement (opt-in via `security_profile: :fapi_2_0_security` globally or per-client): PAR-required at /authorize, DPoP sender-constrained access tokens, ES256/PS256 signing only, exact-match redirect URIs
       - RFC 9207 `iss` parameter on every authorization-response redirect for all clients regardless of profile
       - Truthful FAPI 2.0 keys in `.well-known/openid-configuration` (`authorization_response_iss_parameter_supported` always; `require_pushed_authorization_requests` only when the global server policy is `:fapi_2_0_security`)
       ```

    2. Append these bullets to the existing `## What v0.1 does not include` list:
       ```
       - External OIDF FAPI 2.0 conformance suite certification (Lockspire pins the canonical plan and variants but the live Docker run remains a manual maintainer step and is not gated by CI)
       - mTLS client authentication or mTLS-bound access tokens (DPoP is the supported sender-constraining mechanism)
       ```

    Do NOT remove or reword existing bullets. Do NOT add the word `certified`.
  </action>
  <verify>
    <automated>mix test test/lockspire/release_readiness_contract_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "FAPI 2.0 Security Profile" README.md` returns >= 1
    - `grep -c "RFC 9207" README.md` returns >= 1
    - `grep -c "PAR" README.md` returns >= 1
    - `grep -c "DPoP" README.md` returns >= 1
    - `grep -c "ES256/PS256" README.md` returns >= 1
    - `grep -c "exact-match redirect URIs" README.md` returns >= 1
    - `grep -c "authorization_response_iss_parameter_supported" README.md` returns >= 1
    - `grep -c "require_pushed_authorization_requests" README.md` returns >= 1
    - `grep -c "mTLS" README.md` returns >= 1
    - `grep -c "OIDF" README.md` returns >= 1
    - `grep -wc "certified" README.md` returns 0
  </acceptance_criteria>
  <done>
    README.md carries all 8 positive pinned strings + 2 negative claim mentions; the word "certified" is absent.
  </done>
</task>

<task type="auto">
  <name>Task 3: Add FAPI 2.0 claim bullets to docs/supported-surface.md (D-19)</name>
  <files>docs/supported-surface.md</files>
  <read_first>
    - docs/supported-surface.md (entire file — confirm existing "## Supported in scope" and "## Explicitly out of scope" headings)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-19)
    - .planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-PLAN.md (`<pinned_strings>` block)
  </read_first>
  <action>
    Edit `docs/supported-surface.md` ADDITIVELY — do NOT rewrite existing text.

    1. Append these bullets to the existing `## Supported in scope` list (after the last existing bullet):
       ```
       - FAPI 2.0 Security Profile enforcement when `security_profile: :fapi_2_0_security` is set globally or per-client: PAR-required at /authorize, DPoP sender-constrained access tokens, ES256/PS256 signing only, exact-match redirect URIs with zero tolerance for trailing slashes or query drift
       - RFC 9207 `iss` parameter emitted on every authorization-response redirect (success, denial, and error) for all clients regardless of profile
       - Truthful FAPI 2.0 keys in `.well-known/openid-configuration`: `authorization_response_iss_parameter_supported` always true; `require_pushed_authorization_requests` true only when the global server policy is `:fapi_2_0_security`
       ```

    2. Append these bullets to the existing `## Explicitly out of scope` list (after the last existing bullet):
       ```
       - External OIDF FAPI 2.0 conformance suite certification — Lockspire pins the canonical OIDF FAPI 2.0 plan (`fapi2-security-profile-final-test-plan`) and variant axes in `scripts/conformance/fapi2-plan.json` and `docs/maintainer-conformance.md`, but the live Docker run remains a documented manual maintainer step and is not a CI pass-gate
       - mTLS client authentication and mTLS-bound access tokens (DPoP is the supported sender-constraining mechanism for FAPI 2.0; mTLS is permanently out of scope per the v1.10 milestone)
       ```

    Do NOT remove or reword existing bullets. Do NOT add the word `certified`.
  </action>
  <verify>
    <automated>mix test test/lockspire/release_readiness_contract_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "FAPI 2.0 Security Profile" docs/supported-surface.md` returns >= 1
    - `grep -c "RFC 9207" docs/supported-surface.md` returns >= 1
    - `grep -c "PAR" docs/supported-surface.md` returns >= 1
    - `grep -c "DPoP" docs/supported-surface.md` returns >= 1
    - `grep -c "ES256/PS256" docs/supported-surface.md` returns >= 1
    - `grep -c "exact-match redirect URIs" docs/supported-surface.md` returns >= 1
    - `grep -c "authorization_response_iss_parameter_supported" docs/supported-surface.md` returns >= 1
    - `grep -c "require_pushed_authorization_requests" docs/supported-surface.md` returns >= 1
    - `grep -c "mTLS" docs/supported-surface.md` returns >= 1
    - `grep -c "OIDF" docs/supported-surface.md` returns >= 1
    - `grep -wc "certified" docs/supported-surface.md` returns 0
  </acceptance_criteria>
  <done>
    docs/supported-surface.md carries all 8 positive pinned strings + 2 negative claim mentions; "certified" is absent.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Public-facing docs -> RP / integrator / auditor | These docs ARE the public claim contract; overclaim here is a security incident under FAPI 2.0 governance |
| Doc text -> release_readiness_contract_test (Plan 07) | Pinned strings here are the executable contract that prevents future doc drift |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-22 | Spoofing (overclaim) | Public docs claim FAPI 2.0 conformance certification not actually held | mitigate | All three docs carry an explicit "does NOT claim certification" bullet referencing the manual-only OIDF run. The literal word `certified` is forbidden by acceptance criteria + Plan 07 refute assertion. Severity: HIGH — overclaiming certification is the worst-case truth-in-docs failure. |
| T-43-23 | Spoofing (overclaim) | Public docs claim mTLS support that does not exist | mitigate | All three docs carry an explicit "mTLS is out of scope" bullet. Plan 07 asserts the negative claim appears. Severity: HIGH — false mTLS claim would let RPs pin to a non-existent surface. |
| T-43-24 | Tampering (silent doc drift after future edits) | Future edits remove the FAPI 2.0 claim bullets, leaving the enforcement stack undocumented | mitigate | Plan 07's release_readiness_contract_test asserts the 8 pinned positive strings + 2 negative-claim phrases appear; CI catches drift on the next PR. Severity: HIGH — addressed structurally by Plan 07. |
| T-43-25 | Information Disclosure | Doc reveals internal env var names or implementation details that constrain operator changes | accept | Doc text references public config keys only (`security_profile`, `:fapi_2_0_security`); no internal-only secrets disclosed. Severity: LOW. |
| T-43-26 | Repudiation | RP cannot prove which Lockspire version made which FAPI claim | accept | Docs are versioned in git; each release tag captures the doc state at that moment. Severity: LOW. |
</threat_model>

<verification>
- All 3 doc files contain all 8 positive pinned strings (per acceptance criteria)
- All 3 doc files contain the 2 negative-claim phrases ("mTLS", "OIDF") in out-of-scope context
- The literal word "certified" does NOT appear in any of the 3 doc files (`grep -wc "certified" SECURITY.md README.md docs/supported-surface.md` shows 0 in each)
- No existing content in any of the 3 files was rewritten — diff shows only additions
</verification>

<success_criteria>
- The three public-facing docs truthfully describe FAPI 2.0 enforcement using the locked string vocabulary
- The two negative claims (no certification, no mTLS) appear in each doc
- Plan 07's contract test will assert all 8 positive strings + refute "certified" in each file
- Future doc edits cannot silently drop FAPI claims — the contract test gates that drift
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-05-SUMMARY.md`
</output>

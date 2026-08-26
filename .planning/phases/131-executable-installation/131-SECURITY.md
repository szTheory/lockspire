---
phase: 131
slug: executable-installation
status: verified
threats_total: 31
threats_closed: 31
threats_open: 0
asvs_level: 1
created: 2026-08-26
---

# Phase 131 — Security

> Per-phase security contract for executable installation, generated host integration, migration delivery, and verification.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host router ↔ Lockspire routers | The host supplies its browser and operator-authentication pipelines before forwarding into Lockspire. | Authenticated operator context and public OAuth/OIDC requests |
| Host consent UI ↔ protocol core | Generated host presentation receives an allowlisted view of an authoritative stored interaction and submits to the existing completion controller. | Subject identity, client display fields, scopes, decision |
| Packaged installer ↔ host filesystem | Lockspire plans migrations and managed files before applying journaled, manifest-last changes. | Source bytes, checksums, destination paths, manifest inventory |
| Generated smoke ↔ host endpoint | Executable tests act as an OAuth/OIDC client without changing the host security profile. | Client metadata, PKCE verifier/challenge, state, nonce |
| Verifier ↔ host configuration/runtime | Read-only verification inspects configured seams, compiled routes, and migration delivery. | Module names, paths, configuration keys, migration status |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-131-01 | Elevation of privilege | Generated router | high | mitigate | Require the host-owned `:require_operator` pipeline before the admin forward; negative compile proof covers omission. | closed |
| T-131-02 | Tampering | Generated router | high | mitigate | Compile the rendered macro and inspect actual `Phoenix.Router.routes/1` ordering. | closed |
| T-131-03 | Information disclosure | Claims resolver | medium | mitigate | Generate only the public `subject`, `id_token`, and `userinfo` claim maps. | closed |
| T-131-04 | Denial of service | Logout seam | medium | mitigate | Generate and behaviorally exercise the configured host `logout_path`. | closed |
| T-131-05 | Tampering | Migration planner | high | mitigate | Inventory all packaged and host migrations before application. | closed |
| T-131-06 | Tampering | Migration delivery | high | mitigate | Reject identity/content collisions; use expected checksums and exclusive creation. | closed |
| T-131-07 | Denial of service | Migration package | medium | mitigate | Reject malformed packaged migration filenames during preflight. | closed |
| T-131-08 | Information disclosure | Migration diagnostics | low | mitigate | Report paths and identities without emitting migration contents. | closed |
| T-131-09 | Spoofing | Consent context | high | mitigate | Exact-match the stored account identifier to the host resolver subject. | closed |
| T-131-10 | Tampering | Consent lifecycle | high | mitigate | Derive state authoritatively; terminal and error renders expose no decision forms. | closed |
| T-131-11 | Information disclosure | Consent presentation | high | mitigate | Cross the host seam through an allowlisted context and assert seeded secrets remain absent. | closed |
| T-131-12 | Denial of service | Consent submission | medium | mitigate | Disable both decisions while submitting and retain native CSRF-protected POSTs. | closed |
| T-131-13 | Repudiation | Consent completion | medium | mitigate | Submit only to the context-provided existing interaction completion route. | closed |
| T-131-14 | Tampering | Install orchestration | high | mitigate | Finish one immutable migration/file/manifest operation plan before applying it. | closed |
| T-131-15 | Elevation of privilege | Install manifest | high | mitigate | Treat the manifest as audit data; derive authority from a fresh disk inventory. | closed |
| T-131-16 | Denial of service | File transaction | high | mitigate | Journal staged changes, roll back ordinary failures, recover interruptions, and refuse unsafe symlink paths. | closed |
| T-131-17 | Repudiation | Install manifest | medium | mitigate | Persist deterministic migration version/name/path/checksum inventory and status. | closed |
| T-131-18 | Tampering | Default smoke | high | mitigate | Assert the default profile, PKCE S256, and exact redirect rejection without changing host policy. | closed |
| T-131-19 | Spoofing | Default smoke | high | mitigate | Generate verifier, nonce, and state with 32-byte CSPRNG values; reject predictable template forms in tests. | closed |
| T-131-20 | Elevation of privilege | FAPI smoke | high | mitigate | Require explicit `--with-fapi-smoke` selection and assert the FAPI profile. | closed |
| T-131-21 | Repudiation | Generated proofs | medium | mitigate | Render, compile, execute, and manifest-track generated smoke artifacts. | closed |
| T-131-22 | Elevation of privilege | Install verifier | high | mitigate | Verify compiled host/consent/admin/public route shape and ordering; retain compile-time operator-pipeline enforcement. | closed |
| T-131-23 | Tampering | Install verifier | high | mitigate | Check required configuration independently and reject invalid or missing values without fallback. | closed |
| T-131-24 | Information disclosure | Install verifier | high | mitigate | Emit only safe module/path/key diagnostics with explicit redaction tests. | closed |
| T-131-25A | Denial of service | Migration verification | medium | mitigate | Distinguish missing delivery from Ecto migration state and provide bounded remediation. | closed |
| T-131-26A | Repudiation | Installation docs | medium | mitigate | Test generated artifacts and documentation contracts against actual behavior. | closed |
| T-131-25B | Elevation of privilege / Tampering | Async consent | high | mitigate | Render initial loading states without forms or a completion target. | closed |
| T-131-26B | Information disclosure | Async consent | high | mitigate | Convert async exits to generic safe errors and assert task details are absent. | closed |
| T-131-27 | Spoofing | Async consent | high | mitigate | Accept only the route interaction identifier plus server-owned mount context. | closed |
| T-131-28 | Denial of service | Async consent | medium | mitigate | Run one named load per connected mount and safely handle exits and duplicate submission. | closed |
| T-131-29 | Repudiation | Async consent | medium | mitigate | Keep approval and denial on the existing interaction-controller route. | closed |

The duplicate numeric suffixes `25` and `26` originate in separate Phase 131 plans; `A` and `B` disambiguate them here without rewriting the source plans.

## Accepted Risks Log

No accepted risks.

The pure-Elixir file transaction protects ordinary failures, interrupted writes, destination replacement, and symlinked managed paths. It does not claim protection from a hostile same-user process swapping an ancestor directory between checks; eliminating that race requires native `openat`/`O_NOFOLLOW`-style filesystem support and is outside this embedded installer boundary.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-26 | 31 | 30 | 1 | `gsd-security-auditor` initial ASVS L1 audit |
| 2026-08-26 | 31 | 31 | 0 | `gsd-security-auditor` re-audit after `03e7b6f` |

Focused evidence:

- `mix test test/integration/install_generator_test.exs` — 12 tests, 0 failures after the T-131-19 repair.
- The broader installation, migration, transaction, consent, verifier, and generated-host suites passed during the initial audit — 61 tests, 0 failures across the two commands recorded by the auditor.

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks require an Accepted Risks Log entry.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-26

---
phase: "157"
slug: "host-surfaces-redaction-sweep-release-proof"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-16"
---

# Phase 157 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Storage → host telemetry/logs | Ecto repo query events and logs reach host handlers (APM, OpenTelemetry, Sentry) | Stored signing-key envelopes (secret) |
| Lockspire → telemetry/audit/admin | Lockspire metadata, audit rows, admin LiveView assigns and HTML | Key ids, KEK ids, counts, reason atoms (non-secret); key material must never cross |
| Decode → JOSE → exceptions/Oban | Malformed decoded JWK maps raising inside JOSE; Oban persists formatted errors | Private JWK members (secret) |
| Generator/demo/clean-room → host config | Printed and committed KEK config | KEK values (secret in prod; demo/dev literals non-production) |
| Docs/release → operators | Upgrade order, rotation, backup, rollback guidance | Operational safety instructions |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-157-01 | Information Disclosure | SigningKeyStore reads/inserts | high | mitigate | `sensitive: true` on every key-column path; JWKS paths select `@public_fields` (signing_key_store.ex:14,23,33,45,60,74,101,114,237,257,280,287; support.ex:43-47); sweep key_material_leak_test.exs:203-214,404-424 | closed |
| T-157-02 | Information Disclosure | SigningKeyRecord changeset/inspect | medium | mitigate | Inspect derive except, `redact: true`, column kept out of cast params, `put_change` (signing_key_record.ex:12,19,33,53-54); signing_key_record_test.exs:39-49 | closed |
| T-157-03 | Information Disclosure | JOSE exceptions → logs / Oban errors | high | mitigate | `PrivateJwk.to_jwk/1` bare rescue/catch returning `:invalid_signing_key` (private_jwk.ex:45-55), used by all six consumers; matcher proof key_material_leak_test.exs:597-634 | closed |
| T-157-04 | Information Disclosure | Telemetry/audit metadata | medium | mitigate | Nine key names (atom+string) in both drop sets plus `LSK` v1 value clause (redaction.ex:9-17,55-63,104-112,150-158,242) | closed |
| T-157-05 | Repudiation | Over-dropping kid/kek_id | low | mitigate | redaction_test.exs:163-167 asserts kid/kek_id/previous_kek_id/key_id survive | closed |
| T-157-06 | Elevation of Privilege | Generator dev literal reused in prod | high | mitigate | Per-install random dev literal, labelled dev/test only; prod block env-only and raises (install.ex:126,141-154); install_generator_test.exs:300-341 | closed |
| T-157-07 | Information Disclosure | KEK in compile-time config | high | mitigate | Generator prints only; demo and clean-room KEK in `runtime.exs` only; check_bootstrap gate (build_provider.py:394-397); compile_env guard config_key_encryption_test.exs:137 | closed |
| T-157-08 | Elevation of Privilege | Demo KEK literal copied to real deployment | medium | mitigate | Single demo-only literal in non-prod branch of examples/adoption_demo/config/runtime.exs:16-24; prod raises; compose marks demo-only | closed |
| T-157-09 | Information Disclosure | Clean-room KEK in evidence/source | medium | mitigate | Per-run `os.urandom(32)` KEK registered as secret (clean_room_saas_journey.py:868-870); source literal gate (build_provider.py:396-397) | closed |
| T-157-10 | Tampering | Journey test leaves committed rows | low | mitigate | Random-prefixed kids, foreign-row guard, on_exit cleanup (signing_key_upgrade_journey_test.exs:22-44,262-277) | closed |
| T-157-11 | Information Disclosure | CI logs from `--check` / doctor | low | accept | See AR-157-01 | closed |
| T-157-12 | Tampering (process) | Major bump from commit text | medium | mitigate | D-22 grep over unpushed commits empty (re-run by auditor, 128 commits) | closed |
| T-157-13 | Denial of Service | KEK removed / `:reject` flipped too early | high | mitigate | Guide orders `--check` before `:reject` and before old-KEK removal; upgrade_guide_contract_test.exs:11-48 | closed |
| T-157-14 | Information Disclosure | Backups / crash dumps | medium | mitigate | Guide covers backup remanence, separate KEK backup, crash-dump hygiene; contract test phrases | closed |
| T-157-15 | Tampering (process) | Major bump from release text | medium | mitigate | 157-RELEASE-NOTES.md `feat(keys):` title, minor wording, no marker | closed |
| T-157-16 | Repudiation | Wrong version in docs | low | mitigate | Version-agnostic guide (contract test refutes x.y.z); `{VERSION}` placeholder in release notes | closed |
| T-157-17 | Denial of Service | Consumer crash on malformed key | medium | mitigate | Per-consumer malformed-key tests return existing errors (envelope_signing_consumers_test.exs:135,198,242,287,343,388) | closed |
| T-157-18 | Information Disclosure | Oban logout worker error persistence | high | mitigate | Real `{:discard, :invalid_signing_key}` and recorded reason through matcher (backchannel_logout_delivery_worker_test.exs:204-264) | closed |
| T-157-19 | Repudiation | Vacuous leak proof | low | mitigate | Vacuity guards and matcher canary tests (key_material_leak_test.exs:246-295,610-631) | closed |
| T-157-20 | Repudiation | Telemetry doc names nonexistent events | low | mitigate | All 10 documented `[:lockspire, :key, …]` events exist in lib/; refusal documented as `decode_failed` reason `plaintext_key_refused` | closed |
| T-157-SC | Tampering | Package installs (supply chain) | low | accept | See AR-157-02 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-157-01 | T-157-11 | `--check` and doctor print only ids, counts and reason atoms; their output passes the canary matcher in the leak sweep, and the clean-room KEK is registered for the evidence scan. | Plan 157-03 threat model; auditor verified | 2026-10-16 |
| AR-157-02 | T-157-SC | No dependency installs: `git diff v1.42 -- mix.lock priv/repo/migrations` empty; `mix.exs` diff touches docs extras only. | Plan 157-01 threat model; auditor verified | 2026-10-16 |

Phase 155 accepted risks resolved by this phase:
- **AR-02** (fixed clean-room test KEK literal): resolved — clean-room host reads a per-run random KEK from `config/runtime.exs`, registered as a secret; `check_bootstrap` rejects embedded base64 KEK literals.
- **AR-03** (demo has no KEK): resolved — `examples/adoption_demo/config/runtime.exs` provides a demo-only KEK under `:reject`; seeds use the public key API; CI runs `--check` and doctor on the demo.
- **AR-01** (raw KEK resident in app env) remains accepted and is now documented in the upgrade guide; `{:system, "ENV"}` resolution stays deferred (KEK-05).

Informational (non-blocking): `build_provider.py` run standalone sets a fallback random KEK without `register_secret` (journey path registers it); generator dev/test blocks land in host `dev.exs`/`test.exs` by design (random per install, labelled).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-16 | 21 | 21 | 0 | gsd-security-auditor (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-16

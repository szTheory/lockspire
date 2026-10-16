---
phase: "153"
slug: "configure-support-page-refinement"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-15"
---

# Phase 153 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail. Retroactive audit at HEAD d84988a0 (the phase's code landed in squash commit d44b95dd, PR #123).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Rendered admin page → baseline and review images | Anything on screen can end up in images under the ignored `tmp/` tree and in tracked manifests. | Visible text and field values |
| Review browser → demo database | A stray submit could rotate, revoke or create credentials. | Form submissions |
| Admin copy and forms → stored policy | Wording and layout changes must not change form names, handlers or stored values. | Policy form params |
| Shared components → every admin page | `page_hero`, theme select and redaction markers are shared. | Presentation of actions, consequences, redaction |
| Package graph | Plans allowed no new dependencies. | `mix.exs`, `mix.lock`, CI |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-153-SC | Tampering | Dependency installation (all 7 plans) | high | mitigate | d44b95dd only removed `bandit`/`thousand_island`; `git log d44b95dd..HEAD -- mix.exs mix.lock` is empty. CI added only `node --test test/browser/admin_multi_value_test.mjs` (built-in runner). | closed |
| T-153-BASE-01 | Information Disclosure | Baseline screenshots | medium | mitigate | 30-row manifest, each "Redaction check: Pass" (`153-BASELINE-SCREENSHOTS.md`); images under ignored `tmp/` (`.gitignore:15`), 0 tracked. | closed |
| T-153-BASE-02 | Tampering | Demo database | medium | mitigate | Navigate-only on the isolated `lockspire-ui-review` demo with synthetic seed data (`153-BASELINE-SCREENSHOTS.md:9`). | closed |
| T-153-01 | Information Disclosure | Provider settings and shared hero | low | mitigate | `policies_live/index_test.exs:46,108`; `RouteAssertions.assert_redaction_boundary!` (`route_assertions.ex:104-126`) from `route_contract_test.exs`. | closed |
| T-153-02 | Tampering | Theme selector styling | low | mitigate | Native `<select>` (`admin_components.ex:381`, `admin_layout_live.ex:296`); sync JS `:211-260`; focus/motion asserted `css_assertions.ex:75-94,180-197`. | closed |
| T-153-03 | Tampering | Provider policy copy and forms | medium | mitigate | Save, invalid and failed-save tests on every policy page (`par_test.exs:186,202,224`; `dpop_test.exs:181,193,208`; `security_profile_test.exs:224,264,307`; `dcr_test.exs:344,375,500`); inheritance `par_test.exs:71,129`, `dpop_test.exs:70,129`, `security_profile_test.exs:80`. | closed |
| T-153-04 | Information Disclosure | Signing keys and setup tokens | medium | mitigate | `forbidden_key_material_samples()` asserted at 9 sites in `keys_live_test.exs`; copy-once `iat_live_test.exs:518-574`. | closed |
| T-153-05 | Tampering | Consent/token state and actions | medium | mitigate | Scope text beside single vs family revoke (`tokens_live_test.exs:431-473`), lineage `:289`, error paths `:558,627,655`, filters `:96`; consents `:76,266,367,399`; WR-01 fallback clauses `tokens_live/show.ex:73,108`. | closed |
| T-153-06 | Information Disclosure | Client/queue rendered state | medium | mitigate | Copy-once, redaction and filter tests in `clients_live_test.exs`, `clients_live/show_test.exs`; read-only and filter tests in interactions, device authorizations and logout deliveries; shared marker `admin_components.ex:751,768`. | closed |
| T-153-07 | Tampering | Shared page-hero contract | low | mitigate | `page_hero/1` declares only `title`/`body`/`class` + slots (`admin_components.ex:77-83`), so stale callers fail at compile time; `route_contract_test.exs:61-71` refutes "eyebrow". | closed |
| T-153-08 | Information Disclosure | Rendered admin evidence | medium | mitigate | Read-only GETs and synthetic data recorded in `153-ROUTE-REVIEW.md`, `153-AUTOMATED-UX-SWEEP.md:9`, `153-UI-REVIEW-SNAPSHOT.md:9,37,53`; 0 v1.42 images tracked. | closed |
| T-153-09 | Tampering | Route review inventory | low | mitigate | Re-run at HEAD: `RouteScorecards.expected_routes/0` (30 paths) equals the 30 rows in `153-ROUTE-REVIEW.md` (empty sorted diff). | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

*Accepted risks do not resurface in future audit runs.*

---

## Auditor Notes (non-blocking)

- T-153-09 is now a one-time check. The automated matrix-vs-registry test was dropped in f0b0bd63 (WR-02 accepted in `153-REVIEW-DISPOSITION.md`); `route_contract_test.exs:11-39` keeps only the historical-subset check.
- PR #123 added DCR lifetime inputs (`policies_live/dcr/lifetime_hint.ex`). `153-LIFETIME-TRUTH.md` records that app and app-management-token lifetimes are not enforced and client-secret expiry is metadata only. The UI states those limits; the protocol gap is tracked in todo `2026-10-13-audit-dcr-default-lifetime-semantics.md`, not a Phase 153 threat.
- WR-03 (demo smoke tied to seed data) is deferred with no security impact.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-15 | 12 | 12 | 0 | gsd-security-auditor (retroactive, ASVS L1, block_on high; admin suite + adoption demo contract 310 passed) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-15

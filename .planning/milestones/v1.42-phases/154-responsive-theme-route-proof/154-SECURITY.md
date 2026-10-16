---
phase: "154"
slug: "responsive-theme-route-proof"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-15"
---

# Phase 154 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Rendered admin page → saved images and tracked evidence | Anything visible on screen can end up in images under the ignored `tmp/` tree and in tracked markdown rows. | Visible text, field values, data-* attributes |
| Capture script → stateful admin controls | A stray click or Enter could rotate, revoke, or generate credentials in the demo. | Browser input events |
| Local tooling → CI | The real-browser harness must stay out of CI. | Workflow definitions |
| Shared CSS and components → every admin page | One token or selector change affects every page in both themes. | Presentation of actions, consequences, redaction markers |
| Source tree → evidence | Captures from stale source would misrepresent the shipped UI. | Source SHA, served stylesheet |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-154-01 | Information Disclosure | admin_route_proof.mjs screenshots | high | mitigate | `SENSITIVE_PATTERNS` mirrors `BrowserEvidence.sensitive_patterns/0` (`test/browser/admin_route_proof.mjs:82-112`). `collectScanText` scans innerText, field values, option text and data-* values (`:180-197`, `:320-333`). A hit throws before the screenshot (`:485-488`). Output goes to the ignored `tmp/` tree; no v1.42 images are tracked. Node tests at `admin_route_proof_test.mjs:57-89,130`. | closed |
| T-154-02 | Tampering | admin_route_proof.mjs navigation | high | mitigate | The only submit is the synthetic `ops` login (`:411-418`). The only key presses are Tab (`:464`) and Escape (`:471`). No click, Enter, Space or fill exists in the harness. | closed |
| T-154-03 | Denial of Service | CI pipeline | low | mitigate | CI references only the pre-existing `admin_multi_value_test.mjs` (`ci.yml:161`); `.github` is unchanged since ef6043ec. | closed |
| T-154-04 | Repudiation | admin_css.ex contrast tokens | medium | mitigate | `CssAssertions.assert_contrast_pairs!/0` names each failing ratio (`css_assertions.ex:182-191`), run from `css_contract_test.exs` under `mix test.fast`. | closed |
| T-154-05 | Tampering | admin_css.ex redaction presentation | low | mitigate | The CSS diff adds only the control-border token, three border swaps, `scroll-padding-block` and two wrap blocks; no redaction selector changed. Admin suite 518 passed (SAFE-GATE a). | closed |
| T-154-06 | Information Disclosure | app details / rotate tests | high | mitigate | `assert_page_contract!` runs the token-like-text scan after stripping only Phoenix session plumbing. The one removed test line is a binding rename; no assertion was lost. | closed |
| T-154-07 | Repudiation | html_assertions.ex | low | mitigate | Capability-named helper (`assert_page_contract!`); `inventory_contract_test.exs` runs in the fast suite (1554 passed). | closed |
| T-154-08 | Tampering | keys_live key_next_action_summary | medium | mitigate | Only the unreachable empty-list clause was removed; the call site is guarded by `:if={entry.next_actions != []}` (`keys_live/index.ex:136-137`). | closed |
| T-154-09 | Information Disclosure | /admin/iats/new copy-once render | high | mitigate | The page contract runs before token generation (`iat_live_test.exs:521`) and on the redacted inventory (`:307`); copy-once assertions unchanged. | closed |
| T-154-10 | Tampering | device authorization filter | medium | mitigate | Pure clause move to `device_authorizations_live/index.ex:200`; `device_authorization_filter/1` still accepts only `"pending"` (`:192-193`). | closed |
| T-154-11 | Elevation of Privilege | Operate queues | high | mitigate | No queue markup changed; `route_contract_test.exs:45` keeps queue routes read-only. | closed |
| T-154-12 | Tampering | token/consent revocation scope | high | mitigate | Test diffs are additions only; family and kind-specific revoke tests remain (`tokens_live_test.exs:289,431,558`; `consents_live_test.exs:367,399`). | closed |
| T-154-13 | Tampering | admin_css.ex / admin_components.ex fixes | high | mitigate | No added `display: none` or ellipsis; every fix is wrap, gap or border. Full admin suite passed. | closed |
| T-154-14 | Information Disclosure | 154-RESPONSIVE-SWEEP.md rows | high | mitigate | Harness aborts on a denylist hit; `scanSensitive` over the sweep doc: 0 hits; `BrowserEvidence.parse!/1` raises on a hit (`browser_evidence.ex:60-62`). | closed |
| T-154-15 | Tampering | demo state during keyboard sweep | medium | mitigate | Tab and Escape only (`admin_route_proof.mjs:464,471`). | closed |
| T-154-16 | Repudiation | admin copy changes | low | mitigate | No copy changed under `lib/`; `vocabulary_contract_test.exs` ran in the admin suite. | closed |
| T-154-17 | Information Disclosure | final images, 154-BROWSER-EVIDENCE.md | high | mitigate | Harness denylist: 0 hits over 103 page loads (FINAL-CAPTURES). Eye review Pass on all 30 desktop rows. `scanSensitive` over the 681-row evidence doc: 0 hits. Images stay in ignored `tmp/`. | closed |
| T-154-18 | Information Disclosure | /admin/keys/:id and rotate pages | high | mitigate | No `BEGIN … PRIVATE KEY` match in phase docs or non-image capture output. Rotate pages captured in confirmation state only, nothing submitted. | closed |
| T-154-19 | Repudiation | stale captures | medium | mitigate | FINAL-CAPTURES records source SHA d3b2fec2, the freeze check, `source-sha256.json`, the 23:40:30Z restart, and stale captures moved to `final-prefix-stale/`. | closed |
| T-154-20 | Tampering | demo state | medium | mitigate | Navigate-only harness; no confirm control pressed. | closed |
| T-154-21 | Elevation of Privilege | protocol/security defaults | high | mitigate | `git diff --stat ef6043ec HEAD -- lib/lockspire/{protocol,storage,security,domain} mix.exs mix.lock` is empty; the e67a4898 diff matches the PR #123 allowlist exactly. | closed |
| T-154-SC | Tampering | npm/hex package installs | high | mitigate | No `package.json`; `mix.exs`, `mix.lock` and `.github` unchanged since ef6043ec. Since e67a4898 only the PR #123 bandit removal and one copy string changed (allowlist g1-g3 in 154-SAFE-GATE.md). | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

*Accepted risks do not resurface in future audit runs.*

---

## Auditor Notes (non-blocking)

- `154-BROWSER-EVIDENCE.md` was validated by `BrowserEvidence.parse!/1` once; no test pins it. The auditor re-ran the denylist over it with 0 hits.
- `scanSensitive` flags the phrase "copy-once secret" in prose in 154-FINAL-CAPTURES.md and 154-SAFE-GATE.md. These describe the invariant, not secret values; watch for it if those docs are ever pinned by a test.
- `html_assertions.ex` now also accepts controls wrapped in a `<label>`. This is an accessibility check relaxation in a test helper, not a security control.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-15 | 22 | 22 | 0 | gsd-security-auditor (ASVS L1 grep-depth, block_on high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-15

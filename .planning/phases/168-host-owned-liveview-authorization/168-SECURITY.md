---
phase: "168"
slug: "host-owned-liveview-authorization"
status: verified
threats_open: 0
threats_total: 15
threats_closed: 15
asvs_level: 1
created: "2026-10-22"
---

# Phase 168 — Security

Independent gsd-security-auditor verified the plan-authored register and remediation at source `93b555804a1a11ba08116cd44f8dc020abbd4ea9`, audited HEAD `ee58e3ffdf3f305cc1b9e1be4f1a8671ed700a11`. All 15 unique planned threats are closed; shared T-168-SC is counted once. ASVS L1, blocking threshold high. No risks were accepted.

## Trust Boundaries

| Boundary | Control |
|----------|---------|
| Host session references to current authority | Host-owned current binding, identity existence and permission checks, fail-closed unavailable authority |
| HTTP/disconnected/connected entry to admin callbacks | Required pipeline and ordered host hooks halt before protected rendering/actions |
| Original signed response to new connected join | Current host authority resolved again without a new GET |
| Public/consent and admin destinations/patches | Distinct sessions, protected route inventory and host params hook before destination work |
| Runtime checks to reported evidence | Source-bound commands, current CI selector inspection and explicit transport limits |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|-----------|----------|-----------|----------|-------------|---------------------|--------|
| T-168-01 | Spoofing / Elevation of privilege | Current host authority | high | mitigate | admin_route_host.ex:153,344,385; integration:1205, poisoned authority and fail-closed store | closed |
| T-168-02 | Information disclosure / Elevation of privilege | Entry hook ordering | high | mitigate | host:200; integration:218,271,293,325, actual connected and independent probe denials | closed |
| T-168-03 | Tampering | Required wiring | high | mitigate | admin_routes.ex:126,141,151; compile test:63,103, absent/empty and ordered hook controls | closed |
| T-168-04 | Tampering / Denial of service | Fixture isolation | medium | mitigate | host:283,328; integration:1447; separation:445, supervised authority and restoration | closed |
| T-168-05 | Repudiation | Entry provenance | medium | mitigate | host:201,363; VALIDATION runtime ledger and case-correlated observations | closed |
| T-168-06 | Spoofing / Elevation of privilege | Cached new join authority | high | mitigate | integration:608,695, retained response/distinct PID/four independent invalidations/no new HTTP | closed |
| T-168-07 | Information disclosure | Refused rejoin side effects | high | mitigate | Remediated integration:167,214,668,689,752,782: before/after client snapshots around refused cached joins with callback halt evidence | closed |
| T-168-08 | Repudiation | Rejoin provenance | medium | mitigate | integration:627,641,736,769,1392: fresh correlated observations and no HTTP/session callback | closed |
| T-168-09 | Denial of service | Test process cleanup | low | mitigate | integration:1363,1447; LiveView channels under ExUnit supervisor, monitored termination | closed |
| T-168-10 | Elevation of privilege | Cross-session transition | high | mitigate | host:13,31; separation:231, connected sources/error redirect/explicit fresh protected entry | closed |
| T-168-11 | Tampering / Elevation of privilege | Destination metadata | high | mitigate | inventory:6,62,91,110, independent 29-route inventory with exact protected metadata | closed |
| T-168-12 | Elevation of privilege / Information disclosure | Navigation and patches | high | mitigate | host:216,247; integration:863,893,1011, current-policy params guard and actual navigation/patch controls | closed |
| T-168-13 | Denial of service | Public/consent availability | medium | mitigate | separation:155,204,231, anonymous protocol and independent consent success/provenance | closed |
| T-168-14 | Repudiation | Evidence/CI claims | medium | mitigate | Remediated integration:1122 policy/rotation withdrawn clicks; VALIDATION CI account matches workflow:164 and run_test_matrix.sh:124 | closed |
| T-168-SC | Tampering | Dependency installation | high | mitigate | No production, dependency, lockfile or package-install changes | closed |

Shorthand: host is `test/support/lockspire/web/admin_route_host.ex`; integration is `test/lockspire/web/live/admin/admin_route_integration_test.exs`; separation, inventory and compile tests are under `test/lockspire/web`; admin_routes.ex is under `lib/lockspire/web`. References name the auditor-inspected remediation source.

## Accepted Risks Log

No accepted risks. Browser/socket transport, packaged adoption and exact-floor runtime proof remain Phase 170; generator/demo/guidance convergence remains Phase 169. These ownership boundaries do not waive any Phase 168 mitigation. Existing Phase 167 closures are preserved.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-22 | 15 | 13 | 2 (1 high, 1 medium) | Independent auditor at 45c1b36d: missing rejoin state comparison and evidence overclaims |
| 2026-10-22 | 15 | 15 | 0 | Independent recheck at ee58e3f after 93b5558 test repair |

Fresh remediation verification: 6 targeted checks, 44 focused tests and 1,976 broad checks passed; 6 skipped, 497 excluded. Format and both diff checks passed. The auditor independently inspected source and evidence and did not rerun tests. Local LiveViewTest lifecycle checks are not browser/socket recovery or remote CI proof.

## Sign-Off

- [x] Every threat has a mitigation disposition and inspected evidence.
- [x] No risk accepted by inference.
- [x] threats_open is zero; all 15 planned threats closed.
- [x] Status verified at ASVS L1.

**Verification:** 2026-10-22, independent security auditor.

## Final Source Freshness Check

At `50035272236cd84ce9adc381bef0393f431ee5b7`, the auditor independently inspected WR-01's final delta. The no-store HTTP fallback now calls Identity.resolve/1 (fixture:163), which permits only staff-1 (fixture:400); unknown/deleted/missing/empty controls at integration:1205 receive 403 before callbacks and protected output. Mutable authority checks, the params guard, and the other fourteen mitigations are unchanged. All 15 threats remain closed, threats_open: 0. No source change occurred during this audit.

Final source verification: 45 focused tests and 1,977 broad checks passed (6 skipped, 497 excluded), with compile, format and complete phase diff checks green. This supersedes earlier source/count attribution for current evidence; earlier audit rows remain historical.

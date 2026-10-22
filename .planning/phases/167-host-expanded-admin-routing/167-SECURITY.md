---
phase: "167"
slug: "host-expanded-admin-routing"
status: verified
threats_open: 0
threats_total: 12
threats_closed: 12
asvs_level: 1
created: "2026-10-22"
---

# Phase 167 — Security

Independent gsd-security-auditor reviewed the plan-authored register at `a45dc1ee`, ASVS L1, block threshold high. All 12 unique planned threats are mitigated and closed; reserved T-167-SC is counted once.

## Trust Boundaries

| Boundary | Control |
|----------|---------|
| Host declaration to native router/session | Literal/path/option validation, required host pipelines and ordered hooks, fixed native session |
| HTTP or LiveView entry to admin | Host current-identity decision precedes admin mount; mount configuration alignment is enforced |
| Admin to public protocol and host consent | Ordered host routing, separate native sessions and callback provenance |
| Evidence to logs/operator output | Controlled path errors and bounded redacted fixture observations |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|-----------|----------|-----------|----------|-------------|---------------------|--------|
| T-167-01 | Elevation of privilege | Required host authorization wiring | high | mitigate | admin_routes.ex:77,100,126; admin_route_integration_test.exs:178 explicitly tests disconnected/connected socket state, missing/deleted identity, halt and host redirect before mount sentinel | closed |
| T-167-02 | Tampering | Path and mount alignment | high | mitigate | admin_routes.ex:95,225,246; admin_mount.ex:9,20,45 validate path and guard both entry points | closed |
| T-167-03 | Spoofing | Native session/options/hooks | high | mitigate | admin_routes.ex:80,102,163; admin_routes_compile_test.exs:129,162,180; native duplicate/nesting rules | closed |
| T-167-04 | Information disclosure | Configuration/entry errors | medium | mitigate | admin_mount.ex:20,49 ignores session payload; config.ex:125 and config_test.exs:54 reject malformed values safely | closed |
| T-167-05 | Elevation of privilege | Prefixed action/navigation paths | high | mitigate | admin_route_integration_test.exs:357,430,515,574 covers connected route matrix, navigation, recovery and root variants | closed |
| T-167-06 | Spoofing | Fresh join lifecycle | high | mitigate | admin_route_integration_test.exs:359 checks distinct process, reused session and host hooks; admin_route_host.ex:476 retains native transport/session configuration | closed |
| T-167-07 | Tampering | Test isolation/concurrent views | medium | mitigate | admin_route_integration_test.exs:258,340,536 serializes/restores config and checks independent views under stable mount | closed |
| T-167-08 | Information disclosure | Lifecycle evidence | medium | mitigate | admin_route_host.ex:48,189,203 uses disposable records and bounded observer data | closed |
| T-167-09 | Tampering | Route/action inventory | high | mitigate | admin_route_inventory_test.exs:6,52,62,91 independently fences original ordered 29 tuples and selected action/hooks/pipelines | closed |
| T-167-10 | Elevation of privilege | Forward precedence | high | mitigate | admin_route_separation_test.exs:98,141 proves admin precedence and independent anonymous public access | closed |
| T-167-11 | Spoofing | Consent/admin session boundary | high | mitigate | admin_route_host.ex:17; admin_route_separation_test.exs:190,217 checks distinct consent session and connected/concurrent callback isolation | closed |
| T-167-SC | Tampering | Dependency installation | high | mitigate | mix.exs and mix.lock unchanged from phase base; no package installation introduced | closed |

Source shorthand: implementation paths are under lib/lockspire or lib/lockspire/web; tests under test/lockspire/web (lifecycle file under live/admin), fixture under test/support/lockspire/web. Line references are the auditor's inspected `a45dc1ee` source.

## Accepted Risks Log

No accepted risks. The complete host-authorization denial matrix remains Phase 168 scope, installation/upgrade convergence Phase 169, and browser transport/package/exact-floor proof Phase 170. These are ownership boundaries, not waived Phase 167 mitigations.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-22 | 12 | 11 | 1 | Independent auditor at 8104bdb9: connected-denial evidence gap |
| 2026-10-22 | 12 | 12 | 0 | Independent re-audit at a45dc1ee after test-only repair |

The repair's direct socket assertions prove callback behavior for both connection states; they do not prove real transport behavior. The integration file passed 13 tests after the repair. No production code changed after the 1961-check final broad suite.

## Sign-Off

- [x] Every threat has a mitigation disposition and inspected evidence.
- [x] No risks accepted by inference.
- [x] threats_open is zero.
- [x] Status verified at ASVS L1.

**Verification:** 2026-10-22, independent security auditor.

## Security Audit 2026-10-22

| Metric | Count |
|---|---|
| Threats found | 12 |
| Closed | 12 |
| Open | 0 |

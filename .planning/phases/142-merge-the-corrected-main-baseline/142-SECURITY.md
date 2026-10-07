---
phase: "142"
slug: "merge-the-corrected-main-baseline"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 142 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Reviewed PR to `main` | GitHub PR policy and the maintainer authorization determine which exact source can merge. | PR URL, reviewed head SHA, reviews, required check conclusions |
| CI and hygiene evidence to source acceptance | The maintained helper binds local and hosted results to the current full source SHA. | Commit SHA, workflow identity, seven job results, hygiene counts, private receipt |
| `main` to protected package publication | Phase 143 owns the protected publish path and must recheck authorization and current main. | Current-main SHA, closed authorization variables, environment approval, package artifact |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-142-01 | Tampering | Release-train link | medium | mitigate | Focused ExUnit contract checks local destinations in the maintained ledger; the contributor gate passed. See 142-01 summary. | closed |
| T-142-02 | Spoofing | PR source head | high | mitigate | The final correction PR #113 was reviewed at full head `084e2849a584c5d287add7693e41af37d7abd5d9`; its squash result is `6f1a19b39999f96eb24352c75c2a0628375175ae`. See the post-plan continuation in 142-02 and 142-03 summaries. | closed |
| T-142-03 | Elevation of privilege | Release Please auto-merge and dispatch | high | mitigate | Complete paginated PR and active-run inventories found no pre-readiness publication path; auto-merge remained disabled and protected publication gates stayed closed. See 142-02 and 142-04 summaries. | closed |
| T-142-04 | Spoofing | PR review identity | high | mitigate | The user's conditional authorization named PR #113 and its exact reviewed head `084e2849a584c5d287add7693e41af37d7abd5d9`. The repository's zero-approval policy and separate human authorization are recorded; no independent review is claimed. See the post-plan continuation in 142-02. | closed |
| T-142-05 | Spoofing / Tampering | Approved PR and main SHA | high | mitigate | The authorized PR #113 head and live controls were rechecked before merge; exact-source acceptance required synchronized `HEAD`, local `main`, and refreshed `origin/main` at `6f1a19b39999f96eb24352c75c2a0628375175ae`. | closed |
| T-142-06 | Spoofing | Canonical CI evidence | high | mitigate | The maintained helper accepted canonical push CI run 37617422181 on the exact merge SHA with all seven required jobs successful. | closed |
| T-142-07 | Tampering / Repudiation | Hygiene and result record | high | mitigate | The helper receipt records local `mix ci`, 24 PASS, 0 WARN, 0 BLOCK, successful Release no-publish and the accepted SHA. `142-RESULT.md` separates source SHA from the result commit. | closed |
| T-142-08 | Elevation of privilege | Publication boundary | high | mitigate | No dispatch, tag, or package publication occurred. Release run 37617422018 ended `no_publish`, with protected publish jobs skipped; Phase 143 owns publication. | closed |
| T-142-09 | Elevation of privilege | Old Release Please chain | high | mitigate | Release Please auto-merge was disabled; `hex-publish` stayed main-only with its configured reviewer, and the live run census was empty before merge. See 142-04 and 142-02 summaries. | closed |
| T-142-10 | Tampering | Phase 143 authorization variable | high | mitigate | PR #113 (`084e2849a584c5d287add7693e41af37d7abd5d9`) was squash-merged as `6f1a19b39999f96eb24352c75c2a0628375175ae`. The protected publish job creates a temporary active repository ruleset for only `refs/heads/main`, with no bypass actors and an update-blocking rule; it verifies the ruleset and GitHub's effective main rules. The wrapper repeats those read-backs and checks fetched main, hosted main, the Phase 143 authorization, recovery ref, and verified SHA immediately before invoking the Hex publisher. It withholds the Hex key during GitHub checks and unsets the GitHub token before upload; the `always()` cleanup attempts removal and verifies that the freeze is gone. PR CI passed, and the post-merge Release run completed with all publication jobs skipped. See CR-01 resolution in PR #113. | closed |
| T-142-11 | Spoofing | Required CI contexts | high | mitigate | Live main protection required a PR and all seven strict canonical CI contexts. PR #113 had all seven checks green at its exact reviewed head before merge, and canonical CI passed all seven jobs on the squash SHA. | closed |
| T-142-12 | Denial of service | Archived-phase router root detection | medium | mitigate | The portable router suite passed with 21 tests, 2 skipped, and 0 failures while preserving rejection and child failure behavior. See 142-04 summary. | closed |
| T-142-SC | Tampering | Package installs | high | mitigate | No npm, pip, or cargo installation was introduced by this phase; package legitimacy remains a stop condition if a future execution adds one. Declared in Plans 01–04. | closed |

*Status: verified — all 13 unique planned threats are closed. Repeated T-142-SC entries across plans are consolidated above.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 13 | 13 | 0 | GSD security auditor, ASVS level 1 |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-07 — CR-01 is mitigated by the enforced temporary main freeze and exact-SHA preflight in merged PR #113. If freeze creation succeeds but GitHub returns no usable ruleset ID, the workflow fails closed and may require manual administrator cleanup; this is an operational availability edge, not an authorization bypass. No release was dispatched and no package was published.

## Security Audit 2026-10-07

| Metric | Count |
|---|---|
| Threats found | 13 |
| Closed | 13 |
| Open | 0 |

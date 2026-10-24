# Verification policy

User direction, reaffirmed 2026-10-22 during `$gsd-verify-work 167`: shift verification left, reduce toil, and aim for zero human UAT. This applies by default to future discussion, planning, execution, verification and CI work.

- Map acceptance criteria and prohibitions to existing executable checks before proposing new tests or a human checkpoint. Run focused unit, integration, seam, smoke or end-to-end checks as early as practical; select the smallest set that proves the behavior.
- Add missing regression checks when they provide recurring value. Use existing CI selectors where they already cover the checks; add CI work only when its recurring value warrants the setup and runtime. Local evidence does not imply a remote CI run passed.
- The agent may classify routine checks and review source, architecture and evidence claims. Missing verification descriptors are a planning defect to resolve with an explicit closure rule and evidence, not an inherently human decision. Do not substitute an LLM opinion for missing behavioral proof.
- Keep evidence types precise: compiled routing, direct callbacks, connected LiveViewTest lifecycle, actual browser/socket transport, packaged adoption and exact dependency runtime tests establish different properties. Report the exact tested scope. Give untested work an explicit phase owner; do not silently mark it proven.
- Hand off only checks that actually require human judgment, unavailable private access, physical observation or an explicitly reserved decision. State exactly why automation cannot establish that particular fact. Do not ask for confirmation of facts already established by suitable evidence.
- Record each resolved checkpoint with its criterion, method, result, source revision and limits. Reuse that resolution while its evidence remains valid. Reopen only for a relevant source/acceptance change, a regression or new evidence of a missing property; identify the trigger. Never reopen merely because the old plan or initial report contained a manual flag.
- Keep consequential external action approval separate from verification. This policy neither authorizes publication/ref updates nor waives security, failed tests, stale covered-source checks or unresolved product decisions.

## Phase 167 closure precedent

The original two checkpoints were descriptor-less host-ownership and evidence-boundary records. They are resolved in [167-UAT.md](phases/167-host-expanded-admin-routing/167-UAT.md) by fresh tests and a delegated source/evidence audit, not by an assumed user pass. The initial report and plans retain their historical observations; the UAT closure ledger records their disposition. No product behavior changed during this verification pass.

Existing compile, inventory, separation, integration, configuration and compatibility tests supply the recurring regression checks and are already selected by CI. No duplicate CI job or prose-matching test is needed. Phase 168 still owns the full authorization denial matrix; 169 owns adoption convergence; 170 owns packaged/browser/exact-floor runtime and CI proof. Those future requirements are not Phase 167 UAT blockers.

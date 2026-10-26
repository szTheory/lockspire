# Phase 178: Packaged Upgrade Proof & Delivery Handoff - Context

**Gathered:** 2026-10-26 (assumptions mode)
**Status:** Ready for planning
**Authority:** Owner requested subagent research, adversarial tradeoff analysis and automatic adoption of a coherent scoped recommendation bundle after the initial assumptions were presented. This captures delegated recommendations, not fabricated individual confirmations or runtime results.

<domain>
## Phase Boundary

Prove the selected verifier adoption, upgrade, mixed-version/key, activation, rotation, rejection and recovery journeys through package-installed Phoenix hosts; complete focused reviews, contributor/CI gates and the milestone audit; leave an exact delivery/main-acceptance and resource-custody handoff. Own VPROOF-02, VDELIV-01 and VDELIV-02. Phases 175–177 establish the approved behavior and source evidence. This discussion selects no new protocol, credential-age policy, schema, runtime dependency, arbitrary-store support, UI project or publication.
</domain>

<decisions>
## Implementation Decisions

### Finite package matrix and actual upgrade inputs
- **D-01:** Use the stable Phase 175 case IDs and acceptance contract. Preserve the Phase 176/177 exhaustive source owners and their exact tested identities; add actual installed-package evidence for the remaining adoption/composition boundaries. Source proof alone is insufficient, and an unrestricted product of every endpoint, parser failure, prefix, key and deployment stage is unnecessary. Missing required package cases are failures/blockers, never passing skips.
- **D-02:** Run the core fresh, legacy-upgrade, activation, key-rotation/rejection and recovery journeys in four cells: exact locked Phoenix 1.8.13 / LiveView 1.2.10 and exact floor Phoenix 1.8.5 / LiveView 1.1.28, each with built-in storage and the declared shared-PostgreSQL delegating client/transaction composition. Use shared scenario definitions and record actual host dependency locks/resolution plus Elixir/OTP/PostgreSQL identity. Keep the existing locked/floor CI runtime partitions; no floor upgrade is selected.
- **D-03:** Use accepted pre-verifier main `173059a166e9ade0f5f57c9980b7b2400a98538c` as the exact installed old-code predecessor for the bounded mixed-version journey. Separately execute a checksum-pinned public 1.6.1 legacy-producer/adopter control on the locked pair using the established prerequisite lifetime-upgrade path. Label its narrower environment/coverage and source identity independently; do not imply a complete public-release upgrade matrix from that control. Verify the existing pinned checksum/artifact before use. The lifetime-schema upgrade runner is precedent/prerequisite, not verifier-upgrade acceptance.
- **D-04:** Prove real old/new host processes reading/writing the same run-owned store while compatible readers retain legacy writes. Observe actual persisted writes and old/new read controls. Drain the old process before dedicated activation; then prove dedicated writes/reads, compatible-reader rollback and that switching writes back does not convert existing dedicated rows. Use an isolated negative control to demonstrate old-code rejection of dedicated material. Local processes do not prove host fleet parity, drain/quiescence, backup quality or rollback safety.
- **D-05:** Prove dedicated authentication over real mounted HTTP on the five existing JWT client-authentication endpoints (token, introspection, revocation, device authorization and CIBA), with fresh assertions/JTIs and the existing HS256/issuer-audience/replay/lifecycle rules. Preserve PAR rejection and FAPI exclusions, plus unaffected Basic/post controls. Exercise endpoint breadth once per dependency pair; do not repeat every endpoint at every transition or remove existing device/CIBA support.

### Harness shape, provenance and consumer boundaries
- **D-06:** Reuse package construction/binding, host preparation, process/DB ownership, redaction and strict-receipt helpers. Prefer a bounded verifier scenario group; a thin sibling runner sharing those helpers is appropriate if lifetime/admin coupling obscures the journey. Decouple generic dependency-pair selection from `admin_proof`; do not enable unrelated admin behavior to obtain floor dependencies. No cloned acceptance framework or new dependency.
- **D-07:** Record runner SHA separately from each artifact's proven source. Bind candidate and predecessor archive/tree, installed vendor tree, resolved dependency, compiled identity and host lock. `prepare_package` currently attributes the checkout SHA to external tar/Hex inputs: correct that attribution before relying on it. An old artifact's unknown source remains unknown unless independently established; a candidate requires a trustworthy source-to-artifact binding. A caller-supplied source string alone is insufficient. Preserve original receipt bytes and failed attempts.
- **D-08:** Extend the clean-room delegated store and its boundary allowlist narrowly with the existing maintenance behavior, inventory and compare-and-rewrap capabilities. Preserve selected client/transaction/audit participant agreement and callback witnesses. Prove unsupported/mismatched authority fails before inventory/fetch/write. Use ordinary host-owned modules and documented seams; never import checkout `test/support`, Lockspire's test Repo or a private production debug API into the installed host.
- **D-09:** Exercise installed `--dry-run`, apply and separate fresh `--check` commands, including partial/non-ready failure outcomes. Include one actual assembled running-release RPC smoke on the locked pair for the documented Mix-free API; distinguish its startup snapshot from bare Mix task-local configuration and unbooted `eval`. Fixture/control channels may prepare synthetic state and return allowlisted projections; public authentication outcomes must remain real HTTP observations.

### PostgreSQL, preservation and disclosure proof
- **D-10:** Execute selected contention/fault scenarios on both dependency pairs through the configured delegating composition, which uses the built-in PostgreSQL repository underneath. Use committed fixtures, independently checked-out connections, explicit barriers, distinct backend PIDs and the exact observed `pg_blocking_pids(contender)` relation before releasing the blocker. Cover rotation-first stale-maintenance conflict and maintenance-first coherent rotation; inspect authoritative rows after lock waits. Shared sandbox ownership or sleep-only assertions are insufficient.
- **D-11:** Prove actual valid audit INSERT failure with a reached-boundary witness (for example, the existing run-owned trigger/sequence pattern), unchanged ciphertext and absent committed audit. Invalid audit metadata now fails before mutation and is not equivalent. Also prove provisional low-level replacement followed by caller-owned outer rollback, and that the reporting API rejects an already-open transaction. Success reports/events must follow the selected outer commit. Compare sensitive rows in memory and emit safe booleans only.
- **D-12:** Prove unchanged hash/partner secret, lifetime version/deadlines, management material, metadata, last-secret-rotation time and inserted/updated timestamps through custody rewrap; only verifier ciphertext changes with its atomic audit. Cover repeat idempotence, partial progress/retry and fresh nil-cursor reconciliation. A wrapper that commits then simulates an unavailable response proves indeterminate-result handling, not real network-fault injection; label it accordingly. Do not claim rollback merely because the caller received an error.
- **D-13:** Reproduce maintenance after JWT authentication/JTI consumption and before the current-row issuance guard using a host adapter barrier and separate PostgreSQL connection. Require fail-closed stale identity, no successful issuance/grant side effects, same-JTI replay rejection and fresh-JTI retry success. Keep the ciphertext-sensitive fingerprint; no replay reset or hidden same-assertion retry.
- **D-14:** Preserve the approved native/configured-lifetime policy and authenticated migrated original finite deadline during package journeys. Expired migrated dedicated material may undergo custody-only rewrap but must remain ineligible to authenticate. Missing-key restoration preserves the partner secret; existing authorized secret rotation/reprovision replaces it through the one-time handoff. No age reset, hash reconstruction, automatic replacement or endpoint/signing custody changes.
- **D-15:** Register verifier plaintext, encryption-key bytes and ciphertext sentinels before child output/artifact processing. Capture representative installed success and forced crypto/storage failure across owned Logger, raw query telemetry, reports/CLI, audit and HTTP responses, while retaining exhaustive exact-source disclosure coverage. Preserve authorized explicit-secret transport and redact nested inspection. Host custom instrumentation and PostgreSQL server logging remain host-owned boundaries; do not silently change global logging policy.

### Evidence freshness, review and delivery
- **D-16:** Settle shipped source, proof harness, guidance and acceptance inputs before final expensive runs. Freeze a bounded input manifest and preserve source/package/candidate identities. Changed covered bytes require affected proof refresh; later evidence-only/GSD metadata requires explicit applicability reconciliation, not blanket reruns or relabeling old execution at a new SHA. Reassess affected prior verification owners without rewriting immutable historical observations or the frozen ledger.
- **D-17:** Complete focused security, source and integration review, all 18 requirement dispositions, canonical milestone audit, full local `mix ci` and the existing seven required hosted CI jobs. Bind evidence to exact candidate and executed checkout, workflow/event/run/attempt and complete job graph; preserve failed attempts. Local results do not prove hosted results. Do not assemble a green graph from incompatible attempts or waive actual behavior/gate gaps because document structure validates.
- **D-18:** Preserve GitHub PR CI's actual synthetic merge checkout identity separately from the reviewed head and package source. Record parents and tree/covered-input relationships when reconciling artifacts. Do not change checkout policy merely to simplify provenance or claim that a manually dispatched check automatically satisfies branch protection.
- **D-19:** Avoid a lifecycle cycle: pre-merge phase verification/milestone audit assesses implemented package outcomes and a truthful delivery handoff whose integration/main acceptance may be explicitly pending/blocked under roadmap criterion 4. Required package/security/candidate gaps still block their claims. After normal reviewed integration, append a dated acceptance/audit addendum. A pending integration handoff is not accepted main and cannot authorize the next milestone's implementation. Preserve actual merge/review authorization requirements; this research delegation is not exact-head merge approval.
- **D-20:** Use the single v1.48 milestone PR and existing exact-main helper after integration. Require synchronized `HEAD == local main == refreshed origin/main`, full contributor checks, matching canonical push-CI and no-publish Release graph, and dispositions for warnings actually emitted. Preserve stdout bytes plus command, exit, observation time, digest and final checkout status separately. Retain the original Phase 175 entry receipt unchanged; it cannot accept the integrated milestone.
- **D-21:** Align fresh-install/generator, upgrade, maintenance, diagnostics and support guidance with observed behavior and executable commands. Current supported-surface/release contracts and workflows override aspirational prompt guidance, including older tag-publish recommendations. No new admin surface is selected; any necessary UI wording still follows `PRODUCT.md` and current `brandbook/`, including retired wording. Keep maintainer evidence details out of adopter flows unless needed to make an operational decision.
- **D-22:** Record dated resource custody: identity, custodian or unknown original owner, purpose, unique-work disposition, retention/cleanup trigger, blocker and next action. Clean only exact run-owned ephemeral resources when safe; preserve unknown edits/history/worktrees/databases/demo data and immutable receipts. Refresh the rolling ranking using actual outcomes; UI quality remains next with completed Q1–Q10/final confirmation intact. OPS-03/KEK-04/token work retain evidence triggers. Publication stays separate under Release Please/protected exact-ref release controls.
- **D-23:** Retain Phase 177 E-09/E-10 and descriptorless non-authoritative prohibition flags with their original status/provenance, plus any other actual prior flags relevant to final review. Do not fabricate human review, suppress unresolved flags or relabel structural/judgment checks as runtime proof. Concrete behavioral gaps remain blocking independently of advisory lifecycle bookkeeping.

### Agent's Discretion
- Choose runner/module/receipt filenames, exact scenario grouping and bounded fixture/control plumbing within these decisions. Favor small auditable glue and existing Elixir/OTP/Plug/Ecto/Phoenix facilities.
- Resolve routine matrix deduplication, harness factoring and review/gate ordering without another preference interview. Escalate only a demonstrated security/public API/support/scope conflict or a genuinely required consequential-action authorization.
- Further research should target concrete unresolved compatibility/proof questions; three independent scoped analyses have reached diminishing returns for generic comparisons. Implementation and actual execution must settle remaining evidence.

### Folded Todos
None; todo matching returned zero pending todos.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, policy and lifecycle
- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/MILESTONE-GUIDE.txt`
- `.planning/MILESTONE-ARC.md`
- `.planning/DEVELOPMENT-TRAIN.md`
- `.planning/RELEASE-TRAIN.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTRACT.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.json`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-BASELINE.json`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CUSTODY.md`
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-CONTEXT.md`
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-VERIFICATION.md`
- `.planning/phases/177-safe-verifier-maintenance-recovery/177-CONTEXT.md`
- `.planning/phases/177-safe-verifier-maintenance-recovery/177-COMPLETION.md`
- `.planning/phases/177-safe-verifier-maintenance-recovery/177-SOURCE-ACCEPTANCE.json`
- `.planning/phases/177-safe-verifier-maintenance-recovery/177-VERIFICATION.md`
- `.planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY.md`
- `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-CONTEXT.md`
- `.planning/research/ui-quality-engine/MILESTONE-PROPOSAL.md`

### Package, storage and delivery seams
- `scripts/acceptance/clean_room/package_input.py`
- `scripts/acceptance/clean_room/build_provider.py`
- `scripts/acceptance/clean_room/selected_receipts.py`
- `scripts/acceptance/clean_room/client_lifetime_upgrade.py`
- `scripts/acceptance/clean_room/redaction.py`
- `scripts/acceptance/clean_room_saas_journey.py`
- `test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex`
- `lib/lockspire/admin/client_verifier_maintenance.ex`
- `lib/lockspire/storage/client_verifier_maintenance.ex`
- `lib/mix/tasks/lockspire.clients.verifier.rewrap.ex`
- `test/support/client_verifier_maintenance_concurrency.ex`
- `scripts/maintainer/repo_hygiene_check.sh`
- `.github/workflows/ci.yml`
- `docs/client-secret-verifier-configuration.md`
- `docs/client-secret-jwt-host-guide.md`
- `docs/supported-surface.md`
- `docs/maintainer-release.md`

### Relevant prompt guidance
- `prompts/README.md`
- `prompts/lockspire-elixir-oss-library-practices.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-ecto-token-and-audit-model.md`
- `prompts/lockspire-security-posture-and-threat-model.md`
- `prompts/lockspire-telemetry-audit-and-introspection.md`
- `prompts/lockspire-release-engineering-and-ci.md`
- `prompts/lockspire-release-readiness-and-conformance.md`
- `PRODUCT.md` and `brandbook/README.md` only for applicable operator wording; no visual redesign is selected.

### Primary-source rationale
- [Elixir library guidelines](https://elixir.hexdocs.pm/library-guidelines.html) — consumer dependency resolution and narrow library responsibilities.
- [Hex package build](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html) — local archive construction is separate from publication.
- [Mix 1.19.5 releases](https://mix.hexdocs.pm/1.19.5/Mix.Tasks.Release.html) — actual running-node RPC versus eval.
- [PostgreSQL 14 isolation](https://www.postgresql.org/docs/14/transaction-iso.html) and [blocking functions](https://www.postgresql.org/docs/14/functions-info.html) — current-row authority and observed contention.
- [Ecto Repo transaction API](https://hexdocs.pm/ecto/3.13.5/Ecto.Repo.html#transact/2) and [Ecto SQL 3.13.5 source](https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql.ex) — commit and independent telemetry/logging boundaries.
- [Fernet timestamp-preserving rotation](https://cryptography.io/en/46.0.3/fernet/) and [Vault transit rewrap](https://developer.hashicorp.com/vault/api-docs/secret/transit#rewrap-data) — custody/authority distinction, with no dependency adoption.
- [Keycloak update compatibility](https://www.keycloak.org/server/update-compatibility) — explicit version/configuration transition limits, not evidence of Lockspire fleet safety.
- [GitHub workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [workflow jobs API](https://docs.github.com/en/rest/actions/workflow-jobs) and [merge API](https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request) — checkout/run/head identity and protected integration.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Package helpers already bind archive, extracted/vendor tree, resolved dependency and compiled candidate, and own disposable host resources. Extend attribution to distinguish runner and external artifact source.
- Existing selected receipts provide strict fields, scenario/count reconciliation and cleanup/redaction checks; use the pattern without copying an entire framework.
- Phase 177's independently checked-out PostgreSQL barrier harness and reached-audit-INSERT trigger/sequence witness provide source precedents. Recreate minimal host-owned fixtures through package seams; checkout test support cannot be loaded into consumers.
- The Mix-free maintenance API and thin rewrap task already implement the operator workflow; the package journey must exercise them.

### Established Patterns
- Dependency-pair selection is currently gated by admin proof. The existing lifetime upgrade runner requires the older lifetime expansion and cannot be renamed into verifier proof.
- The clean-room delegated adapter has lifetime/client/transaction callbacks but lacks maintenance capability/inventory/CAS and boundary-allowlist entries.
- Sensitive repository options suppress both SQL logging and raw query telemetry. Schema Inspect and `log: false` alone cannot replace that seam.
- Audit validation happens before mutation; a rejected metadata case cannot prove transaction rollback after an actual audit INSERT.
- PR workflow execution may use a synthetic merge checkout; local candidate, package source, PR head and synchronized main are distinct identities.

### Integration Points
- Add finite verifier acceptance around package-clean provider preparation, documented installer/configuration/Mix/API/RPC seams and mounted HTTP.
- Attach host-owned adapter callback/barrier witnesses to selected authoritative client/transaction/audit storage, preserving the frozen support boundary.
- Feed immutable package/candidate receipts into final reviews and the existing milestone/main train; leave publication controls closed.
</code_context>

<specifics>
## Specific Ideas

- Three owner-authorized independent analyses covered package/adopter DX, storage/security/concurrency and delivery/CI/release integrity. They compared reuse-only, broad Cartesian proof and bounded installed journeys; the bounded layered approach is selected.
- Methodology applied: assumption-first/research-first defaults, least-surprise host seams, high-threshold escalation and one-shot bundles. The material findings were external-artifact misattribution, wrong legacy-runner reuse, incomplete package adapter, false rollback witnesses and a pre/post-merge acceptance cycle.
- Stakeholder jobs are concrete: adopter installs/upgrades; operator previews/rewraps/checks/restores; reviewer assesses source-bound transaction/security evidence; maintainer delivers and hands off safely. No graphic-design or animation work is applicable.
- Research recommendations are decisions; no package proof, CI result, release-RPC run, audit completion or accepted-main outcome has been executed by this discussion.
</specifics>

<deferred>
## Deferred Ideas

- Package publication, manual tags/release dispatch, fleet coordination/hot reload, backup-key destruction, arbitrary-store support and a generic secrets platform.
- Full Cartesian repetition of source-only malformed-input cases, new chaos/provenance frameworks, speculative optimization/indexes and new runtime dependencies.
- UI quality implementation and Storybook remain a future milestone with the completed interview preserved; token lifecycle, OPS-03 and KEK-04 retain evidence triggers.

### Reviewed Todos (not folded)
None; no pending todo matched.
</deferred>

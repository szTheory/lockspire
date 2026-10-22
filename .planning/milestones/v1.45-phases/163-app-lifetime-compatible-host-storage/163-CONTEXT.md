# Phase 163: App Lifetime & Compatible Host Storage - Context

**Gathered:** 2026-10-20 (assumptions mode; three code research lenses and primary-source verification)
**Status:** Ready for planning
**Decision authority:** User explicitly requested delegated breadth/depth and adversarial research, coherent recommendations and automatic adoption. The decisions below follow that direction; no separate confirmation response is claimed. Phase 162's normative contract is locked.

<domain>
## Phase Boundary

Implement DCR-05, DCR-06, DCR-13 and DCR-14: persist and enforce app lifetime across the complete selected consumer inventory, compatible legacy/fresh host storage and explicit custom-adapter support. Include focused runtime, race, rollback and upgrade proof now. Phase 164 owns secret expiry and rotation; Phase 165 owns management-token expiry/recovery; Phase 166 owns complete cross-phase packaged journeys, security/CI and final guidance proof. Foundations needed by those phases belong here, but their credential requirements must not be marked complete here.
</domain>

<decisions>
## Implementation Decisions

### Eligibility and consumer coverage

- **D-01:** Use one narrow Lockspire app-eligibility decision with explicit consumer context and endpoint-owned error mapping. Keep generic storage fetches capable of returning expired/disabled rows; filtering them away hides state and breaks permitted management reads/deletes. Preserve configuration/storage failures as server errors, separate from invalid credentials.
- **D-02:** Apply current enabled-state and app-deadline checks to every applicable Phase 162 consumer, including public/private-key/mTLS clients. Authentication is a useful shared entry gate, but never the sole enforcement boundary. Deadline equality is expired; no pruning dependency or JWT skew grace.
- **D-03:** Check browser authorization before host login/consent handoff and again at resume, remembered consent and approval/code persistence. Recheck PAR use, device verification/approval, CIBA host approval and queued push issuance. Preserve validated-redirect trust, original state, existing polling/replay/grant-expiry errors, and host ownership.
- **D-04:** Online UserInfo and token exchange must inspect the current issuing app through the declared client adapter, before host claims/validation where applicable and at final durable issuance. RFC 8693 retains durable subject AND actor token identities and validates their issuing apps independently from the requester. Preserve introspection's owned-token restriction; invalid caller is 401, otherwise authorized inactive target is only active:false. Keep offline VerifyToken free of client-store lookups.
- **D-05:** Implement app-state management distinctions now: expired-enabled app permits valid-credential GET/DELETE, forbids PUT; disabled app blocks all self-management. Intake closure alone must not disable existing management. Do not conflate these app checks with finite management-token enforcement due in Phase 165, or allow this phase's foundations to revive/extend an app.

### Durable authority, clocks and token truth

- **D-06:** Final authorization/issuance operates on current locked client state and previously verified credential identity, not a client snapshot. Use stable client-ID ordering for multiple requester/subject/actor app locks, and one consistent client-before-grant/token ordering across relevant writers. Acquire all required blocking locks before capturing the final decision time; a later grant/request/token wait invalidates an earlier time sample.
- **D-07:** App rejection at code redemption must leave the code unconsumed and write no token. Current-client guards, grant consumption, token writes and atomic audits participate in one rollback authority. Apply intended mutable changes to current rows; do not restore old hashes, enabled flags or deadlines via stale whole-client replacements. This ordering foundation must be usable by later credential phases.
- **D-08:** Prefer one outer transaction with plain functions/with beneath it, retaining the existing supported transaction abstraction. Explicitly propagate errors into rollback. Ecto Repo.transaction returning {:error, reason} is not itself rollback; Repo.transact has different return semantics. Do not mechanically migrate every transaction API or swallow nested rollback errors.
- **D-09:** Preserve existing clock entry-point conventions while adapting them into explicit dependencies. Fix dropped clocks at ClientAuthentication and CIBA adaptation; avoid global clock services, per-consumer ambient callback discovery and public-option churn. Fresh time after lock waits is required; an ingress DateTime must not become permanent authority. SQL now()/CURRENT_TIMESTAMP and a waiting statement's statement_timestamp() cannot establish post-wait time.
- **D-10:** Compute effective access/refresh expiry once from the final decision time and min(ordinary deadline, finite app deadline), then derive durable expiry, access JWT exp and response expires_in from that result. Cover ordinary grants, refresh rotation, push and RFC 8693. Refuse zero-lifetime issuance at equality. Keep ID-token TTL and authorization-artifact TTL semantics selected in Phase 162.
- **D-11:** End locks before network calls, host callbacks that can perform remote work, delivery and response encoding. In particular, separate durable code/interaction transitions from JARM redirect construction, which can fetch remote JWKS. Do not solve locking by disabling supported response modes. Prepare expensive work outside locks only when current-state/fingerprint revalidation preserves the selected contract.

### Storage and legacy authority

- **D-12:** Persist lifetime_version plus nullable app/management deadlines and the existing secret deadline on the client aggregate. Migration establishes existing rows as explicit v0; constructors explicitly assign v1 to new clients. Missing/unknown domain version is invalid, never an implicit v0 fallback. Preserve historical advisory secret dates unchanged during schema expansion; only authoritative new dates use whole seconds.
- **D-13:** Keep legacy rows effectively unlimited, with no guessed deadline or policy backfill. Reads, ordinary metadata edits and enable/disable need not promote. Any existing credential-replacement path that promotes a legacy row must canonicalize unrelated historical deadlines to unlimited atomically under the current row, per Phase 162; never flip the version alone. Do not accidentally enforce historical secret dates while building app enforcement.
- **D-14:** Declare lifetime-contract version at the adapter boundary, owned by the adapter. Validate it in dependency adaptation and pass explicit typed support to consumers. Do not reuse the permissive capabilities-map default of :all as proof, or introduce a general capability framework. Exact callback/module/helper names remain planner discretion.
- **D-15:** Supported custom composition must explicitly share a transaction authority covering client current-row guards, grants/tokens and required audits. Independent backend callbacks do not prove atomicity. Reject unsupported composition/configuration with actionable host errors rather than unlimited fallback or a false credential error. No distributed coordinator or new runtime dependency.
- **D-16:** Add reusable adapter conformance fixtures that prove version/deadline round trips, current-row guarded writes, rollback and unsupported-state failure. Negative adapters must fail when omitting/unknown-declaring the contract, dropping version/deadlines, lacking guards or pretending unrelated stores share a transaction. Wire UserInfo and every relevant consumer to the declared adapter rather than a hardcoded Ecto repository.

### Host upgrade and operational proof

- **D-17:** Add one new packaged prefix-aware expansion migration through existing installer/checksum tools. Never alter shipped migration bytes or move existing host schema. Fresh generated installs and upgraded public/custom-prefix hosts must converge on equivalent lifetime storage. Use nullable deadlines and a constant v0 default; constructors still explicitly write v1.
- **D-18:** Treat additive/no-rewrite DDL as locking DDL. PostgreSQL 14 still takes ACCESS EXCLUSIVE; avoid extra scans/constraints without need. Provide a bounded operational procedure using existing tooling, explain lock acquisition/maintenance considerations and test supported shapes; do not promise a production duration or nonblocking migration.
- **D-19:** Preserve selected deploy order: expand schema while old code can run, stage the new build without serving, drain every old writer (web/admin/jobs/CLI), then cut over. Before first v1 write the old binary may use expanded schema; after authoritative writes it is not a safe protocol rollback. Retain schema/state and fix forward or use an enforcement-aware build. No activation daemon, permanent flag, mixed-version bridge or zero-downtime claim.
- **D-20:** Focused Phase 163 upgrade evidence must exercise real database expansion and pinned pre-lifetime/candidate builds in isolated processes using existing clean-room/package infrastructure where practical. A faithful legacy fixture is useful but does not alone prove old-binary compatibility. Prove representative old nil/past/future/stale dates remain unlimited, pre-v1 old read/write compatibility and preservation of v1 state/unsafe downgrade boundary. Do not run an old binary against authoritative traffic to claim safe post-v1 rollback.

### Verification, dependency discipline and scope

- **D-21:** Use deterministic injected clocks and real independent PostgreSQL sessions for races. Identify holder/contender backend PIDs and confirm the expected blocker with pg_blocking_pids before moving the clock/releasing the holder. Shared sandbox/allowed tasks reuse connections and are not independent transactions. Avoid sleeps as expiry evidence and global any-waiter counters; guarantee cleanup and bounded waits.
- **D-22:** Include before/equality/after, changed-policy/provenance, disabled-versus-expired, no-secret clients, queued/resumed work, stale preverified credential, and both client-lock AND later grant-lock waits. Assert durable artifact counts/state and rollback of failed audits/writes, not merely returned errors. Exercise opaque and signed token representations and every issuance route. Phase 166's final suite supplements these tests.
- **D-23:** Reuse OTP/Elixir/Ecto/PostgreSQL and existing test/install infrastructure. Add no dependency unless evidence establishes necessity. Keep repository facade delegation and explicit token dependency architecture intact. No new host account/recovery system, broad UI work, authorization feature or generic framework.
- **D-24:** Apply accurate host-facing storage/migration guidance with the code that establishes it; final cross-phase copy reconciliation stays Phase 166. Any changed admin text requires PRODUCT personas/vocabulary and retired-wording checks. Do not expose internal lifetime versions as product UI concepts or promise immediate offline revocation.

### Agent's Discretion

Choose narrow module/callback names, internal result types, plan slicing and test fixture organization within these constraints. Prefer a cohesive implementation over duplicate endpoint policy. Research may refine internal mechanics but cannot reopen Phase 162 semantics or weaken the guarantees to simplify storage.

### Folded Todos

The matched DCR lifetime umbrella informs this phase; its pending todo remains owned by final Phase 166 proof. Do not close it at context capture or Phase 163 completion.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 163 goal, four success criteria and phase ownership.
- `.planning/REQUIREMENTS.md` — DCR-05/06/13/14 and cross-cutting constraints.
- `.planning/PROJECT.md` and `.planning/METHODOLOGY.md` — embedded host boundary, decisive research and automated proof.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md` — normative selected policy, consumer/error, legacy/storage and deployment contract.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json` — design examples, not runtime proof.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md` — all 27 selected decisions and inventories.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-VERIFICATION.md` — completed design gate and proof limits.
- `.planning/research/dcr-lifetimes/SCOPE.md` and `.planning/research/dcr-lifetimes/SUMMARY.md` — milestone scope/research.
- `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` — completed baseline audit, do not repeat wholesale.
- `.planning/todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md` — umbrella remains pending until Phase 166.
- `prompts/lockspire-ecto-token-and-audit-model.md`, `prompts/lockspire-host-app-integration-seam.md`, `prompts/lockspire-elixir-oss-library-practices.md`, `prompts/lockspire-security-posture-and-threat-model.md`, `prompts/lockspire-phoenix-system-design.md` — applicable background; current code and normative contract take precedence.
- `PRODUCT.md` — required before admin copy changes, not a mandate for UI redesign.

Primary implementation sources (verified 2026-10-20):
- https://raw.githubusercontent.com/elixir-ecto/ecto/v3.13.6/lib/ecto/repo.ex — actual pinned Ecto transaction semantics; Ecto SQL is separately 3.13.5.
- https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql/sandbox.ex — shared versus independent connections and cleanup.
- https://www.postgresql.org/docs/14/transaction-iso.html — current-row re-evaluation after lock waits.
- https://www.postgresql.org/docs/14/explicit-locking.html#LOCKING-ROWS — row/table lock behavior.
- https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT — transaction/statement versus actual time.
- https://www.postgresql.org/docs/14/sql-altertable.html — fast defaults still acquire exclusive table locks.
- https://www.postgresql.org/docs/14/functions-info.html#FUNCTIONS-INFO-SESSION-TABLE — pg_blocking_pids for targeted wait evidence.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/lockspire/domain/client.ex` and `lib/lockspire/storage/ecto/client_record.ex` hold provenance and credential state together; to_domain manually maps fields.
- `lib/lockspire/storage/client_store.ex` is the domain storage contract; `lib/lockspire/storage/ecto/repository/client_store.ex` already locks current client rows, but replacement currently applies a stale prebuilt client.
- `lib/lockspire/protocol/token_exchange/internal/dependencies.ex` and `lib/lockspire/protocol/token_exchange/internal/legacy_options.ex` are explicit adaptation seams. Capabilities currently default missing fields to :all; this cannot certify lifetime support.
- `lib/lockspire/install/migrations.ex` and `lib/lockspire/storage/ecto/migration.ex` provide checksum-preserving additive copies and prefix helpers.
- `test/lockspire/storage/repository_concurrency_test.exs`, `test/lockspire/storage/reencrypt_concurrency_test.exs` and `scripts/acceptance/clean_room/build_provider.py` provide independent transaction/lock and package-root test seams. Strengthen the reencrypt helper's global wait observation rather than copying it blindly.

### Established Patterns

- `test/lockspire/architecture_fitness_test.exs` requires repository facade delegation and prohibits token internal callback probing/option bags.
- `lib/lockspire/protocol/client_auth.ex` currently validates method/material without universal active/app eligibility. Public success makes authentication-only secret checks insufficient.
- `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` currently loses request clock. Existing clock conventions differ across AuthorizationFlow, PAR, device and CIBA; adapt explicitly.

### Integration Points

- `lib/lockspire/protocol/authorization_request.ex`, `lib/lockspire/protocol/authorization_flow.ex`, `lib/lockspire/protocol/device_verification.ex`, `lib/lockspire/ciba.ex` — intake, delayed approvals and code persistence.
- `lib/lockspire/protocol/pushed_authorization_request.ex`, `lib/lockspire/protocol/device_authorization.ex`, `lib/lockspire/protocol/backchannel_authentication.ex` — request creation/clock propagation.
- `lib/lockspire/workers/ciba_notification_worker.ex` and `lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex` — push bypasses ordinary ClientAuth.
- `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex`, `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex`, `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex`, `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex` — current-state guarded issuance and unified effective expiry.
- `lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex` — separate persistence plus subject/actor issuer checks.
- `lib/lockspire/protocol/userinfo.ex` currently hardcodes an Ecto client fetch; `lib/lockspire/protocol/introspection.ex` preserves owned-token semantics.
- `lib/lockspire/plug/verify_token.ex` stays offline. `lib/lockspire/web/controllers/registration_controller.ex` and lifecycle code need app-state-specific management rules without prematurely claiming Phase 165.
</code_context>

<specifics>
## Specific Ideas

1. Deadline 160, issuance 159: access row and signed exp are 160, expires_in is 1, refresh has its own ordinary TTL capped at 160. At 160 no token or code-consumption side effect.
2. Acquire client lock at 159, block on grant lock, move injected clock to 160 after confirmed wait: reject after lock release and roll back all writes. Repeat with committed disablement and credential identity replacement.
3. RFC 8693 requester A stays eligible; subject issuer B or actor issuer C expires independently. Reject invalid grant, preserve all durable identities and stable multi-app lock order.
4. Existing secret dates nil/creation/past/future/stale remain advisory on v0 rows. An adapter dropping version or a finite deadline must fail conformance, never gain unlimited authority.
5. Expired enabled app with valid management credential: GET/DELETE permitted, PUT forbidden. Disabled app blocked. Closed registration intake alone leaves management usable.
6. Public/custom-prefix legacy host expands schema, old build reads/writes before cutover, candidate explicitly writes v1 after old writers drain. Authoritative state remains intact; no old-binary protocol rollback claim afterward.

Relevant lenses: security/protocol, Elixir/Ecto architecture, PostgreSQL concurrency, host maintainer DX, SRE/deployment, support/product truth and regression engineering. Graphics/rendering disciplines do not add useful constraints here. User prefers small flat dependencies and automatic evidence over repeated manual approval.
</specifics>

<deferred>
## Deferred Ideas

- Phase 164: finite secret enforcement, wire secret metadata and atomic secret rotation under current policy.
- Phase 165: finite management token lifecycle, recovery and complete credential rotation behavior.
- Phase 166: full packaged end-to-end matrix, cross-phase security/redaction, required CI and final operator/public guidance reconciliation.
- New activation services, mixed-version zero-downtime bridge, app renewal, overlapping credentials, generic capability framework, distributed coordinator, admin redesign and new dependencies lack need within this phase.

### Reviewed Todos (not closed)

The DCR lifetime umbrella matches this scope but explicitly resolves in Phase 166; retain its pending status. No other todo was folded.
</deferred>

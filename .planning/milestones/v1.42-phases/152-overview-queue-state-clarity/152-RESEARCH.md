# Phase 152: Overview & Queue State Clarity — Research

**Researched:** 2026-10-12  
**Domain:** Phoenix LiveView admin overview and read-only OAuth/OIDC support queues  
**Confidence:** HIGH for source semantics and current ExUnit seams; MEDIUM for user-facing copy decisions already locked by the UI contract.

## User Constraints

### Locked Decisions

- Preserve the embedded Phoenix library boundary, host-owned login/accounts/layout/branding/product policy, and existing OAuth/OIDC security behavior. [CITED: `AGENTS.md`; `.planning/phases/152-overview-queue-state-clarity/152-UI-SPEC.md`]
- Keep interaction, device-authorization, and logout queues read-only. Do not add retry, discard, approve, deny, logout-now, worker, or protocol mutation controls. [CITED: `.planning/REQUIREMENTS.md` SAFE-01; `.planning/phases/152-overview-queue-state-clarity/152-UI-SPEC.md`]
- Show successful zero, loading, and unavailable as separate states; a failed source must not be rendered as zero or healthy. [CITED: `.planning/phases/152-overview-queue-state-clarity/152-UI-SPEC.md`]
- Describe recorded evidence and supported consequences only. A recorded logout response/render does not prove remote session termination; refresh-token reuse evidence does not prove compromise. [CITED: `.planning/phases/152-overview-queue-state-clarity/152-UI-SPEC.md`]
- Use plain, empathetic user-facing language. Do not show “operator” as audience language, and remove low-value implementation/provenance notes instead of moving them into tooltips. [CITED: user direction in `.planning/STATE.md` v1.42 milestone direction; `.planning/REQUIREMENTS.md` UI-02; phase UI-SPEC]
- Reuse the existing LiveView component/token system; add no dependencies, queue actions, schema changes, protocol changes, or new motion. Keep any screenshots synthetic and redaction-safe; never expose private key material. [CITED: `.planning/REQUIREMENTS.md` SAFE-01 and Delivery Rules; phase UI-SPEC]

### the agent's Discretion

- Choose the most concise page/row wording that remains accurate to the source state and supports the staff user's next investigation. [CITED: phase UI-SPEC, Copywriting Contract]
- Remove duplicate overview counts and secondary copy when they do not help a decision; keep only record summaries with a meaningful destination. [CITED: phase UI-SPEC, Overview Information Contract]
- If an overview count represents a subset, provide a matching read-only filtered destination; otherwise count and label the full destination list. [CITED: phase UI-SPEC, Overview Information Contract]

### Deferred Ideas (OUT OF SCOPE)

- Do not resolve or accept CR-01, the separate critical plaintext private signing-key-at-rest issue. [CITED: `.planning/REQUIREMENTS.md` Out of Scope]
- Do not add queue mutation controls or change storage schemas, OAuth/OIDC behavior, security defaults, or host-owned behavior. [CITED: `.planning/REQUIREMENTS.md` Out of Scope and SAFE-01]

## Project Constraints (from AGENTS.md)

- Build Lockspire as a separate companion library, not as a Sigra module; preserve the embedded-library shape and do not make a standalone authorization service required. [CITED: `AGENTS.md`, Working Boundaries]
- Keep protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces bounded. The host owns account resolution, claims, login redirects, branding, and product policy. [CITED: `AGENTS.md`, Working Boundaries]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted authentication, or a complete CIAM suite. [CITED: `AGENTS.md`, Working Boundaries]
- Keep the phase scoped to the existing Phoenix/LiveView/Ecto/PostgreSQL stack; no dependency additions are justified. [CITED: `AGENTS.md`, Technology Stack; phase UI-SPEC, Registry Safety]
- Preserve existing security defaults: required PKCE S256, exact redirect URI matching, hashed client secrets, short-lived single-use authorization codes, refresh-token rotation and family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction in logs/admin surfaces. [CITED: `AGENTS.md`, Security Defaults To Preserve]
- Keep product priorities in view: Phoenix host-app install DX, secure authorization/OIDC lifecycle, calm staff workflows, telemetry/auditability, release hygiene, and executable documentation. [CITED: `AGENTS.md`, Product Priorities]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-03 | Overview metrics and queue labels accurately match the records and status filters they describe. Explain token reuse and logout-delivery outcomes without implying compromise or claiming unsupported controls. A failed read remains distinct from an empty or healthy result. | Overview and queue count/filter semantics are verified below; existing LiveView tests already cover state distinctions, redaction, and read-only controls, but need assertions updated for exact subset pivots and revised copy. |

## Summary

Phase 152 is a presentation and read-only routing refinement in four existing Phoenix LiveViews: `/admin` and `/admin/overview`, `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`. The current overview independently reads each source and distinguishes loading, loaded, and unavailable observations. Keep this per-source isolation. Its current interaction/device/logout attention counts are subsets while their links open full historical lists; the refresh-token count already links to an exact status filter, and the active-consent count links to its exact filter. Make the remaining links truthful through an existing-list read filter or by changing the count/label to represent the whole destination list. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:186-279`; `lib/lockspire/web/live/admin/interactions_live/index.ex:22-30,135-142`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:22-30,141-148`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:22-31,134-140`; `lib/lockspire/web/live/admin/tokens_live/index.ex:71-80,220-230,267-285`]

Use existing `page_hero`, `section_card`, `pane`, `metric_grid`, `summary_stat`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, and `empty_state` components. The three queues already have a read-only loading/error/empty/loaded pattern and tests for it. Tighten headlines and summaries to tell staff what is recorded and what they can inspect; remove duplicated inventory notes and repeated disclaimers. Refresh-token reuse means a token with reuse evidence was presented after it had already been redeemed or revoked, and the storage transaction revokes every token in that family. Logout records represent one client/channel delivery; `retryable` and `discarded` refer to delivery status, not the entire logout event. Do not claim account compromise, confirmed remote sign-out, or a queue action. [VERIFIED: `lib/lockspire/storage/ecto/repository/token_store.ex:241-264,339-349`; `lib/lockspire/domain/logout_delivery.ex:6-16,17-36`; `lib/lockspire/workers/backchannel_logout_delivery_worker.ex:154-206,210-260`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:195-224`]

**Primary recommendation:** Keep the current Phoenix/LiveView and component stack, correct overview count-to-destination correspondence, preserve independent read states, and rewrite only the visible text needed to make record facts and next pivots plain and exact.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Read overview sources and derive summary observations | API / Backend | Frontend Server (SSR) | `OverviewLive.Index.load_summary/0` calls the `Lockspire.Admin` boundary and converts each read to a loaded/loading/unavailable value; the LiveView renders that presentation state. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:186-279`] |
| Read and filter interactions/device/logout records | API / Backend | Frontend Server (SSR) | Each LiveView reads through `Lockspire.Admin`; underlying storage lists saved records. A filter for an overview subset should stay read-only and should not alter domain or storage state. [VERIFIED: `lib/lockspire/web/live/admin/interactions_live/index.ex:135-142`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:141-148`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:134-140`] |
| Render accessible, redacted queue rows and state feedback | Frontend Server (SSR) | Browser / Client | Existing AdminComponents own presentation primitives; LiveViews use them with redaction helpers, semantic status text, and status/error states. [VERIFIED: `lib/lockspire/web/live/admin/interactions_live/index.ex:33-130`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:33-137`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:34-130`] |
| Enforce OAuth token reuse and logout-delivery outcomes | API / Backend | Database / Storage | Token store and worker own the persistent consequences and statuses; presentation must report saved facts without implying a stronger remote outcome. [VERIFIED: `lib/lockspire/storage/ecto/repository/token_store.ex:241-264,339-349`; `lib/lockspire/workers/backchannel_logout_delivery_worker.ex:154-206`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | Existing project dependency; no version change | Server-rendered interactive admin pages and URL-driven read filters | All in-scope routes are existing LiveViews; user-approved plan is copy/presentation/read-filter work, with no new client framework. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:1-4`; `mix.exs:35-45`] |
| Lockspire `Admin` boundary and Ecto repository | In-repo | Read client/token/consent/key/interaction/device/logout data | Existing pages read through this boundary; preserve it instead of bypassing it from UI code. [VERIFIED: `lib/lockspire/admin.ex:18-34,168-169`; `lib/lockspire/storage/ecto/repository.ex:177-220,375-415`] |
| `Lockspire.Web.Components.AdminComponents` | In-repo | Shared semantic page, pane, summary, row, badge, and empty-state rendering | The phase UI contract enumerates reusable components; each current queue already uses the relevant set. [CITED: phase UI-SPEC, Design System and Component Inventory; VERIFIED: the three queue LiveViews cited in the Architecture Map] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | Existing test stack | Assert rendered routes, status wording, filter correspondence, empty/error states, read-only boundary, and redaction | Use focused tests in the four existing admin LiveView test modules; no test package is needed. [VERIFIED: `test/lockspire/web/live/admin/overview_live_test.exs:1-5`; `test/lockspire/web/live/admin/interactions_live_test.exs:1-5`; `test/lockspire/web/live/admin/device_authorizations_live_test.exs:1-5`; `test/lockspire/web/live/admin/logout_deliveries_live_test.exs:1-4`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing URL-driven filtering over the existing read models | New queue controls or new storage/schema APIs | Do not add new mutation or storage surface. Existing list reads already return saved records; filtering the existing list in the LiveView is enough for current data volume assumptions, but pagination/performance limits are not established here. [VERIFIED: existing list functions cited above; `[ASSUMED]` performance at current list size] |
| Existing Lockspire components and design tokens | New UI/component dependency | A dependency adds cost and is out of scope; no dependency is required for the component patterns already present. [CITED: phase UI-SPEC, Design System and Registry Safety] |

**Installation:** None. No external package is added.

## Architecture Patterns

### Independent read observations on the overview

**Use:** Keep each source's observation local. `observe_list/2` accepts only `{:ok, rows}` where rows is a list, catches a read exception, and otherwise returns unavailable. `observation_value/2` renders `Loading` until loaded and `Unavailable` for a failed observation. Keep each tile/pivot associated with that source; one unavailable list must not erase successful sibling reads. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:236-288`]

**Important limitation:** Overview errors currently display unavailable text but do not offer an explicit read-reload event. Existing route pivots still reach the corresponding read page. If UI-03's failure state is adjusted, preserve that safe route pivot and do not describe a navigation as retry unless the target route actually reloads the failed source. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:31-180`; `[CITED: phase UI-SPEC, Overview Information Contract #7]`]

### URL-owned read filters for exact overview pivots

The token Support page already normalizes a status query param, passes the resulting status into `Admin.list_tokens/1`, and derives both rows and count from the returned filtered set. Its `reuse_detected` status uses `reuse_detected_at` presence in storage and is the same predicate used by the enriched token status. [VERIFIED: `lib/lockspire/web/live/admin/tokens_live/index.ex:71-80,220-285`; `lib/lockspire/admin/tokens.ex:13-19,32-37,147-152,200-205`; `lib/lockspire/storage/ecto/repository/token_store.ex:13-24,418-420`]

Apply this pattern to interaction, device, and logout subset pivots only if keeping subset counts on the overview: normalize known query values, derive the displayed rows from the list read, and retain the selected filter in the URL. Do not let unknown query values silently present themselves as a narrower view. Add count/row assertions that prove every linked overview value is exactly the count of destination rows. [CITED: phase UI-SPEC, Overview Information Contract #4; VERIFIED: current queue handlers ignore params at `lib/lockspire/web/live/admin/interactions_live/index.ex:22-30`, `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:22-30`, and `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:22-31`]

### Record status before consequence; consequence before identifiers

Keep `status_badge` visible and text-labeled; lead each row with record state and one verified implication, then place redacted IDs, times, client context, and optional endpoint/failure details in secondary metadata. Existing `dense_resource_row`, `long_value`, `Redaction.handle/2`, and status components are already used by all three queues. Do not print user/device code plaintext, token values, authorization codes, cookies, session values, or private keys. [VERIFIED: current queue render implementations cited above; `test/lockspire/web/live/admin/interactions_live_test.exs:60-77`; `test/lockspire/web/live/admin/device_authorizations_live_test.exs:68-93,157-166`; `test/lockspire/web/live/admin/logout_deliveries_live_test.exs:205-219`]

### Distinguish load state from result state

Keep a three-branch presentation: loading before the read; unavailable when the read errors/raises; loaded list, with a separate successful-empty branch. Interaction and logout tests explicitly cover this. Device tests cover loading/error/empty and assert that error output contains neither a count nor an empty state. Overview tests cover independent source failures and source links. [VERIFIED: `lib/lockspire/web/live/admin/interactions_live/index.ex:71-99,135-142`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:74-101,141-148`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:62-90,134-140`; test ranges in Validation Architecture]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shared admin page/row presentation | New one-off dashboard or queue framework | Existing `AdminComponents` primitives and semantic CSS tokens | Existing route tests and UI contract already depend on these components; keep per-route status meaning local. [CITED: phase UI-SPEC, Component Inventory] |
| Secret and identifier display | Ad hoc truncation or raw token/code interpolation | Existing `Lockspire.Redaction.handle/2` and `AdminComponents.long_value` patterns | Device and interaction tests explicitly prohibit raw sensitive values; retain established redaction. [VERIFIED: queue test paths/ranges above] |
| State announcements | Client-side polling/animation to explain state | Existing `role="status"`, empty-state component, and loaded/unavailable state branches | Current tests verify these static LiveView states; no motion or new browser runtime is needed. [VERIFIED: three LiveView sources and tests cited above] |

**Key insight:** The chief correctness risk is not component rendering; it is a dashboard number whose label or link describes a different set than the destination page. Test the source query, count, row set, and href together.

## Common Pitfalls

### Pitfall 1: Calling a subset count a full queue count

**What goes wrong:** Overview currently counts pending interactions and pending device authorizations but links to full historical lists; it counts retryable plus discarded logout deliveries but links to all deliveries. Users see a count that is not the number of rows on arrival. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:163-177,220-230`; list reads are unfiltered at the queue sources cited above]

**How to avoid:** Keep count and list predicate identical, with a read-only query-param filter if preserving attention subsets; otherwise label/count all records. Token reuse and active consent already have exact status-filter hrefs (`status=reuse_detected` and `status=active`). [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:141-149`; `lib/lockspire/web/live/admin/tokens_live/index.ex:71-80,255-285`; phase UI-SPEC]

### Pitfall 2: Treating a reused refresh token as proof of compromise

**What goes wrong:** The record proves Lockspire observed a token with reuse state; it does not identify why the token was presented again or prove who presented it. The current transaction marks reuse when an unexpired refresh record has already been redeemed or revoked, then revokes every record sharing its family ID. [VERIFIED: `lib/lockspire/storage/ecto/repository/token_store.ex:241-264,339-349`]

**How to avoid:** Count matching token records, not invented “incidents.” Say a previously redeemed or revoked refresh token was presented again and that Lockspire revoked the token family. Avoid “account compromised,” “attacker,” or a causal claim about which client/person reused it. [VERIFIED: source above; `[CITED: phase UI-SPEC, Overview Information Contract #5]`]

### Pitfall 3: Treating a logout delivery as the whole logout or remote sign-out

**What goes wrong:** Each saved row is one per-client/per-channel delivery. A 2xx response means the endpoint accepted the request; a rendered front-channel page only shows rendering. Neither proves the relying party ended its user session. A `retryable` or `discarded` status is a delivery outcome, not a control on this read-only page. [VERIFIED: `lib/lockspire/domain/logout_delivery.ex:2-36`; `lib/lockspire/workers/backchannel_logout_delivery_worker.ex:154-206`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:204-224,276-298`]

**How to avoid:** Use `Logout deliveries needing review` for the overview subset, and describe the actual channel, recorded response/failure, and safe client configuration pivot. Remove repeated “Support note” and “no worker action is exposed” disclaimers. Never promise retry, successful remote sign-out, or user logout based only on this record. [CITED: phase UI-SPEC, Logout deliveries]

### Pitfall 4: Saying “active” when the page shows history

**What goes wrong:** The interactions LiveView loads every recorded status, but its browser page title is `Active interactions`. The domain's exact state union includes completed, denied, and expired records too. [VERIFIED: `lib/lockspire/web/live/admin/interactions_live/index.ex:12-30,135-157`; `lib/lockspire/domain/interaction.ex:6-8`]

**How to avoid:** Use the contract title `Authorization interactions` and plain row outcomes. Preserve distinct pending login, pending consent, completed, denied, and expired labels. [CITED: phase UI-SPEC, Route Contract and Interactions]

### Pitfall 5: Conflating loading, unavailable, and empty

**What goes wrong:** Returning `[]` for an error can create a false healthy-zero display. The current queue loaders correctly return separate `:loading`, `:unavailable`, and `:loaded` values. Keep the loaded check in the empty-state condition (especially in the device queue, where the `[]` guard is safe only because unavailable is branched first). [VERIFIED: `lib/lockspire/web/live/admin/interactions_live/index.ex:15-30,71-99,135-142`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:15-30,74-101,141-148`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:17-31,62-90,134-140`]

**How to avoid:** Extend existing failure injection tests for every source, assert failed sources show unavailable and no zero/empty copy, and assert unaffected overview sources still render. Keep read reload labels honest and same-route.

### Pitfall 6: Turning explanatory copy into backend jargon

**What goes wrong:** Current overview says “Measured from token inventory,” “reuse incidents,” “logout failures,” and “issuer-wide”; logout rows repeat support notes with internal worker caveats. These phrases explain implementation or invent a unit instead of helping a staff member understand a record. [VERIFIED: `lib/lockspire/web/live/admin/overview_live/index.ex:31-35,43-79,81-180,286-302`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:38-46,276-298`]

**How to avoid:** Remove low-value provenance and repeat copy rather than moving it into a tooltip. Keep a short in-place explanation only where a decision depends on it (for example, endpoint acceptance does not confirm remote session termination). Do not use “operator” as visible audience text. [CITED: phase UI-SPEC, Overview and Copywriting Contracts; `.planning/REQUIREMENTS.md` UI-02]

## Code Examples

### Exact refresh-token reuse predicate

```elixir
# Source: lib/lockspire/storage/ecto/repository/token_store.ex:418-420
defp maybe_filter_status(query, :reuse_detected, _),
  do: where(query, [token], not is_nil(token.reuse_detected_at))
```

The verbatim source also confirms the reuse state check: `defp token_status(%Token{reuse_detected_at: %DateTime{}}), do: :reuse_detected` [`lib/lockspire/admin/tokens.ex:200-205`]. The index can safely use its existing `status=reuse_detected` read filter as the overview pivot. Count list rows if labeling a token count; do not rename row count as an incident count. [VERIFIED: cited paths/lines]

### Preserve read outcomes

```elixir
# Source: lib/lockspire/web/live/admin/interactions_live/index.ex:135-142
defp load_interactions do
  case Admin.list_interactions() do
    {:ok, interactions} when is_list(interactions) -> {:loaded, interactions}
    _other -> {:unavailable, []}
  end
rescue
  _error -> {:unavailable, []}
end
```

The loaded-empty check must remain separate from unavailable. A read retry is navigation back to the same read route; it is not a queue mutation. [VERIFIED: cited path/lines; phase UI-SPEC]

## Source-of-Truth State Values

These values are quoted verbatim from their source definitions so the planner can preserve domain semantics:

| Domain | Verbatim source definition | Planning implication |
|--------|----------------------------|----------------------|
| Interaction status | `@type status :: :pending_login | :pending_consent | :completed | :denied | :expired` [`lib/lockspire/domain/interaction.ex:6-8`] | Page includes current and historical states; title must not imply pending-only. |
| Device authorization status | `@statuses [:pending, :approved, :denied, :consumed, :expired]` [`lib/lockspire/domain/device_authorization.ex:8-8`]; `@type status :: :pending | :approved | :denied | :consumed | :expired` [`lib/lockspire/domain/device_authorization.ex:38-38`] | Full list includes pending and historical outcomes; code/user-code plaintext remains forbidden. |
| Logout delivery status | `@type status ::` followed by `:pending | :enqueued | :attempted | :succeeded | :retryable | :discarded | :rendered | :skipped` [`lib/lockspire/domain/logout_delivery.ex:7-16`] | Preserve queued, attempted, endpoint success, retryable, discarded, rendered, and skipped distinctions. |
| Overview pending-interaction predicate | `open: Enum.count(interactions, &(&1.status in [:pending_login, :pending_consent]))` [`lib/lockspire/web/live/admin/overview_live/index.ex:220-223`] | This count is a subset of the unfiltered interaction list. |
| Overview pending-device predicate | `pending: Enum.count(device_authorizations, &(&1.status == :pending))` [`lib/lockspire/web/live/admin/overview_live/index.ex:224-227`] | This count is a subset of the unfiltered device list. |
| Overview logout-attention predicate | `failed: Enum.count(logouts, &(&1.status in [:retryable, :discarded]))` [`lib/lockspire/web/live/admin/overview_live/index.ex:228-231`] | This is a subset and should be described as deliveries needing review. |
| Queue delivery-metric predicates | `queued: Enum.count(deliveries, &(&1.status in [:pending, :enqueued]))`, `retryable: Enum.count(deliveries, &(&1.status == :retryable))`, `discarded: Enum.count(deliveries, &(&1.status == :discarded))`, `accepted: Enum.count(deliveries, &(&1.status == :succeeded))`, `rendered: Enum.count(deliveries, &(&1.status == :rendered))` [`lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:147-156`] | If metrics remain, they must retain their exact aggregation and pair with understandable text. |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest and project AdminProof HTML assertions. [VERIFIED: four existing test modules, headers] |
| Config file | `mix.exs` |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` |
| Full suite command | `MIX_ENV=test mix test.fast` (project alias includes setup, `test/lockspire`, `test/mix`, and integration tests). [VERIFIED: `mix.exs`, alias `test.fast`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-03 | Overview count, label, and href match destination filtered rows for reuse, pending interactions/device auth, and logout deliveries needing review; loaded source failures remain independent. | LiveView render/integration | Focused four-file command above | ✅ Existing overview tests in `overview_live_test.exs`; add exact list/count/pivot coverage. |
| UI-03 | Interactions title accurately covers historical statuses; queue empty/loading/unavailable remain distinct; no unsupported actions or raw secret fields. | LiveView render | Focused four-file command above | ✅ `interactions_live_test.exs`; revise expectations and preserve secret/read-only assertions. |
| UI-03 | Device request states, expiry, empty/unavailable distinction, redaction, and read-only boundary remain accurate. | LiveView render | Focused four-file command above | ✅ `device_authorizations_live_test.exs`; preserve existing status-state fixtures. |
| UI-03 | Logout delivery facts distinguish retryable and discarded from remote sign-out; list/filter matches overview; no worker controls or sensitive failure data leak. | LiveView render | Focused four-file command above | ✅ `logout_deliveries_live_test.exs`; add exact subset filter/pivot and updated-copy coverage. |

### Sampling Rate

- **Per task commit:** Run the relevant test file(s) from the focused command.
- **Per phase gate:** Run all four focused files, then `MIX_ENV=test mix test.fast` before verification.

### Wave 0 Gaps

- No framework or fixture gaps identified. Existing tests already exercise failed reads, loaded zero/one/many, status buckets, redaction, and no queue controls. The gap is that overview test assertions currently bless old boilerplate and only check href existence, not whether overview subset counts match the rows shown after navigation. [VERIFIED: `test/lockspire/web/live/admin/overview_live_test.exs:154-297`; other test modules cited above]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | No authentication flow changes; preserve host-owned admin authentication and user/account boundaries. |
| V3 Session Management | Yes | No session/logout behavior changes; do not imply remote sign-out from delivery evidence. |
| V4 Access Control | Yes | Keep existing host guard boundary and make no queue mutation controls. |
| V5 Input Validation | Yes | Whitelist recognized URL filter values and treat unknown query values as the unfiltered/all state or invalid state explicitly; never produce a false subset label. |
| V6 Cryptography | Yes | No secret/key display or cryptographic implementation changes; keep private signing-key evidence out of browser output. |

These controls follow explicit project/phase boundaries, not a claim of formal ASVS compliance. [CITED: `AGENTS.md`; `.planning/REQUIREMENTS.md` SAFE-01; phase UI-SPEC]

### Known Threat Patterns for Phoenix LiveView Admin Surfaces

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive token/device/user-code values leak through a rendered list or screenshot | Information disclosure | Use current redaction helpers; keep IDs/handles secondary; maintain forbidden-secret assertions and synthetic-only proof. [VERIFIED: queue source/test paths above] |
| Display label overstates evidence (reuse implies compromise; HTTP 2xx implies user signed out) | Spoofing / information integrity | Map copy to exact persisted field/status and state what remains unconfirmed. [VERIFIED: token store and worker paths above] |
| Query parameters falsely imply filtering while full rows remain visible | Tampering / information integrity | Normalize accepted filter values and assert displayed row-set and summary count together. [VERIFIED: token filter implementation; current other queue handlers ignore params] |
| Retry/approve/discard copy suggests a mutation that is not backed by a queue page action | Elevation / information integrity | Keep queues read-only; retry links only re-read the page. [CITED: phase UI-SPEC, Interaction and State Rules; `test/lockspire/web/live/admin/*_live_test.exs` existing no-control assertions] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Filtering an already loaded list in the LiveView is acceptable for the existing scale because the three storage calls currently return their complete lists and no pagination/scale requirement appears in this phase's locked scope. | Architecture Patterns | A large production history could require repository-level filters or pagination for response time/memory; no such target is specified. |
| A2 | The phrase “family was revoked” is more useful to staff than an internal audit code, as long as it is tied to the reuse timestamp and explained without implying why the token was presented again. | Summary / Pitfalls | Copy may be too technical; however, omitting the family-wide consequence could obscure meaningful account impact. |

## Open Questions

No user decision is required for planning. The source and UI contract leave implementation choice between (a) read-only URL filters for the three subset pivots and (b) changing overview summary rows to counts of their complete destination lists. Prefer preserving the already-approved attention subsets and add a small normalized URL filter for the existing-list read paths if that remains within one-plan scope; do not add storage/schema or mutation APIs. This recommendation is MEDIUM confidence because current loaded-list size is not quantified. [CITED: phase UI-SPEC, Overview Information Contract #4; `[ASSUMED]` current list size is acceptable]

## Environment Availability

Step 2.6: SKIPPED. This is a code/test/UI phase with no new external service or package dependency. Existing Elixir/Phoenix test tools are project-local; no external tool is required.

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` — project boundaries, embedded-library shape, host responsibilities, stack, and security defaults.
- `.planning/REQUIREMENTS.md` UI-03 and SAFE-01 — phase acceptance and immutable safety boundaries.
- `.planning/phases/152-overview-queue-state-clarity/152-UI-SPEC.md` — locked route, copy, count/filter, read-state, and UI component contract.
- `.planning/milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` — source route jobs for overview, interactions, device authorizations, and logout deliveries.
- `lib/lockspire/web/live/admin/overview_live/index.ex` and the three queue LiveViews — current queries, visible text, routing, and read-state behavior.
- `lib/lockspire/admin/tokens.ex`, `lib/lockspire/storage/ecto/repository/token_store.ex`, `lib/lockspire/domain/{interaction,device_authorization,logout_delivery}.ex`, `lib/lockspire/workers/backchannel_logout_delivery_worker.ex` — state values and source-level outcome semantics.
- `test/lockspire/web/live/admin/{overview,interactions,device_authorizations,logout_deliveries}_live_test.exs` — current regression seams for accuracy, redaction, loading/error/empty, and read-only behavior.

### External Sources

None needed. Local source is authoritative for this phase; no package or external framework changes are proposed.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all relevant UI pages and tests exist in the repository; no new packages.
- Architecture: HIGH — source call paths and storage semantics read directly from current code.
- Pitfalls: HIGH — count/filter mismatch and outcome wording are observable directly in source/tests; choice of filter-vs-full-count is medium because list scale is unspecified.

**Research date:** 2026-10-12  
**Valid until:** 2026-11-11 for code patterns and route behavior; re-check line references if source changes before execution.

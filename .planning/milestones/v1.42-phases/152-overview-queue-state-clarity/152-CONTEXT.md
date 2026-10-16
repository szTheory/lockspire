---
phase: overview-queue-state-clarity
created: 2026-10-12
source: User feedback, v1.42 requirements, existing route review
---

# Phase 152 Context: Overview & Queue State Clarity

## User direction

Make overview and support/operation signals understandable to staff who need to decide what to inspect next. Use plain, empathetic, concise language. Remove labels and explanatory text that describe implementation provenance instead of helping a decision. Avoid “operator” as visible audience copy, and avoid unexplained terms such as “posture,” “reuse incident,” and “issuer-wide.” Preserve the familiar grouped navigation and current Lockspire design system.

## Decisions

- Counts on the overview must describe the same record subset shown by their destination. Where an overview count represents only pending, retryable, or discarded records, use the existing queue's read-only query filters to open that subset; keep direct navigation to the full historical queue available.
- A detected refresh-token reuse is a record that an already-used refresh token was presented again. Lockspire revokes the token family. The UI must explain that consequence without claiming the user or client was compromised.
- A retryable or discarded logout row describes delivery to a client endpoint or browser channel. It does not establish that the relying party ended a user session. Keep delivery state and channel visible, state only recorded outcomes, and add no retry/discard or worker controls.
- Interactions and device-authorization pages include historical states, so use neutral page titles and factual state labels rather than implying every row is active or waiting.
- A successful empty read, a loading read, and a failed read remain visibly distinct for each independent source. A failed read never renders as zero or a successful empty state; recovery retries only the read.
- Keep client, account, credential, token, code, cookie, user-code, device-code, verifier, and private-key redaction intact. Preserve protocol behavior, security defaults, revocation scopes, and CR-01's separate unresolved status.

## Scope boundary

Phase 152 updates overview and read-only queue presentation, copy, query pivots, and focused tests only. Broader Configure/Support copy and hierarchy pass belongs to Phase 153. No new dependency, data model, protocol action, host-owned UX, or queue mutation is authorized.

## Open questions

None. The remaining UI wording and grouping choices are resolved by the decisions above, existing code facts, and the approved Phase 152 UI-SPEC.

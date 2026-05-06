# Domain Pitfalls: CIBA

**Domain:** Embedded OAuth/OIDC Provider (Elixir/Phoenix)
**Researched:** 2026-05-05

## Critical Pitfalls

Mistakes that cause rewrites or major security issues.

### Pitfall 1: Unsolicited Authentication Requests (User Fatigue)
**What goes wrong:** A malicious or buggy client repeatedly sends CIBA requests for a user, causing their Authentication Device (AD) to be spammed with push notifications (MFA Fatigue/Prompt Bombing).
**Why it happens:** The RP only needs a hint (like an email) to trigger the flow. If Lockspire and the Host blindly forward all requests, the user is bombarded.
**Consequences:** User frustration, potential accidental approval by a fatigued user (security breach).
**Prevention:** 
1. Implement and enforce the `user_code` parameter. A secret code the user must type on the Consumption Device, which is then verified before notifying the AD.
2. Implement strict rate limiting (`slow_down` error responses) for the `/bc-authorize` endpoint.

### Pitfall 2: Token Endpoint Polling Exhaustion
**What goes wrong:** RPs poll the token endpoint aggressively in Poll mode, overwhelming the Lockspire database.
**Why it happens:** RPs ignore the `interval` parameter returned by `/bc-authorize` or the database queries for the pending request are unoptimized.
**Consequences:** Denial of Service (DoS) on the provider database.
**Prevention:**
1. Lockspire must strictly enforce the `interval` parameter, returning a `slow_down` error if the RP polls too frequently.
2. Ensure the `CIBARequest` table has a highly optimized index on `auth_req_id`.

## Moderate Pitfalls

### Pitfall 1: Context Loss in the UI
**What goes wrong:** The user receives a notification "Approve login?" but doesn't know *who* or *where* the request came from.
**Prevention:** Utilize the `binding_message` parameter. The RP generates a visual code (e.g., "XYZ-123") displayed on the Consumption Device. Lockspire passes this to the Host app, which displays it on the Authentication Device. The user visually verifies the codes match before approving.

### Pitfall 2: Webhook Delivery Failures (Ping/Push)
**What goes wrong:** Lockspire attempts to notify the RP (Ping/Push) but the RP's endpoint is temporarily down. Lockspire drops the notification, and the transaction hangs indefinitely.
**Prevention:** Always use a durable background job queue (Oban) with exponential backoff for outbound webhooks. Lockspire must also require `client_notification_token` to authenticate the webhook to the RP securely.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Core Protocol (Poll) | Not handling the `authorization_pending` state correctly, leading to 400 errors instead of the spec-defined response. | Strict unit tests against the OIDC CIBA conformance suite expectations for the token endpoint. |
| Host Delegation | Creating a bottleneck by triggering host notifications synchronously. | Ensure the Host callback boundary explicitly expects asynchronous processing or handles the delegation in an Elixir Task. |

## Sources

- CIBA Core 1.0 Security Considerations (Section 13)
- OIDF Conformance Suite CIBA Test Profiles

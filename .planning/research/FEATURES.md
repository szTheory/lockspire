# Feature Landscape: CIBA

**Domain:** Embedded OAuth/OIDC Provider (Elixir/Phoenix)
**Researched:** 2026-05-05

## Table Stakes

Features users expect for basic CIBA compliance. Missing = product cannot claim CIBA support.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `/bc-authorize` Endpoint | Core entry point for CIBA requests. | Medium | Must handle hint resolution (`login_hint`, `login_hint_token`, `id_token_hint`), client authentication, and scope validation. |
| Poll Delivery Mode | The baseline delivery mechanism for CIBA. | Low | Clients repeatedly poll the token endpoint with `grant_type=urn:openid:params:grant-type:ciba` and the `auth_req_id`. |
| Host Consent Callback | Mechanism for the Host app to report the outcome. | Low | Must expose a function like `Lockspire.CIBA.grant(auth_req_id, account_id)` and `Lockspire.CIBA.deny(auth_req_id)`. |
| CIBA Error Responses | Standardized errors (e.g., `authorization_pending`, `slow_down`). | Low | Essential for Poll mode clients to back off correctly. |

## Differentiators

Features that set Lockspire apart, taking advantage of Elixir's strengths.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Ping Delivery Mode | Eliminates client polling overhead by notifying them when auth is done. | Medium | Requires Oban to reliably deliver the HTTP POST to the client's registered notification endpoint. |
| Push Delivery Mode | Delivers tokens directly to the client's endpoint, removing the need for a token endpoint call. | High | Requires secure transmission of tokens and complex token binding claims (`urn:openid:params:jwt:claim:auth_req_id`). |
| Signed Authentication Requests | Enhances security by requiring clients to sign their CIBA initialization requests. | High | Prevents tampering and ensures authenticity of the request. Fits well with Lockspire's existing JAR capabilities. |

## Anti-Features

Features to explicitly NOT build in Lockspire.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Push Notification Delivery | Lockspire does not own the user's devices (FCM, APNs, SMS). | Delegate the actual user notification to the Host application via a Behaviour callback (e.g., `Lockspire.Host.ciba_request/1`). |
| Out-of-Band Consent UI | Lockspire shouldn't render the mobile or web view where the user clicks "Approve". | Host application builds the UI and calls Lockspire APIs to finalize the transaction. |

## Feature Dependencies

```
`/bc-authorize` Endpoint → Poll Mode
`/bc-authorize` Endpoint → Host Consent Callback
Host Consent Callback → Ping Delivery Mode
Host Consent Callback → Push Delivery Mode
```

## MVP Recommendation

Prioritize:
1. `/bc-authorize` Endpoint
2. Poll Delivery Mode
3. Host Consent Callback

Defer: 
- Push Delivery Mode: High complexity due to token delivery security and Oban dependencies. Can follow in a subsequent release once Poll is stable.

## Sources

- CIBA Core 1.0 Specification

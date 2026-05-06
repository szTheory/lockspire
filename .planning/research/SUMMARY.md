# Research Summary: Lockspire OpenID Connect CIBA

**Domain:** Embedded OAuth/OIDC Provider (Elixir/Phoenix)
**Researched:** 2026-05-05
**Overall confidence:** HIGH

## Executive Summary

Client-Initiated Backchannel Authentication (CIBA) Core 1.0 allows Relying Parties (RPs) to initiate authentication on behalf of a user without requiring browser redirects on the Consumption Device (CD). Instead, the user is authenticated via an Out-of-Band (OOB) mechanism on their Authentication Device (AD), such as a smartphone push notification. 

For Lockspire, CIBA represents a significant competitive advantage. Elixir's inherent concurrency, coupled with Oban for background processing, makes Ping and Push delivery modes trivial and resilient compared to other language ecosystems. However, as an embedded library, Lockspire must strictly separate protocol state (managing `auth_req_id`, polling intervals, token issuance) from the delivery mechanism. The host application remains entirely responsible for sending the actual push notification to the user and collecting their consent.

## Key Findings

**Stack:** Leverages existing Elixir concurrency primitives (Registry/PubSub) and Oban for guaranteed webhook delivery in Ping/Push modes.
**Architecture:** Protocol validation happens in Lockspire (`/bc-authorize`), but out-of-band notification logic is delegated to the host application via a Behaviour.
**Critical pitfall:** Allowing malicious clients to spam users with unsolicited push notifications. Strict validation of `login_hint_token` and enforcement of `user_code`/`binding_message` are necessary.

## Implications for Roadmap

Based on research, suggested phase structure for CIBA:

1. **CIBA Core Protocol & Poll Mode** - Implement the `/bc-authorize` endpoint, new `grant_type=urn:openid:params:grant-type:ciba`, and database schema for tracking CIBA requests.
   - Addresses: Core specification compliance and the easiest delivery mode (Poll) for clients to adopt.
   - Avoids: Infrastructure overhead of webhooks before the core state machine is proven.

2. **Host Delegation & Notification Seams** - Define the `Lockspire.Host` callbacks to trigger host notifications and receive asynchronous consent results.
   - Addresses: The boundary between Lockspire's protocol state and the host's push notification infrastructure.

3. **Ping and Push Delivery Modes (Oban Integration)** - Add support for outgoing webhooks to notify clients when authentication is complete.
   - Addresses: The advanced CIBA delivery modes, utilizing Oban for retry logic and resilience.
   - Avoids: Building custom HTTP retry loops, relying instead on established ecosystem tools.

**Phase ordering rationale:**
- Poll mode requires no outgoing HTTP calls from Lockspire and establishes the core database structures. The Host callback boundary must be defined before advanced Ping/Push delivery modes can be fully exercised.

**Research flags for phases:**
- Phase 2: Needs careful API design to ensure the host can easily correlate asynchronous Push/WebSocket responses from the Authentication Device back to Lockspire's `auth_req_id`.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Oban is already an established standard in the Phoenix ecosystem for background jobs. |
| Features | HIGH | CIBA Core 1.0 is a stable specification with clear endpoint definitions. |
| Architecture | HIGH | The Elixir Behaviour pattern has already proven successful for separating Lockspire logic from Host logic (e.g., Device Flow, DCR). |
| Pitfalls | HIGH | The spec explicitly warns about unsolicited authentication requests and provides mechanisms (`user_code`) to mitigate them. |

## Gaps to Address

- Determining the exact schema requirements for the `login_hint_token` if Lockspire decides to validate it natively versus delegating the entire hint resolution to the host application.

# Research Summary: Lockspire Token Exchange (RFC 8693)

**Domain:** Embedded OAuth/OIDC Provider (Elixir/Phoenix)
**Researched:** 2026-05-XX
**Overall confidence:** HIGH

## Executive Summary

RFC 8693 defines the OAuth 2.0 Token Exchange grant type, which acts as a Security Token Service (STS) protocol. It enables microservices, API gateways, and service meshes to perform **impersonation** (acting as a user) and **delegation** (acting on behalf of a user). For an embedded Elixir provider like Lockspire, this milestone is crucial for integrating with modern, distributed backend architectures where a single frontend token should not be passed unmodified through deep service call chains.

The primary security challenge is preventing privilege escalation. By default, token exchange should be a "downscoping" operation. Any "upscoping" or audience pivoting must be strictly governed by host application business logic. To support this while remaining an unopinionated library, Lockspire must introduce a Behaviour (e.g., `Lockspire.TokenExchangeValidator`) that delegates the policy decision of *who can exchange what* to the host application, keeping Lockspire focused purely on protocol correctness and cryptographic validation.

## Key Findings

**Stack:** Standard Elixir/Phoenix ecosystem; relies on existing JWT (JOSE/Joken) capabilities to parse and mint nested `act` claims.
**Architecture:** Protocol validation happens in Lockspire, but the authorization policy is delegated to a host-implemented Elixir Behaviour (`Lockspire.TokenExchangeValidator`).
**Critical pitfall:** Privilege escalation via unauthorized scope expansion or audience pivoting, especially when confusing impersonation with delegation.

## Implications for Roadmap

Based on research, suggested phase structure for Token Exchange:

1. **Token Exchange Foundation** - Add support for the new `grant_type`, request/response parameters, and basic token-type URIs.
   - Addresses: Standard RFC 8693 request parsing and basic downscoping.
   - Avoids: Rushing into complex delegation before the core endpoints conform to the spec.

2. **Delegation & Impersonation (Host Behaviour)** - Introduce the `Lockspire.TokenExchangeValidator` Behaviour.
   - Addresses: Allowing the host application to securely govern audience pivoting and scope expansion.
   - Avoids: Hardcoding policy logic or RBAC into Lockspire.

3. **Advanced Claims (`act` and `may_act`)** - Support for complex delegation chains.
   - Addresses: Full compliance with the delegation profile of RFC 8693, providing an audit trail of actors in the `act` claim.

**Phase ordering rationale:**
- Protocol parsing and foundational structures must exist before defining the Elixir Behaviour boundary. Complex claims come last once the validation boundary is proven.

**Research flags for phases:**
- Phase 2: Needs careful API design for the Behaviour to ensure developer ergonomics are optimal for Phoenix teams.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new infrastructure needed, leverages existing Erlang/Elixir crypto. |
| Features | HIGH | RFC 8693 explicitly defines request/response shapes and token type URIs. |
| Architecture | HIGH | The Elixir Behaviour pattern is a proven method for decoupling protocol state from business logic in Lockspire. |
| Pitfalls | HIGH | Privilege escalation is a well-documented risk in token exchange literature. |

## Gaps to Address

- Determining the optimal data structure to pass to `Lockspire.TokenExchangeValidator` to give the host app enough context (e.g., original token claims, requested scopes, client info) without exposing internal Lockspire state.
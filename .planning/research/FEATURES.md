# Feature Landscape

**Domain:** OAuth 2.0 Device Authorization Grant (RFC 8628)
**Researched:** 2026-04-27

## Table Stakes

Features users expect. Missing = product feels incomplete or non-compliant.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `POST /device/code` | Initiates the flow. | Low | Must return `device_code`, `user_code`, `verification_uri`, `expires_in`, and `interval`. |
| `POST /token` Device Grant | The device must be able to poll this endpoint. | Medium | Must handle `authorization_pending`, `slow_down`, `expired_token`, and `access_denied`. |
| Host-owned Verification UI | User needs a place to enter the `user_code`. | Medium | Requires a seam similar to the existing consent flow. |
| Automatic Code Expiration | Security requirement. | Low | Codes should expire after 5-10 minutes. |

## Differentiators

Features that set product apart. Not expected, but valued for security and UX.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Base20 User Codes | Improves UX by removing ambiguous characters (O/0, I/1) and vowels (preventing bad words). | Low | e.g., `BCDFGHJKLMNPQRSTVWXZ` format `XXXX-XXXX`. |
| `verification_uri_complete` | Allows generating a QR code for the user to scan, pre-filling the code. | Low | Great for Smart TV integrations. |
| Contextual Consent Screen | Shows IP, location, and device type of the requesting client on the verify screen. | Medium | Critical defense against remote Device Code phishing. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-submit on `verification_uri_complete` | Highly vulnerable to remote phishing (one-click attack). | Pre-fill the input but require an explicit user action (button click) to confirm. |
| Overly long/complex `user_code` | Ruins UX for devices where users must type the code manually (e.g., TV remote). | Use an 8-character Base20 code separated by a dash. |
| Redis dependency for state | Violates embedded library constraint. | Use Ecto with efficient indexes and background cleanup. |

## Feature Dependencies

```
POST /device/code → Verification UI Seam → POST /token (Device Grant)
```

## MVP Recommendation

Prioritize:
1. `POST /device/code` generation with Base20.
2. Ecto schema for Device Authorization requests.
3. `POST /token` handling with `authorization_pending` and `slow_down`.
4. Host app integration generators for the `/verify` UI.

## Sources

- RFC 8628 Specifications
- OAuth 2.0 Security Best Current Practice (BCP)
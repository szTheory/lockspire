# Domain Pitfalls

**Domain:** OAuth 2.0 Device Authorization Grant (RFC 8628)
**Researched:** 2026-04-27

## Critical Pitfalls

Mistakes that cause rewrites, massive security breaches, or server outages.

### Pitfall 1: Device Code Phishing (Remote Phishing)
**What goes wrong:** An attacker runs a script to generate a `user_code`, then emails a link (`verification_uri_complete`) to a victim saying "Verify your account." The victim clicks the link, which auto-submits, and the attacker receives an access token on their machine.
**Why it happens:** The server treats a simple HTTP GET with a pre-filled code as sufficient authorization.
**Consequences:** Complete account takeover for the targeted application.
**Prevention:** 
1. The verification page MUST display context (e.g., "Device: Linux CLI, IP: 192.168.x.x").
2. The verification MUST require an explicit user action (e.g., clicking a "Confirm" button) via a `POST` request, even if the code was provided in the URL.

### Pitfall 2: User Code Brute-Forcing
**What goes wrong:** Attackers script requests against the `/verify` endpoint trying every combination of the 8-character `user_code` to hijack pending sessions.
**Why it happens:** `user_code` is explicitly designed to be low-entropy (short, easy to type). Without rate limits, the search space is small enough to guess within the 10-minute expiration window.
**Consequences:** Unauthorized access to legitimate user sessions.
**Prevention:**
1. Keep the `expires_in` window short (5-10 minutes max).
2. The host application MUST aggressively rate-limit the `/verify` endpoint by IP and by user session (e.g., max 5 failed attempts).

## Moderate Pitfalls

### Pitfall 3: The "Polling Storm"
**What goes wrong:** Badly written clients poll the `/token` endpoint 10 times a second instead of respecting the 5-second `interval`.
**Prevention:** Lockspire must track the `last_polled_at` timestamp in the database. If a request arrives too soon, respond with `400 Bad Request` and `error: slow_down`. Lockspire can also dynamically increase the interval in the response.

### Pitfall 4: Unfriendly User Codes
**What goes wrong:** Generating codes like `0O1Il8B`. Users can't tell the difference between zero and the letter O.
**Prevention:** Only use the Base20 character set (`BCDFGHJKLMNPQRSTVWXZ`). Separate it with a dash for readability (`XXXX-XXXX`).

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Code Generation | High entropy vs low entropy mix-up | Ensure `device_code` is securely random (e.g., 32+ bytes of entropy) while `user_code` is strictly Base20 formatted. |
| Host Integration | Host forgets to implement rate limiting | Provide clear security warnings in the generator output and documentation regarding brute-force risks on the verification UI. |

## Sources

- RFC 8628 Security Considerations (Section 5).
- Recent industry reports on Storm-2372 and Device Code Phishing campaigns.
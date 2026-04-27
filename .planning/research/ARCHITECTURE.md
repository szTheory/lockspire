# Architecture Patterns

**Domain:** OAuth 2.0 Device Authorization Grant (RFC 8628)
**Researched:** 2026-04-27

## Recommended Architecture

The Device Flow requires storing a pending state that is polled by the client and mutated by the user via a separate browser session.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `DeviceCodeEndpoint` | Handles `POST /device/code`. Generates codes. | `Storage` |
| `TokenEndpoint` | Handles `POST /token`. Polls state, enforces intervals, issues tokens. | `Storage`, `Protocol Core` |
| `VerificationUI` (Host) | Displays code entry form, requires user consent, mutates state to authorized. | `Storage` |
| `Storage` | Durable state in Ecto (e.g., `lockspire_device_requests`). | PostgreSQL |

### Data Flow

1. **Client** calls `POST /device/code`.
2. **Lockspire** generates a high-entropy `device_code` (internal) and low-entropy `user_code` (Base20, public). Stores in Ecto with status `pending`, timestamp, and `expires_in`. Returns payload to client.
3. **Client** begins polling `POST /token` every 5 seconds using `device_code`.
4. **Lockspire** checks DB. If `pending`, updates last polled timestamp (to enforce `slow_down`) and returns `400 authorization_pending`.
5. **User** navigates to `verification_uri` on their phone/PC, enters `user_code`.
6. **Host App** verifies the code via Lockspire API, displays consent screen with device context. User approves.
7. **Host App** signals Lockspire to update DB state to `authorized` and attaches `user_id`.
8. **Client** polls `POST /token`. Lockspire sees `authorized`, deletes the record, and issues Access/Refresh tokens.

## Patterns to Follow

### Pattern 1: Polling Backpressure
**What:** Enforcing the `interval` parameter.
**When:** During `POST /token` polling.
**Example:**
If the client polls before the interval has passed, the server MUST return `slow_down` and can increase the interval (e.g., add 5 seconds). This protects the database from polling storms.

### Pattern 2: Explicit Consent Confirmation
**What:** The user must explicitly click a button to authorize the device.
**When:** The user lands on the `verification_uri_complete`.
**Example:** Even if the URL pre-fills the `user_code`, the UI must show "A CLI tool is requesting access. Click Confirm to allow." This prevents "drive-by" phishing.

## Anti-Patterns to Avoid

### Anti-Pattern 1: In-Memory Only State
**What:** Storing `device_code` state in GenServers or ETS.
**Why bad:** If the Phoenix server restarts or deploys during a 10-minute device flow window, the flow breaks. It also fails in multi-node deployments without complex distribution.
**Instead:** Store in Ecto/Postgres. The DB load from a 5-second polling interval per client is negligible for Postgres.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Polling DB Load | Negligible | Needs index on `device_code` | May require tuning polling `interval` dynamically or partitioning the device request table. |
| Expired Codes | Negligible | Needs cron job | Ensure expired pending requests are aggressively pruned via an Ecto deletion worker to prevent table bloat. |

## Sources

- RFC 8628 Section 3.4 & 3.5
- Enterprise scale implementations (Auth0, Okta) architecture guidance.
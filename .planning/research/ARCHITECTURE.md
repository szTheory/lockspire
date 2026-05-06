# Architecture Patterns: CIBA

**Domain:** Embedded OAuth/OIDC Provider (Elixir/Phoenix)
**Researched:** 2026-05-05

## Recommended Architecture

CIBA in Lockspire requires a strict decoupling of the protocol state machine from the out-of-band communication channel, leveraging Elixir Behaviours and Oban for asynchronous operations.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Lockspire.Web.CIBAController` | Handles POST to `/bc-authorize`. Validates hints, scopes, and client auth. | Ecto, `Lockspire.Host` |
| `Lockspire.Domain.CIBARequest` | Database schema storing `auth_req_id`, expiration, requested scopes, and status (`pending`, `granted`, `denied`). | `Lockspire.Web.TokenController` |
| `Lockspire.Host` (Behaviour) | Exposes `ciba_notify/1` callback. The Host app implements this to trigger SMS/Push to the end-user. | External Notification Services (FCM/APNs) |
| `Lockspire.Workers.CIBADelivery` | Oban worker responsible for HTTP POSTs to the client's notification endpoint in Ping/Push modes. | External RPs |

### Data Flow

**1. Initiation (Poll Mode):**
- Client POSTs to `/bc-authorize` with `login_hint`.
- Lockspire validates request and inserts `CIBARequest` into DB.
- Lockspire asynchronously calls `Lockspire.Host.ciba_notify(request_details)`.
- Lockspire synchronously returns `auth_req_id` and `expires_in` to the Client.

**2. Out-of-Band Consent:**
- Host app receives `ciba_notify` and sends a push notification to the user's phone.
- User opens the Host app on their phone and clicks "Approve".
- Host app calls `Lockspire.CIBA.grant_consent(auth_req_id, account_id)`.
- Lockspire updates the `CIBARequest` status to `granted`.

**3. Token Exchange (Poll Mode):**
- Client polls `/token` with `grant_type=urn:openid:params:grant-type:ciba`.
- If status is `pending`, Lockspire returns `authorization_pending`.
- Once status is `granted`, Lockspire issues Access/ID Tokens and deletes/marks the `CIBARequest` as consumed.

**4. Ping/Push Delivery (Optional):**
- Upon the Host calling `grant_consent`, if the client requested Ping/Push, Lockspire enqueues an Oban job (`Lockspire.Workers.CIBADelivery`).
- The worker executes and securely POSTs the notification or tokens to the RP.

## Patterns to Follow

### Pattern 1: Oban for Webhook Delivery
**What:** Using Oban for guaranteed delivery of Ping/Push notifications.
**When:** Implementing the Ping or Push delivery modes.
**Example:**
```elixir
def grant_consent(auth_req_id, account_id) do
  # Update DB
  request = Repo.get_by!(CIBARequest, auth_req_id: auth_req_id)
  
  if request.delivery_mode in [:ping, :push] do
    %{auth_req_id: request.auth_req_id, mode: request.delivery_mode}
    |> Lockspire.Workers.CIBADelivery.new()
    |> Oban.insert()
  end
end
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Synchronous Notification Delivery
**What:** Blocking the `/bc-authorize` endpoint response while waiting for the Host app to send an SMS or Push notification.
**Why bad:** The CD (Consumption Device) will experience timeouts. The spec requires immediate return of the `auth_req_id`.
**Instead:** The Host callback (`ciba_notify`) must be fired asynchronously, or the Host app must implement it in a non-blocking way (e.g., casting a GenServer or queuing its own Oban job). Lockspire should enforce or heavily document this expectation.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| DB Polling | Simple indexed queries on `auth_req_id` are sufficient. | Standard database load. | High frequency polling could cause DB strain. Consider adding Phoenix.PubSub to notify the token endpoint polling process immediately when consent is granted, reducing empty DB queries. |
| Webhook Retries | Standard Oban configuration. | Moderate queue sizes. | Requires dedicated Oban queues for external webhooks to prevent slow RP endpoints from blocking internal Lockspire jobs. |

## Sources

- Elixir/Oban Best Practices
- CIBA Core 1.0 Specification

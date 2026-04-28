# Device Flow Host Guide

Lockspire's Phase 31 device verification slice is a generated, host-owned `/verify` seam. Lockspire owns the durable lookup and approval state transitions; your Phoenix app owns the browser route, session/auth pipeline, layout, copy, and abuse controls around that seam.

Lockspire does not provide built-in rate limiting for `GET /verify` or `POST /verify`. Treat the generated controller or LiveView as a starting point that must be wrapped in host-owned anti-phishing, trusted-IP, and throttling rules before you ship it.

## Host-owned verification seam

The supported shape is:

- `GET /verify` renders a code-entry page with optional prefill.
- `POST /verify` performs a lookup on the submitted code and shows a review step.
- Approve and deny are separate explicit mutations on an opaque verification handle, not on the raw code again.

Keep the seam narrow:

- Let Lockspire decide whether a request is pending, expired, or no longer active.
- Let the host app decide who is signed in, what session rules apply, and what product framing surrounds the page.
- Keep `GET /verify` side-effect free.

## Anti-phishing rules for `verification_uri_complete`

`verification_uri_complete` is prefill-only. In plain terms: verification_uri_complete is prefill-only. Use it to pre-populate the host-owned form and nothing more.

Required rules:

- `verification_uri_complete` is prefill-only and must never auto-submit, auto-look-up, auto-approve, or auto-advance the flow.
- Re-display the code on the review screen and ask the user to confirm it matches the code shown on the requesting device. The review step must re-display the code even when the form was prefilled from the query string.
- Require an explicit user action before any lookup or approval.
- Never approve on GET and never treat opening `verification_uri_complete` as proof of possession. In short: never approve on GET.
- Do not log raw verification query strings because they can contain a user-entered code.

## Rate limiting /verify

Apply rate limits to both `GET /verify` and `POST /verify`. The goal is to slow spray attacks and brute force without creating a code-existence oracle.

Recommended dimensions:

- Primary IP bucket: throttle all requests by trusted client IP for both `GET /verify` and `POST /verify`.
- Secondary `normalized_user_code` bucket: throttle repeated lookups against the same normalized code across IPs.
- Tighter `{normalized_user_code, ip}` failure bucket: increment only when a `POST /verify` lookup fails or the user submits a mismatched review step.
- Optional signed-in session or account bucket: once the user is authenticated, add a softer per-session or per-account limit to catch scripted retries behind shared networks.

Recommended behavior:

- Return HTTP `429` with a short `Retry-After`.
- Keep the user-facing copy neutral, for example "Try again in a moment."
- Preserve the same invalid-or-expired posture whether the code is unknown or expired.
- Increase `POST /verify` delay with stepped or exponential backoff on repeated failures in the same `{normalized_user_code, ip}` bucket.

Suggested starting points:

- `GET /verify`: enough headroom for normal refreshes, but still bounded by IP.
- `POST /verify`: stricter than GET because it is the brute-force surface.
- `{normalized_user_code, ip}` failures: the tightest bucket in the system.

Tune exact numbers to your traffic profile, but keep the relative strictness: IP broadest, `normalized_user_code` narrower, failure bucket tightest.

## Trusted IP and proxy handling

Rate-limit keys are only useful if the IP is trustworthy. Derive them from a trusted IP source.

- If Phoenix sits behind a reverse proxy or load balancer, rewrite `conn.remote_ip` using a trusted proxy configuration before you derive limiter keys.
- Trust only headers added by infrastructure you control.
- Do not key limits directly from arbitrary `x-forwarded-for` values.
- Make the IP extraction rule consistent across `GET /verify`, `POST /verify`, and any approve or deny endpoints.

If you already use `RemoteIp` or equivalent proxy-aware middleware, apply it before the verification seam.

## Normalize the code before keying limits

Use the same normalization rule everywhere before deriving limit keys: strip separators and whitespace + uppercase.

That should match Lockspire's durable lookup rule for `user_code` canonicalization:

- Input: `wdjb-mjht`
- `normalized_user_code`: `WDJBMJHT`

Never key rate limits from the raw query string or raw form value when cosmetic separators can vary.

## 429 and audit guidance

When you throttle:

- Send a short `Retry-After` header.
- Avoid telling the user whether the code exists.
- Keep logs and audit events keyed by fingerprints instead of raw codes.
- Redact query strings and form payloads that contain device verification codes.

A simple pattern is to hash `normalized_user_code` again for logs and store only the fingerprint plus the IP/session dimensions that tripped the limiter.

## Small custom limiter example

This Hammer-style example keeps the contract explicit without making Hammer a Lockspire dependency:

```elixir
defmodule MyAppWeb.VerifyRateLimit do
  import Plug.Conn

  @get_window_ms :timer.minutes(1)
  @post_window_ms :timer.minutes(5)

  def allow_lookup!(conn, user_code) do
    normalized_user_code =
      user_code
      |> String.replace(~r/[^[:alnum:]]/u, "")
      |> String.upcase()

    ip = format_ip(conn.remote_ip)

    with :ok <- hit("verify:get:#{ip}", 30, @get_window_ms),
         :ok <- hit("verify:post:#{ip}", 10, @post_window_ms),
         :ok <- hit("verify:code:#{normalized_user_code}", 5, @post_window_ms) do
      {:ok, normalized_user_code}
    else
      {:error, retry_after_seconds} -> {:error, retry_after_seconds}
    end
  end

  def register_failure(normalized_user_code, ip) do
    hit("verify:failure:#{normalized_user_code}:#{ip}", 3, @post_window_ms)
  end

  defp hit(bucket, limit, window_ms) do
    case Hammer.check_rate(bucket, window_ms, limit) do
      {:allow, _count} -> :ok
      {:deny, retry_after_ms} -> {:error, max(1, div(retry_after_ms, 1_000))}
    end
  end

  defp format_ip(ip), do: :inet.ntoa(ip) |> to_string()
end
```

Pair the limiter with neutral `429` responses and a review step that still re-displays the code before approve or deny.

## Router-layer example

This PlugAttack-style example blocks obvious spray traffic before the request reaches the host verification controller:

```elixir
defmodule MyAppWeb.VerifyAttack do
  use PlugAttack

  rule "throttle GET /verify by ip", conn do
    if conn.method == "GET" and conn.request_path == "/verify" do
      throttle("verify:get:#{format_ip(conn.remote_ip)}", period: 60_000, limit: 30)
    end
  end

  rule "throttle POST /verify by ip", conn do
    if conn.method == "POST" and conn.request_path == "/verify" do
      throttle("verify:post:#{format_ip(conn.remote_ip)}", period: 300_000, limit: 10)
    end
  end

  defp format_ip(ip), do: :inet.ntoa(ip) |> to_string()
end
```

Use app-level code in the controller or LiveView for the tighter `normalized_user_code` and `{normalized_user_code, ip}` buckets, because those depend on the submitted code after normalization.

## Ship checklist

Before you expose `/verify` publicly:

- Confirm `verification_uri_complete` is prefill-only.
- Confirm the review step re-displays the code and requires explicit confirmation.
- Confirm `GET /verify` has no approval semantics.
- Confirm trusted proxy IP rewriting runs before limiter keys are derived.
- Confirm `normalized_user_code` keys strip separators and whitespace + uppercase.
- Confirm `429` responses include `Retry-After` and neutral copy.
- Confirm logs and audit trails use fingerprints instead of raw codes.

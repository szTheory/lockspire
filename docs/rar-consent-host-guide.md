# Custom RAR Consent In A Host Phoenix App

Lockspire validates and persists `authorization_details`, but the host app owns the consent UX. This guide shows the narrow supported path for custom RAR consent after `mix lockspire.install`: edit the generated host file, render structural `authorization_details`, and keep product semantics in the host.

## Generated files to open

After `mix lockspire.install`, start with these host-owned files:

- `lib/your_app_web/live/lockspire_consent_live.ex`
- `lib/your_app/lockspire/interaction_handler.ex`

`lockspire_consent_live.ex` is where the host renders approval UX. `interaction_handler.ex` stays responsible for any host policy you apply before the final approval or denial redirect completes.

Lockspire continues to own:

- protocol validity for the interaction
- durable storage of approved `authorization_details`
- the final `POST /lockspire/interactions/:interaction_id/complete` redirect contract

The host app continues to own:

- wording and layout
- branding
- domain semantics
- any product-specific policy checks before approval

## Structural data available to the host

The repo-owned reference consent surface already exposes structural RAR data to the UI:

- `authorization_details`
- `authorization_detail_types`

Treat that shape as the contract. Render semantic copy from the normalized payload you receive; do not introduce a Lockspire-side renderer registry or behavior callback.

## Example: `payment_initiation`

This example is illustrative only. Adapt field names, currency handling, risk checks, and customer-facing copy to your domain.

Update the generated `lib/your_app_web/live/lockspire_consent_live.ex` with a host helper:

```elixir
defmodule YourAppWeb.LockspireConsentLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <section class="host-consent-shell">
      <%= if @authorization_details != [] do %>
        <section class="host-rar-consent">
          <h2>Requested transaction details</h2>

          <%= for detail <- @authorization_details do %>
            <.rar_detail detail={detail} />
          <% end %>
        </section>
      <% end %>

      <form action={finalize_path(@interaction_id)} method="post">
        <input type="hidden" name="decision" value="approve" />
        <button type="submit">Approve access</button>
      </form>
    </section>
    """
  end

  attr :detail, :map, required: true

  defp rar_detail(%{ "type" => "payment_initiation" } = assigns) do
    ~H"""
    <article class="rar-detail">
      <h3>Payment initiation</h3>
      <p>
        Pay {amount_text(@detail)} to {creditor_name(@detail)}.
      </p>
      <p :if={remittance_information(@detail)}>
        Reference: {remittance_information(@detail)}
      </p>
    </article>
    """
  end

  defp rar_detail(assigns) do
    ~H"""
    <article class="rar-detail">
      <h3>{@detail["type"] || "authorization_detail"}</h3>
      <pre>{Jason.encode_to_iodata!(@detail, pretty: true)}</pre>
    </article>
    """
  end

  defp amount_text(detail) do
    amount = get_in(detail, ["instructedAmount", "amount"]) || "unknown"
    currency = get_in(detail, ["instructedAmount", "currency"]) || ""
    String.trim("#{amount} #{currency}")
  end

  defp creditor_name(detail) do
    get_in(detail, ["creditorName"]) || "the requested recipient"
  end

  defp remittance_information(detail) do
    detail["remittanceInformation"]
  end
end
```

That pattern keeps the contract clean:

- Lockspire owns structural validity.
- The host translates structure into product copy.
- Unknown types still render safely without blocking the approval screen.

## Approval form contract

Keep the approval and denial form targets pointed at Lockspire's protocol-owned completion endpoint:

```elixir
defp finalize_path(interaction_id) do
  "/lockspire/interactions/#{interaction_id}/complete"
end
```

Do not replace that endpoint with a host-owned redirect target. If you need more product policy, compute it in the host LiveView or host interaction handler before submitting the final Lockspire completion form.

## Verification

Repo proof for this seam already exists:

- `test/integration/phase57_rar_introspection_verification_e2e_test.exs`
- `test/lockspire/web/live/consent_live_test.exs`
- `test/lockspire/release_readiness_contract_test.exs`

Host-app verification should add at least:

1. A LiveView test that renders your generated `lockspire_consent_live.ex` with representative `authorization_details`.
2. A happy-path approval test that submits the final completion form.
3. A fallback rendering test for unknown RAR types so future validator additions do not break the screen.

If the host supports remembered consent, also verify that semantic copy stays aligned when the same normalized RAR payload is reused from stored consent.

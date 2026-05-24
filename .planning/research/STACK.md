# v1.23 Research: Stack

## Scope

Add DCR and RFC 7592 support for existing logout propagation metadata:

- `backchannel_logout_uri`
- `backchannel_logout_session_required`
- `frontchannel_logout_uri`
- `frontchannel_logout_session_required`

## Existing Stack Reuse

- Elixir/Phoenix request handling already exists for `POST /register` and `GET|PUT|DELETE /register/:client_id`.
- Ecto storage already includes the four logout propagation fields on `Lockspire.Domain.Client` and `Lockspire.Storage.Ecto.ClientRecord`.
- Existing logout propagation runtime already uses Oban plus Req for durable back-channel delivery and iframe rendering for front-channel best-effort cleanup.
- Existing admin surfaces already separate post-logout redirect URIs from logout propagation settings.

## Standards Inputs

- RFC 7591 / RFC 7592 remain the registration and management envelope.
- OpenID Connect Back-Channel Logout 1.0 defines `backchannel_logout_uri` and `backchannel_logout_session_required`.
- OpenID Connect Front-Channel Logout 1.0 defines `frontchannel_logout_uri` and `frontchannel_logout_session_required`.

## Recommended Stack Changes

- No new runtime dependency is needed.
- Extend the existing DCR intake and management validator instead of creating a logout-specific pipeline.
- Reuse existing URI validation conventions already applied to redirect and logout-related metadata elsewhere in Lockspire.
- Reuse existing JSON rendering and E2E test lanes for registration read/update responses.

## What Not To Add

- No federation metadata ingestion.
- No new delivery mechanism beyond the shipped back-channel and front-channel implementations.
- No new hosted UI or external compatibility lane.
- No remote proof claims for front-channel success.

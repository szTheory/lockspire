defmodule Lockspire.Diagnostics.RemoteJwksTest do
  use ExUnit.Case, async: true

  alias Lockspire.Diagnostics.RemoteJwks

  test "classifies fetch failures with bounded reactive posture facts" do
    incident =
      RemoteJwks.classify_fetch_error(
        :private_key_jwt,
        {:jwks_fetch_failed, {:http_status, 503}},
        cached_entry_present?: true,
        forced_refresh_attempted?: true
      )

    assert incident.class == :remote_jwks_fetch_failed
    assert incident.consumer == :private_key_jwt
    assert incident.stage == :network
    assert incident.fetch_status == 503
    assert incident.cached_entry_present? == true
    assert incident.forced_refresh_attempted? == true
    assert incident.bounded_reactive? == true
    assert incident.proactive_readiness? == false
    assert incident.preserves_last_known_good_cache? == true
    assert incident.current_request_fails_closed? == true
    assert incident.remediation =~ "HTTP status 503"
  end

  test "classifies invalid jwks content separately from transport failures" do
    incident =
      RemoteJwks.classify_fetch_error(
        :jarm,
        {:jwks_fetch_failed, :invalid_format},
        forced_refresh_attempted?: true
      )

    assert incident.class == :remote_jwks_invalid
    assert incident.stage == :parse
    assert incident.subreason == :invalid_format
    assert incident.remediation =~ "Publish a valid JWKS document"
  end

  test "classifies post-refresh missing key incidents" do
    incident =
      RemoteJwks.key_unavailable(
        :private_key_jwt,
        cached_entry_present?: true,
        forced_refresh_attempted?: true,
        requested_kid_present_in_cached_set?: false
      )

    assert incident.class == :remote_jwks_key_unavailable
    assert incident.stage == :select_key
    assert incident.subreason == :post_refresh_key_still_missing
    assert incident.requested_kid_present_in_cached_set? == false
    assert incident.remediation =~ "Publish the requested key"
  end

  test "classifies post-refresh signature failures" do
    incident =
      RemoteJwks.signature_invalid(
        :private_key_jwt,
        cached_entry_present?: true,
        forced_refresh_attempted?: true,
        requested_kid_present_in_cached_set?: true
      )

    assert incident.class == :remote_jwks_signature_invalid
    assert incident.stage == :verify_signature
    assert incident.subreason == :post_refresh_signature_invalid

    assert RemoteJwks.metadata(incident)[:remote_jwks_incident_class] ==
             :remote_jwks_signature_invalid
  end
end

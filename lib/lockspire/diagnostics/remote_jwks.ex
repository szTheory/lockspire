defmodule Lockspire.Diagnostics.RemoteJwks do
  @moduledoc """
  Shared remote-JWKS incident classification for support-facing diagnostics.
  """

  alias Lockspire.JwksFetcher

  @typedoc """
  Stable operator-facing incident classes for remote `jwks_uri` failures.
  """
  @type incident_class ::
          :remote_jwks_fetch_failed
          | :remote_jwks_invalid
          | :remote_jwks_key_unavailable
          | :remote_jwks_signature_invalid

  @type consumer :: :private_key_jwt | :jarm

  @type t :: %__MODULE__{
          class: incident_class(),
          consumer: consumer(),
          jwks_source: :jwks_uri,
          stage: atom(),
          subreason: atom() | nil,
          fetch_status: integer() | nil,
          target_safety_reason: atom() | nil,
          cached_entry_present?: boolean() | nil,
          forced_refresh_attempted?: boolean(),
          requested_kid_present_in_cached_set?: boolean() | nil,
          bounded_reactive?: true,
          proactive_readiness?: false,
          preserves_last_known_good_cache?: boolean(),
          current_request_fails_closed?: true,
          remediation: String.t()
        }

  defstruct [
    :class,
    :consumer,
    :stage,
    :subreason,
    :fetch_status,
    :target_safety_reason,
    :cached_entry_present?,
    :forced_refresh_attempted?,
    :requested_kid_present_in_cached_set?,
    :remediation,
    jwks_source: :jwks_uri,
    bounded_reactive?: true,
    proactive_readiness?: false,
    preserves_last_known_good_cache?: true,
    current_request_fails_closed?: true
  ]

  @spec classify_fetch_error(consumer(), {:jwks_fetch_failed, term()}, keyword()) :: t()
  def classify_fetch_error(consumer, {:jwks_fetch_failed, _reason} = error, opts \\ [])
      when consumer in [:private_key_jwt, :jarm] and is_list(opts) do
    details = JwksFetcher.error_details(error)

    %__MODULE__{
      class: fetch_class(details),
      consumer: consumer,
      stage: Map.fetch!(details, :stage),
      subreason: Map.get(details, :subreason),
      fetch_status: Map.get(details, :fetch_status),
      target_safety_reason: Map.get(details, :target_safety_reason),
      cached_entry_present?: Keyword.get(opts, :cached_entry_present?),
      forced_refresh_attempted?: Keyword.get(opts, :forced_refresh_attempted?, false),
      requested_kid_present_in_cached_set?:
        Keyword.get(opts, :requested_kid_present_in_cached_set?),
      remediation: fetch_remediation(details)
    }
  end

  @spec key_unavailable(consumer(), keyword()) :: t()
  def key_unavailable(consumer, opts \\ [])
      when consumer in [:private_key_jwt, :jarm] and is_list(opts) do
    requested_kid_present? = Keyword.get(opts, :requested_kid_present_in_cached_set?)
    forced_refresh_attempted? = Keyword.get(opts, :forced_refresh_attempted?, false)

    %__MODULE__{
      class: :remote_jwks_key_unavailable,
      consumer: consumer,
      stage: :select_key,
      subreason:
        if(forced_refresh_attempted?,
          do: :post_refresh_key_still_missing,
          else: :requested_key_missing
        ),
      cached_entry_present?: Keyword.get(opts, :cached_entry_present?),
      forced_refresh_attempted?: forced_refresh_attempted?,
      requested_kid_present_in_cached_set?: requested_kid_present?,
      remediation: key_unavailable_remediation(requested_kid_present?)
    }
  end

  @spec signature_invalid(consumer(), keyword()) :: t()
  def signature_invalid(consumer, opts \\ [])
      when consumer in [:private_key_jwt, :jarm] and is_list(opts) do
    forced_refresh_attempted? = Keyword.get(opts, :forced_refresh_attempted?, false)

    %__MODULE__{
      class: :remote_jwks_signature_invalid,
      consumer: consumer,
      stage: :verify_signature,
      subreason:
        if(forced_refresh_attempted?,
          do: :post_refresh_signature_invalid,
          else: :signature_invalid
        ),
      cached_entry_present?: Keyword.get(opts, :cached_entry_present?),
      forced_refresh_attempted?: forced_refresh_attempted?,
      requested_kid_present_in_cached_set?:
        Keyword.get(opts, :requested_kid_present_in_cached_set?),
      remediation:
        "Confirm the client assertion or JARM decryption key matches the published JWKS and retry with one fresh JWT after the remote document is corrected."
    }
  end

  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{} = incident) do
    %{
      remote_jwks_incident_class: incident.class,
      remote_jwks_consumer: incident.consumer,
      remote_jwks_stage: incident.stage,
      remote_jwks_subreason: incident.subreason,
      remote_jwks_fetch_status: incident.fetch_status,
      remote_jwks_target_safety_reason: incident.target_safety_reason,
      remote_jwks_cached_entry_present?: incident.cached_entry_present?,
      remote_jwks_forced_refresh_attempted?: incident.forced_refresh_attempted?,
      remote_jwks_requested_kid_present_in_cached_set?:
        incident.requested_kid_present_in_cached_set?,
      remote_jwks_bounded_reactive?: incident.bounded_reactive?,
      remote_jwks_proactive_readiness?: incident.proactive_readiness?,
      remote_jwks_preserves_last_known_good_cache?: incident.preserves_last_known_good_cache?,
      remote_jwks_current_request_fails_closed?: incident.current_request_fails_closed?,
      remote_jwks_remediation: incident.remediation
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp fetch_class(%{stage: :parse}), do: :remote_jwks_invalid
  defp fetch_class(_details), do: :remote_jwks_fetch_failed

  defp fetch_remediation(%{stage: :validate_target, target_safety_reason: reason})
       when not is_nil(reason) do
    "Fix the remote JWKS target safety issue (#{reason}) or move to a stable public HTTPS JWKS endpoint before retrying with one fresh JWT."
  end

  defp fetch_remediation(%{stage: :validate_target}) do
    "Fix the remote JWKS URI so Lockspire can reach a stable public HTTPS endpoint, then retry with one fresh JWT."
  end

  defp fetch_remediation(%{stage: :network, fetch_status: status}) when is_integer(status) do
    "Check the remote JWKS endpoint availability and HTTP status #{status}, restore a valid JWKS response, then retry with one fresh JWT."
  end

  defp fetch_remediation(%{stage: :network, subreason: :timeout}) do
    "Check remote JWKS reachability and latency, restore a timely HTTPS response, then retry with one fresh JWT."
  end

  defp fetch_remediation(%{stage: :network}) do
    "Check remote JWKS reachability and transport health, restore a valid HTTPS response, then retry with one fresh JWT."
  end

  defp fetch_remediation(%{stage: :parse}) do
    "Publish a valid JWKS document with overlapping old and new keys, let one forced refresh converge, then retry with one fresh JWT."
  end

  defp fetch_remediation(%{stage: :cache}) do
    "Check the Lockspire JWKS cache health, then retry with one fresh JWT after the remote JWKS endpoint is confirmed healthy."
  end

  defp key_unavailable_remediation(false) do
    "Publish the requested key alongside the previous key at the JWKS URI, keep both keys available during rollover, then retry with one fresh JWT."
  end

  defp key_unavailable_remediation(_requested_kid_present?) do
    "Confirm overlap-based key rollover and keep both old and new keys published until Lockspire can refresh and verify a fresh JWT."
  end
end

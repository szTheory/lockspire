defmodule Lockspire.Diagnostics.RemoteJwks do
  @moduledoc """
  Shared remote-JWKS incident classification for support-facing diagnostics.
  """

  alias Lockspire.Domain.Client
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

  @type summary_status :: :supported | :incident

  @type summary :: %{
          applicable?: boolean(),
          status: summary_status() | :not_applicable,
          client_id: String.t() | nil,
          mode: :remote_jwks_uri | :not_configured,
          incident: t() | nil,
          headline: String.t(),
          detail: String.t(),
          next_step: String.t(),
          ownership: String.t(),
          command_hint: String.t() | nil
        }

  @incident_classes ~w(
    remote_jwks_fetch_failed
    remote_jwks_invalid
    remote_jwks_key_unavailable
    remote_jwks_signature_invalid
  )a
  @consumers ~w(private_key_jwt jarm)a
  @stages ~w(validate_target network parse cache select_key verify_signature)a
  @subreasons ~w(
    unsafe_target
    https_required
    invalid_uri
    resolution_failed
    http_status
    timeout
    redirect_disallowed
    transport_error
    payload_too_large
    invalid_format
    cache_error
    requested_key_missing
    post_refresh_key_still_missing
    signature_invalid
    post_refresh_signature_invalid
  )a

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

  @spec snapshot(t()) :: map()
  def snapshot(%__MODULE__{} = incident) do
    %{
      class: incident.class,
      consumer: incident.consumer,
      stage: incident.stage,
      subreason: incident.subreason,
      fetch_status: incident.fetch_status,
      target_safety_reason: incident.target_safety_reason,
      cached_entry_present?: incident.cached_entry_present?,
      forced_refresh_attempted?: incident.forced_refresh_attempted?,
      requested_kid_present_in_cached_set?: incident.requested_kid_present_in_cached_set?,
      remediation: incident.remediation
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  @spec summarize_client(Client.t()) :: summary()
  def summarize_client(%Client{} = client) do
    if remote_jwks_client?(client) do
      incident = incident_from_client_metadata(client)

      %{
        applicable?: true,
        status: if(is_nil(incident), do: :supported, else: :incident),
        client_id: client.client_id,
        mode: :remote_jwks_uri,
        incident: incident,
        headline: summary_headline(incident),
        detail: summary_detail(incident),
        next_step: summary_next_step(incident),
        ownership: ownership_note(),
        command_hint: doctor_command(client.client_id)
      }
    else
      %{
        applicable?: false,
        status: :not_applicable,
        client_id: client.client_id,
        mode: :not_configured,
        incident: nil,
        headline: "Remote JWKS incident diagnosis is not active for this client.",
        detail:
          "This client is not using a remote jwks_uri on the shipped direct-client surface.",
        next_step:
          "Use `mix lockspire.verify` for install wiring checks or inspect the inline jwks registration instead.",
        ownership: ownership_note(),
        command_hint: nil
      }
    end
  end

  @spec ownership_note() :: String.t()
  def ownership_note do
    "Lockspire owns the guarded fetch, cache, refresh, and verify path. The host operator diagnoses incidents here and coordinates with the client integrator, who owns the JWKS endpoint and overlap-based key rollover."
  end

  @spec install_boundary_note() :: String.t()
  def install_boundary_note do
    "`mix lockspire.verify` remains the install and onboarding diagnostic. Use this doctor surface for runtime remote JWKS incidents."
  end

  @spec doctor_command(String.t()) :: String.t()
  def doctor_command(client_id) when is_binary(client_id) do
    "mix lockspire.doctor remote-jwks --client #{client_id}"
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

  defp remote_jwks_client?(%Client{jwks_uri: jwks_uri} = client)
       when is_binary(jwks_uri) and jwks_uri != "" do
    client.token_endpoint_auth_method == :private_key_jwt or
      not is_nil(client.authorization_encrypted_response_alg)
  end

  defp remote_jwks_client?(_client), do: false

  defp incident_from_client_metadata(%Client{metadata: metadata} = client)
       when is_map(metadata) do
    metadata
    |> Map.get("remote_jwks_diagnostic", Map.get(metadata, :remote_jwks_diagnostic))
    |> build_incident_from_map(default_consumer(client))
  end

  defp incident_from_client_metadata(_client), do: nil

  defp build_incident_from_map(nil, _default_consumer), do: nil

  defp build_incident_from_map(raw, default_consumer) when is_map(raw) do
    with {:ok, class} <- atom_field(raw, [:class], @incident_classes),
         {:ok, stage} <- atom_field(raw, [:stage], @stages) do
      %__MODULE__{
        class: class,
        consumer: atom_value(raw, [:consumer], @consumers, default_consumer),
        stage: stage,
        subreason: atom_value(raw, [:subreason], @subreasons, nil),
        fetch_status: integer_field(raw, [:fetch_status]),
        target_safety_reason: atom_value(raw, [:target_safety_reason], @subreasons, nil),
        cached_entry_present?: boolean_field(raw, [:cached_entry_present?]),
        forced_refresh_attempted?: boolean_field(raw, [:forced_refresh_attempted?], false),
        requested_kid_present_in_cached_set?:
          boolean_field(raw, [:requested_kid_present_in_cached_set?]),
        remediation: string_field(raw, [:remediation]) || remediation_for(class, raw)
      }
    else
      :error -> nil
    end
  end

  defp build_incident_from_map(_raw, _default_consumer), do: nil

  defp atom_field(raw, keys, allowed, default \\ :error) do
    case value_for(raw, keys) do
      nil when default != :error ->
        default

      value ->
        case normalize_atom(value, allowed) do
          {:ok, atom} -> {:ok, atom}
          :error when default != :error -> default
          :error -> :error
        end
    end
  end

  defp atom_value(raw, keys, allowed, default) do
    case atom_field(raw, keys, allowed, default) do
      {:ok, atom} -> atom
      atom when is_atom(atom) -> atom
      _other -> default
    end
  end

  defp integer_field(raw, keys) do
    case value_for(raw, keys) do
      value when is_integer(value) ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int, ""} -> int
          _other -> nil
        end

      _other ->
        nil
    end
  end

  defp boolean_field(raw, keys, default \\ nil) do
    case value_for(raw, keys) do
      value when is_boolean(value) -> value
      "true" -> true
      "false" -> false
      nil -> default
      _other -> default
    end
  end

  defp string_field(raw, keys) do
    case value_for(raw, keys) do
      value when is_binary(value) and value != "" -> value
      _other -> nil
    end
  end

  defp value_for(raw, [key]) do
    Map.get(raw, key, Map.get(raw, Atom.to_string(key)))
  end

  defp normalize_atom(value, allowed) when is_atom(value) do
    if value in allowed, do: {:ok, value}, else: :error
  end

  defp normalize_atom(value, allowed) when is_binary(value) do
    case Enum.find(allowed, &(Atom.to_string(&1) == value)) do
      nil -> :error
      atom -> {:ok, atom}
    end
  end

  defp normalize_atom(_value, _allowed), do: :error

  defp default_consumer(%Client{token_endpoint_auth_method: :private_key_jwt}),
    do: :private_key_jwt

  defp default_consumer(_client), do: :jarm

  defp remediation_for(class, raw) do
    case class do
      :remote_jwks_fetch_failed ->
        classify_fetch_error(:private_key_jwt, {:jwks_fetch_failed, infer_fetch_reason(raw)}).remediation

      :remote_jwks_invalid ->
        classify_fetch_error(:private_key_jwt, {:jwks_fetch_failed, :invalid_format}).remediation

      :remote_jwks_key_unavailable ->
        key_unavailable(:private_key_jwt,
          requested_kid_present_in_cached_set?:
            boolean_field(raw, [:requested_kid_present_in_cached_set?]),
          forced_refresh_attempted?: boolean_field(raw, [:forced_refresh_attempted?], false)
        ).remediation

      :remote_jwks_signature_invalid ->
        signature_invalid(:private_key_jwt,
          forced_refresh_attempted?: boolean_field(raw, [:forced_refresh_attempted?], false),
          requested_kid_present_in_cached_set?:
            boolean_field(raw, [:requested_kid_present_in_cached_set?])
        ).remediation
    end
  end

  defp infer_fetch_reason(raw) do
    case atom_field(raw, [:stage], @stages) do
      {:ok, :parse} ->
        :invalid_format

      {:ok, :validate_target} ->
        case atom_value(raw, [:target_safety_reason], @subreasons, nil) do
          nil -> :https_required
          reason -> {:unsafe_target, reason}
        end

      {:ok, :network} ->
        case integer_field(raw, [:fetch_status]) do
          nil ->
            case atom_field(raw, [:subreason], @subreasons, :transport_error) do
              {:ok, reason} -> reason
              reason when is_atom(reason) -> reason
            end

          status ->
            {:http_status, status}
        end

      {:ok, :cache} ->
        :cache_error

      _other ->
        :transport_error
    end
  end

  defp summary_headline(nil),
    do: "Remote JWKS is configured with bounded reactive rollover support."

  defp summary_headline(%__MODULE__{class: class}) do
    "Remote JWKS incident: #{class}"
  end

  defp summary_detail(nil) do
    "Lockspire caches jwks_uri material, forces one refresh on stale or unknown-key mismatch, preserves the last known good cache on refresh failure, and fails the current request closed."
  end

  defp summary_detail(%__MODULE__{} = incident) do
    "Stage=#{incident.stage} subreason=#{incident.subreason || "n/a"} forced_refresh=#{incident.forced_refresh_attempted?} cache_preserved=#{incident.preserves_last_known_good_cache?}"
  end

  defp summary_next_step(nil) do
    "If rotation is planned, publish the new key before first use, keep the previous key available during rollover, and use one fresh JWT after the remote JWKS endpoint is updated."
  end

  defp summary_next_step(%__MODULE__{remediation: remediation}), do: remediation
end

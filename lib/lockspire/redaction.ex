defmodule Lockspire.Redaction do
  @moduledoc """
  Shared redaction helpers for telemetry and durable audit metadata.
  """

  @type metadata :: map()

  @telemetry_drop_keys MapSet.new([
                         :access_token,
                         :authorization,
                         :authorization_code,
                         :authorization_header,
                         :client_secret,
                         :client_secret_hash,
                         :client_assertion,
                         :iat,
                         :iat_secret,
                         :initial_access_token,
                         :jwks,
                         :jwks_body,
                         :jwt_claims,
                         :jwt_header,
                         :logout_response_body,
                         :logout_token,
                         :raw_logout_response,
                         :raw_logout_token,
                         :code,
                         :code_challenge,
                         :code_verifier,
                         :params,
                         :payload,
                         :raw_payload,
                         :raw_request,
                         :raw_response,
                         :refresh_token,
                         :rat,
                         :registration_access_token,
                         :request,
                         :request_body,
                         :response,
                         :response_body,
                         :state,
                         :token,
                         :token_hash,
                         "access_token",
                         "authorization",
                         "authorization_code",
                         "authorization_header",
                         "client_secret",
                         "client_secret_hash",
                         "client_assertion",
                         "iat",
                         "iat_secret",
                         "initial_access_token",
                         "jwks",
                         "jwks_body",
                         "jwt_claims",
                         "jwt_header",
                         "logout_response_body",
                         "logout_token",
                         "raw_logout_response",
                         "raw_logout_token",
                         "code",
                         "code_challenge",
                         "code_verifier",
                         "params",
                         "payload",
                         "raw_payload",
                         "raw_request",
                         "raw_response",
                         "refresh_token",
                         "rat",
                         "registration_access_token",
                         "request",
                         "request_body",
                         "response",
                         "response_body",
                         "state",
                         "token",
                         "token_hash"
                       ])

  @audit_drop_keys MapSet.new([
                     :access_token,
                     :authorization,
                     :authorization_code,
                     :authorization_header,
                     :client_secret,
                     :client_secret_hash,
                     :client_assertion,
                     :iat,
                     :iat_secret,
                     :initial_access_token,
                     :jwks,
                     :jwks_body,
                     :jwt_claims,
                     :jwt_header,
                     :logout_response_body,
                     :logout_token,
                     :raw_logout_response,
                     :raw_logout_token,
                     :code,
                     :code_challenge,
                     :code_verifier,
                     :params,
                     :payload,
                     :raw_payload,
                     :raw_request,
                     :raw_response,
                     :refresh_token,
                     :rat,
                     :registration_access_token,
                     :request,
                     :request_body,
                     :response,
                     :response_body,
                     :state,
                     :token,
                     :token_hash,
                     "access_token",
                     "authorization",
                     "authorization_code",
                     "authorization_header",
                     "client_secret",
                     "client_secret_hash",
                     "client_assertion",
                     "iat",
                     "iat_secret",
                     "initial_access_token",
                     "jwks",
                     "jwks_body",
                     "jwt_claims",
                     "jwt_header",
                     "logout_response_body",
                     "logout_token",
                     "raw_logout_response",
                     "raw_logout_token",
                     "code",
                     "code_challenge",
                     "code_verifier",
                     "params",
                     "payload",
                     "raw_payload",
                     "raw_request",
                     "raw_response",
                     "refresh_token",
                     "rat",
                     "registration_access_token",
                     "request",
                     "request_body",
                     "response",
                     "response_body",
                     "state",
                     "token",
                     "token_hash"
                   ])

  @telemetry_handle_keys %{
    :family_id => :family,
    "family_id" => :family
  }

  @spec for_telemetry(metadata()) :: metadata()
  def for_telemetry(metadata) when is_map(metadata) do
    metadata
    |> Enum.reduce(%{}, &reduce_telemetry_metadata/2)
  end

  def for_telemetry(_metadata), do: %{}

  @spec for_audit(metadata()) :: metadata()
  def for_audit(metadata) when is_map(metadata) do
    metadata
    |> Enum.reduce(%{}, &reduce_audit_metadata/2)
  end

  def for_audit(_metadata), do: %{}

  @spec handle(atom(), term()) :: String.t()
  def handle(type, value) when is_atom(type) do
    encoded =
      value
      |> normalize_scalar()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 12)

    "#{type}_#{encoded}"
  end

  defp sanitize_value(nil, _surface), do: :drop
  defp sanitize_value(%DateTime{} = value, _surface), do: value
  defp sanitize_value(%NaiveDateTime{} = value, _surface), do: value
  defp sanitize_value(%Date{} = value, _surface), do: value
  defp sanitize_value(%Time{} = value, _surface), do: value

  defp sanitize_value(%_{} = value, _surface) do
    inspect(value)
  end

  defp sanitize_value(value, surface) when is_map(value) do
    sanitized =
      case surface do
        :telemetry -> for_telemetry(value)
        :audit -> for_audit(value)
      end

    if sanitized == %{}, do: :drop, else: sanitized
  end

  defp sanitize_value(value, surface) when is_list(value) do
    sanitized =
      value
      |> Enum.map(&sanitize_value(&1, surface))
      |> Enum.reject(&(&1 == :drop))

    if sanitized == [], do: :drop, else: sanitized
  end

  defp sanitize_value(value, _surface), do: value

  defp reduce_telemetry_metadata({key, value}, acc) do
    case telemetry_drop_result(key, acc) do
      :continue ->
        case Map.get(@telemetry_handle_keys, key) do
          nil -> put_sanitized_value(acc, key, value, :telemetry)
          handle_type -> put_handled_value(acc, key, value, handle_type)
        end

      filtered_acc ->
        filtered_acc
    end
  end

  defp reduce_audit_metadata({key, value}, acc) do
    case audit_drop_result(key, acc) do
      :continue -> put_sanitized_value(acc, key, value, :audit)
      filtered_acc -> filtered_acc
    end
  end

  defp telemetry_drop_result(key, acc) do
    if MapSet.member?(@telemetry_drop_keys, key), do: acc, else: :continue
  end

  defp audit_drop_result(key, acc) do
    if MapSet.member?(@audit_drop_keys, key), do: acc, else: :continue
  end

  defp put_handled_value(acc, key, value, handle_type) do
    Map.put(acc, handle_key(key), handle(handle_type, value))
  end

  defp put_sanitized_value(acc, key, value, surface) do
    case sanitize_value(value, surface) do
      :drop -> acc
      sanitized -> Map.put(acc, key, sanitized)
    end
  end

  defp normalize_scalar(value) when is_binary(value), do: value
  defp normalize_scalar(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_scalar(value) when is_integer(value), do: Integer.to_string(value)
  defp normalize_scalar(value) when is_float(value), do: :erlang.float_to_binary(value)
  defp normalize_scalar(value) when is_boolean(value), do: to_string(value)
  defp normalize_scalar(nil), do: nil
  defp normalize_scalar(value), do: inspect(value)

  defp handle_key(key) when is_atom(key), do: :"#{key_base(key)}_handle"
  defp handle_key(key) when is_binary(key), do: "#{key_base(key)}_handle"

  defp key_base(key) when is_atom(key),
    do: key |> Atom.to_string() |> String.replace_suffix("_id", "")

  defp key_base(key) when is_binary(key), do: String.replace_suffix(key, "_id", "")
end

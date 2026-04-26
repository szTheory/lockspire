defmodule Lockspire.Protocol.RegistrationAccessToken do
  @moduledoc """
  Registration access token (RAT) primitives — generate, hash, verify.

  Hashing uses `Lockspire.Security.Policy.hash_token/1` (deterministic SHA-256
  lowercase hex) per Phase 26 D-06, required for hash-equality lookup at RFC 7592
  management calls (`Lockspire.Storage.Ecto.Repository.get_client_by_registration_access_token_hash/1`).

  The plaintext RAT is generated via `:crypto.strong_rand_bytes/1` + `Base.url_encode64/2`
  with `padding: false`. 32 bytes pre-encode (≈43 chars post-encode) per D-16, matching
  the operator-token entropy floor.
  """

  alias Lockspire.Security.Policy

  @rat_bytes 32

  @spec generate() :: {plaintext :: String.t(), hash :: String.t()}
  def generate do
    plaintext =
      @rat_bytes
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    {plaintext, Policy.hash_token(plaintext)}
  end

  @spec hash(String.t()) :: String.t()
  def hash(plaintext) when is_binary(plaintext), do: Policy.hash_token(plaintext)

  @doc """
  Timing-safe comparison of a stored RAT hash against a candidate plaintext.

  Hashes the candidate via `Policy.hash_token/1` and compares to `stored_hash` using
  `Plug.Crypto.secure_compare/2`. Returns `false` (without raising) when binary lengths
  differ.
  """
  @spec verify(stored_hash :: String.t(), candidate_plaintext :: String.t()) :: boolean()
  def verify(stored_hash, candidate_plaintext)
      when is_binary(stored_hash) and is_binary(candidate_plaintext) do
    Plug.Crypto.secure_compare(stored_hash, Policy.hash_token(candidate_plaintext))
  end
end

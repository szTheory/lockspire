defmodule Lockspire.Domain.PushedAuthorizationRequest do
  @moduledoc """
  Durable server-owned state for pushed authorization requests.
  """

  alias Lockspire.Security.Policy

  @request_uri_prefix "urn:ietf:params:oauth:request_uri:"
  @default_ttl 300

  @type prompt :: String.t() | [String.t()] | nil
  @type code_challenge_method :: :S256 | nil

  @type t :: %__MODULE__{
          id: integer() | nil,
          request_uri: String.t() | nil,
          request_uri_hash: String.t(),
          client_id: String.t(),
          redirect_uri: String.t(),
          scopes: [String.t()],
          resources_requested: [String.t()],
          authorization_details: [map()],
          prompt: prompt(),
          nonce: String.t() | nil,
          state: String.t() | nil,
          code_challenge: String.t(),
          code_challenge_method: code_challenge_method(),
          expires_at: DateTime.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :request_uri,
    :request_uri_hash,
    :client_id,
    :redirect_uri,
    :nonce,
    :state,
    :code_challenge,
    :code_challenge_method,
    :expires_at,
    :inserted_at,
    :updated_at,
    scopes: [],
    resources_requested: [],
    authorization_details: [],
    prompt: nil
  ]

  @spec issue(map(), keyword()) :: t()
  def issue(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    request_uri =
      @request_uri_prefix <>
        (opts
         |> Keyword.get_lazy(:request_uri_generator, &default_request_uri_generator/0)
         |> then(fn generator -> generator.() end))

    %__MODULE__{
      request_uri: request_uri,
      request_uri_hash: Policy.hash_token(request_uri),
      client_id: Map.fetch!(attrs, :client_id),
      redirect_uri: Map.fetch!(attrs, :redirect_uri),
      scopes: List.wrap(Map.get(attrs, :scopes, [])),
      resources_requested: List.wrap(Map.get(attrs, :resources_requested, [])),
      authorization_details: List.wrap(Map.get(attrs, :authorization_details, [])),
      prompt: Map.get(attrs, :prompt),
      nonce: Map.get(attrs, :nonce),
      state: Map.get(attrs, :state),
      code_challenge: Map.fetch!(attrs, :code_challenge),
      code_challenge_method: Map.get(attrs, :code_challenge_method, :S256),
      expires_at: DateTime.add(now, ttl, :second)
    }
  end

  @spec default_ttl() :: pos_integer()
  def default_ttl, do: @default_ttl

  @spec request_uri_prefix() :: String.t()
  def request_uri_prefix, do: @request_uri_prefix

  defp default_request_uri_generator do
    fn ->
      32
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)
    end
  end
end

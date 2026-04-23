defmodule Lockspire.Protocol.TokenFormatter do
  @moduledoc false

  @token_bytes 32

  @type formatted_token :: %{
          token: String.t(),
          token_hash: String.t(),
          token_type: String.t()
        }

  @spec format_access_token(keyword()) :: formatted_token()
  def format_access_token(opts \\ []) do
    format_token(opts)
  end

  @spec format_refresh_token(keyword()) :: formatted_token()
  def format_refresh_token(opts \\ []) do
    format_token(opts)
  end

  @spec hash_token(String.t()) :: String.t()
  def hash_token(token) when is_binary(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end

  defp default_token_generator do
    @token_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp format_token(opts) do
    token =
      opts
      |> Keyword.get_lazy(:token_generator, fn -> &default_token_generator/0 end)
      |> then(fn generator ->
        case :erlang.fun_info(generator, :arity) do
          {:arity, 1} -> generator.(:token)
          _other -> generator.()
        end
      end)

    %{
      token: token,
      token_hash: hash_token(token),
      token_type: "Bearer"
    }
  end
end

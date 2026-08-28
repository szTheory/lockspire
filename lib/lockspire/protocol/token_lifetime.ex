defmodule Lockspire.Protocol.TokenLifetime do
  @moduledoc false

  @access_token_seconds 3_600
  @refresh_token_seconds 2_592_000

  @spec access_token() :: pos_integer()
  def access_token, do: @access_token_seconds

  @spec id_token() :: pos_integer()
  def id_token, do: @access_token_seconds

  @spec refresh_token() :: pos_integer()
  def refresh_token, do: @refresh_token_seconds
end

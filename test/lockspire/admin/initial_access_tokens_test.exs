defmodule Lockspire.Admin.InitialAccessTokensTest do
  use ExUnit.Case, async: true

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Domain.InitialAccessToken

  test "lifecycle status treats the expiry instant as expired" do
    now = ~U[2026-10-09 12:00:00Z]

    assert InitialAccessTokens.lifecycle_status(%InitialAccessToken{expires_at: now}, now) ==
             :expired

    assert InitialAccessTokens.lifecycle_status(
             %InitialAccessToken{expires_at: DateTime.add(now, 1, :second)},
             now
           ) == :active

    assert InitialAccessTokens.lifecycle_status(
             %InitialAccessToken{expires_at: nil},
             now
           ) == :active
  end
end

defmodule Lockspire.Protocol.DiscoveryTest do
  use ExUnit.Case, async: false

  alias Lockspire.Protocol.Discovery

  @static_methods ["none", "client_secret_basic", "client_secret_post"]

  setup do
    original = Application.get_env(:lockspire, :issuer)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    on_exit(fn ->
      if is_nil(original) do
        Application.delete_env(:lockspire, :issuer)
      else
        Application.put_env(:lockspire, :issuer, original)
      end
    end)

    :ok
  end

  test "token_endpoint_auth_methods_supported/0 returns the static seam value (Phase 25 Plan 01)" do
    assert Discovery.token_endpoint_auth_methods_supported() == @static_methods
  end

  test "published_token_endpoint_auth_methods_supported/0 reflects the static list when /token is mounted" do
    assert Discovery.published_token_endpoint_auth_methods_supported() == @static_methods
  end
end

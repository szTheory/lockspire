defmodule Lockspire.JwksFetcherTest do
  use ExUnit.Case, async: true

  alias Lockspire.JwksFetcher

  setup context do
    Req.Test.verify_on_exit!(context)
    Req.Test.set_req_test_from_context(context)

    # Use a unique cache name or clear it if it were not async,
    # but Cachex runs via application tree. Since we need to test caching,
    # we should clear the cache before each test. We must make the suite async: false
    # or just use random URIs to avoid cache collisions.
    # Using random URIs is better for async.
    :ok
  end

  test "fetches and parses JWKS successfully from map body" do
    uri = "https://example.com/jwks_#{System.unique_integer()}"

    jwks_json = %{
      "keys" => [
        %{
          "kty" => "RSA",
          "kid" => "1",
          "n" => "yIccpD9a2RurO-Jb_A-WwQ3ZpZ1G5Ue-j2mF_lB-z7U",
          "e" => "AQAB"
        }
      ]
    }

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Plug.Conn.send_resp(conn, 200, Jason.encode!(jwks_json))
    end)

    assert {:ok, %JOSE.JWK{} = jwk_set} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    # Validate that it parsed the key
    {_, keys} = jwk_set.keys
    assert length(keys) == 1
  end

  test "returns error on network timeout" do
    uri = "https://example.com/jwks_timeout_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    assert {:error, %Req.TransportError{reason: :timeout}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "returns error on non-200 response" do
    uri = "https://example.com/jwks_404_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Plug.Conn.send_resp(conn, 404, "Not Found")
    end)

    assert {:error, {:http_error, 404}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "returns error on invalid JWKS format" do
    uri = "https://example.com/jwks_invalid_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      # Valid JSON, but not a valid JWK
      Plug.Conn.send_resp(conn, 200, Jason.encode!(%{"keys" => "not_a_list"}))
    end)

    assert {:error, {:invalid_jwks_format, _}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "cache prevents subsequent network calls" do
    uri = "https://example.com/jwks_cache_#{System.unique_integer()}"

    jwks_json = %{
      "keys" => [
        %{"kty" => "RSA", "kid" => "1", "n" => "abc", "e" => "AQAB"}
      ]
    }

    # We expect the mock to be called exactly once
    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Plug.Conn.send_resp(conn, 200, Jason.encode!(jwks_json))
    end)

    # First call hits the network (mock)
    assert {:ok, _} = JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    # Second call should hit the cache (no mock expectation set for a second call)
    # If it hits the network, Req.Test will fail because there are no more expectations
    assert {:ok, _} = JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end
end

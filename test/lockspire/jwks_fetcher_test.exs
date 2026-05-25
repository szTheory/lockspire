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

  test "rejects non-https URIs before any request attempt" do
    uri = "http://example.com/jwks_#{System.unique_integer()}"

    assert {:error, {:jwks_fetch_failed, :https_required}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "returns error on network timeout" do
    uri = "https://example.com/jwks_timeout_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    assert {:error, {:jwks_fetch_failed, :timeout}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "redirect responses fail closed" do
    uri = "https://example.com/jwks_redirect_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      conn
      |> Plug.Conn.put_resp_header("location", "https://example.com/final")
      |> Plug.Conn.send_resp(302, "")
    end)

    assert {:error, {:jwks_fetch_failed, :redirect_disallowed}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "rejects unsafe resolved targets before making a request" do
    uri = "https://unsafe.example/jwks_#{System.unique_integer()}"

    resolver = fn "unsafe.example" -> {:ok, [{127, 0, 0, 1}]} end

    assert {:error, {:jwks_fetch_failed, {:unsafe_target, :loopback}}} =
             JwksFetcher.get_keys(
               uri,
               resolver: resolver,
               plug: {Req.Test, Lockspire.JwksFetcher}
             )
  end

  test "returns error on non-200 response" do
    uri = "https://example.com/jwks_404_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Plug.Conn.send_resp(conn, 404, "Not Found")
    end)

    assert {:error, {:jwks_fetch_failed, {:http_status, 404}}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "returns error on invalid JWKS format" do
    uri = "https://example.com/jwks_invalid_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      # Valid JSON, but not a valid JWK
      Plug.Conn.send_resp(conn, 200, Jason.encode!(%{"keys" => "not_a_list"}))
    end)

    assert {:error, {:jwks_fetch_failed, :invalid_format}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "rejects oversized payloads under an explicit body cap" do
    uri = "https://example.com/jwks_oversized_#{System.unique_integer()}"
    oversized_modulus = String.duplicate("A", 300_000)

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Plug.Conn.send_resp(
        conn,
        200,
        Jason.encode!(%{
          "keys" => [
            %{"kty" => "RSA", "kid" => "1", "n" => oversized_modulus, "e" => "AQAB"}
          ]
        })
      )
    end)

    assert {:error, {:jwks_fetch_failed, :payload_too_large}} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
  end

  test "strict runtime policy remains in force" do
    redirect_uri = "https://example.com/jwks_policy_redirect_#{System.unique_integer()}"
    retry_uri = "https://example.com/jwks_policy_retry_#{System.unique_integer()}"
    redirect_path = URI.parse(redirect_uri).path
    retry_path = URI.parse(retry_uri).path
    parent = self()

    {:ok, counter} = Agent.start_link(fn -> 0 end)

    Req.Test.stub(Lockspire.JwksFetcher, fn conn ->
      send(parent, {:request_seen, conn.request_path})

      case conn.request_path do
        ^redirect_path ->
          conn
          |> Plug.Conn.put_resp_header("location", "https://example.com/final")
          |> Plug.Conn.send_resp(302, "")

        ^retry_path ->
          attempt =
            Agent.get_and_update(counter, fn value ->
              {value + 1, value + 1}
            end)

          if attempt == 1 do
            Req.Test.transport_error(conn, :timeout)
          else
            Plug.Conn.send_resp(conn, 200, Jason.encode!(%{"keys" => []}))
          end
      end
    end)

    assert {:error, {:jwks_fetch_failed, :redirect_disallowed}} =
             JwksFetcher.get_keys(
               redirect_uri,
               redirect: true,
               plug: {Req.Test, Lockspire.JwksFetcher}
             )

    assert {:error, {:jwks_fetch_failed, :timeout}} =
             JwksFetcher.get_keys(
               retry_uri,
               retry: :safe_transient,
               receive_timeout: 60_000,
               connect_options: [timeout: 60_000],
               plug: {Req.Test, Lockspire.JwksFetcher}
             )

    assert_receive {:request_seen, ^redirect_path}
    assert_receive {:request_seen, ^retry_path}
    refute_receive {:request_seen, "/final"}
    assert Agent.get(counter, & &1) == 1
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

  test "successful fetches cache with an explicit ttl" do
    uri = "https://example.com/jwks_ttl_#{System.unique_integer()}"

    Req.Test.expect(Lockspire.JwksFetcher, fn conn ->
      Plug.Conn.send_resp(conn, 200, Jason.encode!(%{"keys" => []}))
    end)

    assert {:ok, _} = JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})
    assert {:ok, ttl} = Cachex.ttl(:lockspire_jwks_cache, uri)
    assert is_integer(ttl)
    assert ttl > 0
    assert ttl <= JwksFetcher.cache_ttl()
  end

  test "forced refresh replaces cached key material after rotation" do
    uri = "https://example.com/jwks_rotate_#{System.unique_integer()}"
    {:ok, request_count} = Agent.start_link(fn -> 0 end)
    {:ok, key_versions} = Agent.start_link(fn -> ["old", "new"] end)

    Req.Test.stub(Lockspire.JwksFetcher, fn conn ->
      Agent.update(request_count, &(&1 + 1))

      [kid | _remaining] =
        Agent.get_and_update(key_versions, fn
          [current | rest] -> {[current | rest], rest}
          [] -> {["new"], []}
        end)

      Plug.Conn.send_resp(conn, 200, Jason.encode!(jwks_with_kid(kid)))
    end)

    assert {:ok, initial_keys} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert jwk_kids(initial_keys) == ["old"]

    assert {:ok, cached_keys} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert jwk_kids(cached_keys) == ["old"]

    assert {:ok, refreshed_keys} =
             JwksFetcher.refresh_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert jwk_kids(refreshed_keys) == ["new"]

    assert {:ok, post_refresh_keys} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert jwk_kids(post_refresh_keys) == ["new"]
    assert Agent.get(request_count, & &1) == 2
  end

  test "failed forced refresh preserves the last known good cache entry" do
    uri = "https://example.com/jwks_refresh_failure_#{System.unique_integer()}"
    {:ok, request_count} = Agent.start_link(fn -> 0 end)
    {:ok, mode} = Agent.start_link(fn -> :ok end)

    Req.Test.stub(Lockspire.JwksFetcher, fn conn ->
      Agent.update(request_count, &(&1 + 1))

      case Agent.get(mode, & &1) do
        :ok ->
          Plug.Conn.send_resp(conn, 200, Jason.encode!(jwks_with_kid("stable")))

        :fail ->
          Plug.Conn.send_resp(conn, 503, Jason.encode!(%{"error" => "upstream unavailable"}))
      end
    end)

    assert {:ok, initial_keys} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert jwk_kids(initial_keys) == ["stable"]

    Agent.update(mode, fn _ -> :fail end)

    assert {:error, {:jwks_fetch_failed, {:http_status, 503}}} =
             JwksFetcher.refresh_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert {:ok, cached_keys} =
             JwksFetcher.get_keys(uri, plug: {Req.Test, Lockspire.JwksFetcher})

    assert jwk_kids(cached_keys) == ["stable"]
    assert Agent.get(request_count, & &1) == 2
  end

  test "exposes safe fetch diagnostics details for classification" do
    assert %{stage: :validate_target, subreason: :unsafe_target, target_safety_reason: :loopback} =
             JwksFetcher.error_details({:jwks_fetch_failed, {:unsafe_target, :loopback}})

    assert %{stage: :network, subreason: :http_status, fetch_status: 404} =
             JwksFetcher.error_details({:jwks_fetch_failed, {:http_status, 404}})

    assert %{stage: :parse, subreason: :invalid_format} =
             JwksFetcher.error_details({:jwks_fetch_failed, :invalid_format})
  end

  defp jwk_kids(%JOSE.JWK{} = jwk_set) do
    {_, keys} = jwk_set.keys

    Enum.map(keys, &JOSE.JWK.to_map/1)
    |> Enum.map(fn {_kty, params} -> params["kid"] end)
  end

  defp jwks_with_kid(kid) do
    %{
      "keys" => [
        %{
          "kty" => "RSA",
          "kid" => kid,
          "n" => "yIccpD9a2RurO-Jb_A-WwQ3ZpZ1G5Ue-j2mF_lB-z7U",
          "e" => "AQAB"
        }
      ]
    }
  end
end

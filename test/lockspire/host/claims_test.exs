defmodule Lockspire.Host.ClaimsTest do
  use ExUnit.Case, async: true

  alias Lockspire.Host.Claims

  test "build_id_token_claims/2 drops host auth_time before merging protocol claims" do
    claims = host_claims()

    merged =
      Claims.build_id_token_claims(claims, %{
        "iss" => "https://example.test/lockspire",
        "sub" => "protocol-subject",
        "auth_time" => 1_777_388_700
      })

    assert merged["auth_time"] == 1_777_388_700
    assert merged["sub"] == "protocol-subject"
    assert merged["email"] == "subject@example.test"
  end

  test "build_userinfo_claims/1 drops host auth_time while preserving custom claims" do
    claims = host_claims()

    userinfo = Claims.build_userinfo_claims(claims)

    refute Map.has_key?(userinfo, "auth_time")
    assert userinfo["sub"] == "subject-123"
    assert userinfo["name"] == "Subject 123"
  end

  defp host_claims do
    %Claims{
      subject: "subject-123",
      id_token: %{
        "auth_time" => "host-owned",
        "sub" => "host-subject",
        "email" => "subject@example.test"
      },
      userinfo: %{
        "auth_time" => "host-owned",
        "sub" => "host-subject",
        "name" => "Subject 123"
      }
    }
  end
end

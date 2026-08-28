defmodule Lockspire.Web.AdminProof.RedactionAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.Web.AdminProof.{HtmlAssertions, Paths}

  @raw_value_patterns [
    {"client secret", ~r/\bclient_secret=["']?[^\s<]{8,}/i},
    {"access token", ~r/\baccess_token=["']?[^\s<]{8,}/i},
    {"refresh token", ~r/\brefresh_token=["']?[^\s<]{8,}/i},
    {"authorization code", ~r/\bauthorization_code=["']?[^\s<]{8,}/i},
    {"cookie", ~r/\b(?:cookie|session_id)=["']?[^\s<]{8,}/i},
    {"private key", ~r/-----BEGIN [A-Z ]*PRIVATE KEY-----/},
    {"SQL statement", ~r/\b(?:SELECT|INSERT|UPDATE|DELETE)\b.+\b(?:FROM|INTO|SET)\b/is},
    {"upstream error body", ~r/\b(?:response|error)_body\s*[:=]\s*["'][^"']+["']/i}
  ]

  @read_only_sources [
    "lib/lockspire/web/live/admin/interactions_live/index.ex",
    "lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
    "lib/lockspire/web/live/admin/logout_deliveries_live/index.ex"
  ]

  @raw_storage_fields [
    "device_code_hash",
    "user_code_hash",
    "client_secret_hash",
    "authorization_code",
    "refresh_token",
    "access_token",
    "private_key",
    "verifier_material"
  ]

  def assert_rendered_safe!(html) when is_binary(html) do
    HtmlAssertions.assert_no_token_like_text(html)

    for {label, pattern} <- @raw_value_patterns do
      refute Regex.match?(pattern, html), "expected rendered admin HTML to omit #{label}"
    end

    html
  end

  def assert_safe_operator_context!(html) when is_binary(html) do
    assert html =~ "lockspire-admin-redacted-value"
    assert Regex.match?(~r/lockspire-admin-status-[a-z-]+/, html)

    html
  end

  def assert_source_boundaries! do
    sources = Paths.admin_live_sources() |> Enum.join("\n")
    components = File.read!(Paths.admin_components())

    assert sources =~ "redacted_handle"
    assert sources =~ "copy_once_secret_panel"
    assert components =~ "lockspire-admin-redacted-value"

    for relative_path <- @read_only_sources,
        field <- @raw_storage_fields do
      source = Paths.root() |> Path.join(relative_path) |> File.read!()
      refute source =~ field, "#{relative_path} renders raw storage field #{field}"
    end

    :ok
  end
end

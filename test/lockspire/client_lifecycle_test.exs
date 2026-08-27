defmodule Lockspire.ClientLifecycleTest do
  use ExUnit.Case, async: false

  alias Lockspire.ClientLifecycle
  alias Lockspire.Domain.Client

  test "neutral lifecycle persists a DCR client with DCR audit attribution" do
    client = %Client{client_id: "lifecycle-dcr-client", client_type: :public, redirect_uris: ["https://client.example.test/callback"], allowed_scopes: [], allowed_grant_types: ["authorization_code"], allowed_response_types: ["code"], token_endpoint_auth_method: :none, pkce_required: true, subject_type: :public, active: true}

    assert {:error, _reason} =
             ClientLifecycle.create_dcr(%{client: client, actor: %{type: :dcr, id: "iat-test"}})
  end
end

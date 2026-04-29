defmodule Lockspire.Protocol.EndSessionTest do
  use ExUnit.Case, async: true

  # EndSessionProtocol does not exist yet — stubs are pre-implementation.
  # All cases are @tag :skip until Plan 03 implements Protocol.EndSession.
  # Each test case description matches VALIDATION.md 38-xx-hint, 38-xx-redirect-uri, 38-xx-aud rows.

  describe "validate/1 — id_token_hint" do
    @tag :skip
    test "valid signature with non-expired token passes and extracts sid and sub" do
      # Plan 03: EndSession.validate(%{params: %{"id_token_hint" => valid_jwt, ...}})
      # => {:ok, %EndSession.Result{sid: sid, account_id: sub, ...}}
      flunk("not yet implemented")
    end

    @tag :skip
    test "valid signature with expired token passes (tolerates expiry per D-14 / OIDC spec)" do
      # id_token_hint with exp in the past must still pass signature validation
      # and return {:ok, result} — NOT {:error, ...}
      flunk("not yet implemented")
    end

    @tag :skip
    test "invalid signature returns error" do
      # A JWT signed with a different key must return {:error, %EndSession.Error{reason_code: :invalid_id_token_hint}}
      flunk("not yet implemented")
    end

    @tag :skip
    test "missing id_token_hint proceeds with nil sid (D-16)" do
      # EndSession.validate(%{params: %{}}) => {:ok, %EndSession.Result{sid: nil, ...}}
      flunk("not yet implemented")
    end
  end

  describe "validate/1 — post_logout_redirect_uri" do
    @tag :skip
    test "registered URI passes exact match and is returned in result (D-15)" do
      # EndSession.validate with post_logout_redirect_uri in client.post_logout_redirect_uris
      # => {:ok, %Result{post_logout_redirect_uri: uri}}
      flunk("not yet implemented")
    end

    @tag :skip
    test "unregistered URI is rejected — prevents open redirect (D-15, T-38-03)" do
      # post_logout_redirect_uri NOT in client.post_logout_redirect_uris
      # => {:error, %Error{reason_code: :unregistered_post_logout_redirect_uri}}
      flunk("not yet implemented")
    end

    @tag :skip
    test "missing post_logout_redirect_uri returns nil in result (D-17)" do
      # No post_logout_redirect_uri param => {:ok, %Result{post_logout_redirect_uri: nil}}
      flunk("not yet implemented")
    end
  end

  describe "validate/1 — client_id / aud cross-check" do
    @tag :skip
    test "client_id present in id_token_hint aud passes (D-20)" do
      # JWT aud includes client_id => :ok
      flunk("not yet implemented")
    end

    @tag :skip
    test "client_id not in id_token_hint aud is rejected (D-20, T-38-04)" do
      # JWT aud does not include the client_id param
      # => {:error, %Error{reason_code: :client_id_not_in_aud}}
      flunk("not yet implemented")
    end
  end
end

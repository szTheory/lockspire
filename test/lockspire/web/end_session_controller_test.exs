defmodule Lockspire.Web.EndSessionControllerTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  @endpoint Lockspire.TestEndpoint

  # All cases are @tag :skip until Plan 03 wires EndSessionController.
  # Matches VALIDATION.md rows: 38-xx-methods, 38-xx-host-redirect, 38-xx-completion.
  # Security behaviors: open-redirect prevention (T-38-03), aud mismatch (T-38-04),
  # host redirect (T-38-05), revoke_by_sid at completion (T-38-01).

  describe "GET /end_session" do
    @tag :skip
    test "returns redirect to host logout_path with signed return_to token" do
      # GET /end_session with valid params => 302 to Config.logout_path()
      # The return_to query param must be a signed token (D-09, D-11)
      flunk("not yet implemented")
    end

    @tag :skip
    test "returns 400 for invalid id_token_hint signature" do
      # GET /end_session with tampered hint => 400 plain HTML error
      # Does NOT redirect to post_logout_redirect_uri (open-redirect prevention)
      flunk("not yet implemented")
    end

    @tag :skip
    test "returns 400 when client_id not in id_token_hint aud (T-38-04)" do
      # client_id param present but not in aud claim of id_token_hint
      # => 400 error, no redirect issued
      flunk("not yet implemented")
    end

    @tag :skip
    test "accepts request with no id_token_hint and redirects to host logout (D-16)" do
      # No id_token_hint => proceeds with nil sid, still issues host redirect
      flunk("not yet implemented")
    end
  end

  describe "POST /end_session" do
    @tag :skip
    test "returns redirect to host logout_path (same handler as GET)" do
      # POST /end_session is accepted per D-18 / OIDC spec
      # Must behave identically to GET handler
      flunk("not yet implemented")
    end
  end

  describe "GET /end_session/complete" do
    @tag :skip
    test "valid signed token triggers revoke_by_sid and redirects to post_logout_redirect_uri" do
      # /end_session/complete?token=<valid_signed_token>
      # => calls Repository.revoke_by_sid/1, redirects to registered URI
      flunk("not yet implemented")
    end

    @tag :skip
    test "invalid or expired signed token still succeeds as logout (D-10)" do
      # D-10: treat validation failure as logout success — do not strand user
      # => renders logged-out page or redirects to safe destination
      flunk("not yet implemented")
    end

    @tag :skip
    test "no post_logout_redirect_uri renders logged-out page (D-17, D-24)" do
      # => 200 with plain logged-out HTML page
      flunk("not yet implemented")
    end
  end
end

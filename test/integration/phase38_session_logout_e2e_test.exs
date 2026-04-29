defmodule Lockspire.Phase38SessionLogoutE2ETest do
  use ExUnit.Case, async: false

  # End-to-end integration test for Phase 38 SLO-01 and SLO-02.
  # Requires a running Repo (database). All cases are @tag :skip until
  # Plan 02 (sid tracking) and Plan 03 (end_session) are complete.
  # Matches VALIDATION.md row: 38-01-03 integration.

  @tag :skip
  test "sid is generated at interaction creation and denormalized onto issued tokens (SLO-01)" do
    # 1. Create an interaction via the authorize endpoint
    # 2. Issue an authorization code
    # 3. Exchange for access + refresh tokens
    # 4. Assert interaction.sid is non-nil
    # 5. Assert access_token.sid == interaction.sid
    # 6. Assert refresh_token.sid == interaction.sid
    # 7. Assert id_token claims include "sid" == interaction.sid
    flunk("not yet implemented")
  end

  @tag :skip
  test "revoke_by_sid/1 revokes all active tokens for the session (SLO-01)" do
    # 1. Issue tokens for a known sid
    # 2. Call Repository.revoke_by_sid(sid)
    # 3. Assert all active tokens for that sid have revoked_at set
    # 4. Assert tokens with redeemed_at are unaffected
    flunk("not yet implemented")
  end

  @tag :skip
  test "full RP-initiated logout flow: GET /end_session -> host completion -> redirect (SLO-02)" do
    # 1. Issue tokens for a session with known sid
    # 2. GET /end_session with id_token_hint, post_logout_redirect_uri
    # 3. Follow redirect to host logout_path
    # 4. Simulate host completing logout: GET /end_session/complete?token=...
    # 5. Assert tokens revoked by sid
    # 6. Assert final redirect to post_logout_redirect_uri
    flunk("not yet implemented")
  end
end

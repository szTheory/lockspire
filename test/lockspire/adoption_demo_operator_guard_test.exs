defmodule Lockspire.AdoptionDemoOperatorGuardTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  @repo_root Path.expand("../..", __DIR__)
  @guard_path Path.join(
                @repo_root,
                "examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex"
              )

  setup_all do
    unless Code.ensure_loaded?(AdoptionDemoWeb.Plugs.RequireOperator) do
      Code.compile_file(@guard_path)
    end

    :ok
  end

  test "anonymous admin requests redirect to the demo login picker" do
    conn =
      :get
      |> conn("/lockspire/admin")
      |> assign(:current_account, nil)
      |> call_guard()

    assert conn.halted
    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/login?return_to=%2Flockspire%2Fadmin"]
  end

  test "signed-in non-operators are forbidden with recovery guidance" do
    conn =
      :get
      |> conn("/lockspire/admin")
      |> assign(:current_account, %{operator?: false})
      |> call_guard()

    assert conn.halted
    assert conn.status == 403
    assert conn.resp_body =~ "Operator access requires the demo ops account"
    assert conn.resp_body =~ "Sign out, then choose ops"
  end

  test "operator accounts pass through unchanged" do
    conn =
      :get
      |> conn("/lockspire/admin")
      |> assign(:current_account, %{operator?: true})
      |> call_guard()

    refute conn.halted
    assert conn.status == nil
  end

  defp call_guard(conn) do
    # apply/3 on purpose: the plug lives in examples/adoption_demo and is only
    # compiled at runtime by setup_all, so a direct remote call would emit an
    # "module is not available" warning here.
    # credo:disable-for-next-line Credo.Check.Refactor.Apply
    apply(AdoptionDemoWeb.Plugs.RequireOperator, :call, [conn, []])
  end
end

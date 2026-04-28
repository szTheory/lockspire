defmodule <%= @verification_controller_module %> do
  use Phoenix.Controller, formats: [:html]

  # `verification_uri_complete` is prefill-only. Do not auto-submit, auto-look-up,
  # or mutate device authorization state from GET /verify.
  def show(conn, params) do
    render(conn, :index,
      page_title: "Verify your device",
      review_step?: false,
      user_code: params["user_code"] || "",
      verification_handle: nil,
      client_name: nil,
      scopes: [],
      error_message: nil
    )
  end

  def lookup(conn, _params) do
    render(conn, :index,
      page_title: "Verify your device",
      review_step?: false,
      user_code: "",
      verification_handle: nil,
      client_name: nil,
      scopes: [],
      error_message: "Replace this starter lookup with your host-owned verification flow."
    )
  end

  def approve(conn, _params) do
    conn
    |> put_status(:not_implemented)
    |> text("Implement host-owned approve behavior before exposing /verify.")
  end

  def deny(conn, _params) do
    conn
    |> put_status(:not_implemented)
    |> text("Implement host-owned deny behavior before exposing /verify.")
  end
end

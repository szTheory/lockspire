defmodule Lockspire.Web.AdminRoutes do
  @moduledoc """
  Expands Lockspire's admin LiveViews into the host Phoenix router.

  The host supplies its HTTP authorization pipelines and current-identity
  `on_mount` hooks. Lockspire adds only a mount-path alignment guard.
  """

  @admin_live_routes [
    {"/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index},
    {"/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index},
    {"/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index},
    {"/clients/new", Lockspire.Web.Live.Admin.ClientsLive.Index, :new},
    {"/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show},
    {"/consents", Lockspire.Web.Live.Admin.ConsentsLive.Index, :index},
    {"/consents/:id", Lockspire.Web.Live.Admin.ConsentsLive.Show, :show},
    {"/tokens", Lockspire.Web.Live.Admin.TokensLive.Index, :index},
    {"/tokens/:id", Lockspire.Web.Live.Admin.TokensLive.Show, :show},
    {"/keys", Lockspire.Web.Live.Admin.KeysLive.Index, :index},
    {"/keys/:id", Lockspire.Web.Live.Admin.KeysLive.Show, :show},
    {"/interactions", Lockspire.Web.Live.Admin.InteractionsLive.Index, :index},
    {"/logouts", Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index, :index},
    {"/iats", Lockspire.Web.Live.Admin.IatLive.Index, :index},
    {"/iats/new", Lockspire.Web.Live.Admin.IatLive.New, :new},
    {"/device_authorizations", Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index, :index},
    {"/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit},
    {"/clients/:client_id/par-policy", Lockspire.Web.Live.Admin.ClientsLive.Show, :par_policy},
    {"/clients/:client_id/security-profile", Lockspire.Web.Live.Admin.ClientsLive.Show, :security_profile},
    {"/clients/:client_id/redirects", Lockspire.Web.Live.Admin.ClientsLive.Show, :redirects},
    {"/clients/:client_id/logout-uris", Lockspire.Web.Live.Admin.ClientsLive.Show, :logout_uris},
    {"/clients/:client_id/rotate-secret", Lockspire.Web.Live.Admin.ClientsLive.Show, :rotate_secret},
    {"/clients/:client_id/rotate-registration-access-token", Lockspire.Web.Live.Admin.ClientsLive.Show,
     :rotate_registration_access_token},
    {"/dcr", Lockspire.Web.Live.Admin.DcrLive.Index, :index},
    {"/policies", Lockspire.Web.Live.Admin.PoliciesLive.Index, :index},
    {"/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show},
    {"/policies/security-profile", Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile, :show},
    {"/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show},
    {"/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show}
  ]

  @doc false
  defmacro __admin_live_routes__ do
    route_calls =
      Enum.map(@admin_live_routes, fn {path, view, action} ->
        quote do
          Phoenix.LiveView.Router.live(unquote(path), unquote(view), unquote(action))
        end
      end)

    quote do
      unquote_splicing(route_calls)
    end
  end

  @doc false
  def effective_admin_path(router, method, path, host) do
    with %{plug: Phoenix.LiveView.Plug, route: route_path} <-
           Phoenix.Router.route_info(router, method, path, host),
         mount_path when is_binary(mount_path) <- route_mount_prefix(route_path) do
      mount_path
    else
      _no_admin_route -> nil
    end
  end

  defmacro lockspire_admin_routes(path, options) do
    caller = __CALLER__
    path = Macro.expand(path, caller)
    options = Macro.expand_literals(options, caller)

    validate_admin_path!(path, "literal admin path")
    validate_options!(options)

    pipelines = Keyword.fetch!(options, :pipe_through)
    host_hooks = normalize_hooks!(Keyword.fetch!(options, :on_mount))

    native_options =
      options
      |> Keyword.drop([:pipe_through, :on_mount])
      |> Keyword.put(:on_mount, host_hooks ++ [{Lockspire.Web.AdminMount, {:mount_path, caller.module}}])

    quote do
      require Phoenix.LiveView.Router

      Phoenix.Router.pipeline :lockspire_admin_mount do
        plug(Lockspire.Web.AdminMount, router: unquote(caller.module))
      end

      Phoenix.Router.scope unquote(path) do
        Phoenix.Router.pipe_through unquote(pipelines ++ [:lockspire_admin_mount])

        Phoenix.LiveView.Router.live_session :lockspire_admin, unquote(native_options) do
          Lockspire.Web.AdminRoutes.__admin_live_routes__()
        end
      end
    end
  end

  defp validate_options!(options) when is_list(options) do
    keys = Keyword.keys(options)
    allowed = [:pipe_through, :on_mount, :root_layout, :layout, :session]

    cond do
      not Keyword.keyword?(options) ->
        raise ArgumentError, "Lockspire.Web.AdminRoutes options must be a keyword list"

      Enum.any?(keys, &(&1 not in allowed)) ->
        unknown = Enum.find(keys, &(&1 not in allowed))
        raise ArgumentError, "unknown Lockspire admin route option #{inspect(unknown)}"

      length(keys) != length(Enum.uniq(keys)) ->
        raise ArgumentError, "duplicate Lockspire admin route option"

      true ->
        validate_pipeline_option!(Keyword.get(options, :pipe_through))
        validate_hook_option!(Keyword.get(options, :on_mount))
    end
  end

  defp validate_options!(_options) do
    raise ArgumentError, "Lockspire.Web.AdminRoutes options must be a literal keyword list"
  end

  defp validate_pipeline_option!(pipelines) when is_list(pipelines) and pipelines != [] do
    unless Enum.all?(pipelines, &is_atom/1) do
      raise ArgumentError, "pipe_through must be a nonempty list of host pipeline atoms"
    end
  end

  defp validate_pipeline_option!(_pipelines) do
    raise ArgumentError, "pipe_through must be a nonempty list of host pipeline atoms"
  end

  defp validate_hook_option!(hooks) when is_list(hooks) and hooks != [] do
    unless Enum.all?(hooks, &valid_hook?/1) do
      raise ArgumentError, "on_mount must be a host hook module or a nonempty ordered hook list"
    end
  end

  defp validate_hook_option!(hook) do
    unless valid_hook?(hook) do
      raise ArgumentError, "on_mount must be a host hook module or a nonempty ordered hook list"
    end
  end

  defp valid_hook?(module) when is_atom(module), do: true
  defp valid_hook?({module, _arg}) when is_atom(module), do: true
  defp valid_hook?(_hook), do: false

  defp normalize_hooks!(hooks) when is_list(hooks), do: hooks
  defp normalize_hooks!(hook), do: [hook]

  defp route_mount_prefix(route_path) do
    Enum.find_value(@admin_live_routes, fn {relative_path, _view, _action} ->
      cond do
        relative_path == "/" and String.ends_with?(route_path, "/") ->
          String.trim_trailing(route_path, "/")

        relative_path == "/" and route_path != "" ->
          route_path

        String.ends_with?(route_path, relative_path) ->
          route_path
          |> String.replace_suffix(relative_path, "")
          |> String.trim_trailing("/")

        true ->
          nil
      end
    end)
  end

  defp validate_admin_path!(path, label) when is_binary(path) and path != "" do
    segments = String.split(path, "/", trim: false)

    invalid_segment? =
      Enum.any?(segments, fn segment ->
        segment in [".", ".."] or String.contains?(segment, [":", "*", "\\"]) or
          Regex.match?(~r/%2f|%5c/i, segment)
      end)

    invalid? =
      not String.starts_with?(path, "/") or String.contains?(path, "//") or invalid_segment? or
        String.contains?(path, ["?", "#"]) or String.contains?(path, "://") or
        not String.ends_with?(path, "/admin")

    if invalid? do
      raise ArgumentError,
            "#{label} must be a static slash-prefixed path ending in /admin; got #{inspect(path)}"
    end
  end

  defp validate_admin_path!(path, label) do
    raise ArgumentError, "#{label} must be a literal nonempty slash-prefixed path; got #{inspect(path)}"
  end
end

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
    {"/clients/:client_id/security-profile", Lockspire.Web.Live.Admin.ClientsLive.Show,
     :security_profile},
    {"/clients/:client_id/redirects", Lockspire.Web.Live.Admin.ClientsLive.Show, :redirects},
    {"/clients/:client_id/logout-uris", Lockspire.Web.Live.Admin.ClientsLive.Show, :logout_uris},
    {"/clients/:client_id/rotate-secret", Lockspire.Web.Live.Admin.ClientsLive.Show,
     :rotate_secret},
    {"/clients/:client_id/rotate-registration-access-token",
     Lockspire.Web.Live.Admin.ClientsLive.Show, :rotate_registration_access_token},
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
      (unquote_splicing(route_calls))
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
      |> Keyword.put(
        :on_mount,
        host_hooks ++ [{Lockspire.Web.AdminMount, {:mount_path, caller.module}}]
      )

    quote do
      require Phoenix.LiveView.Router

      Phoenix.Router.pipeline :lockspire_admin_mount do
        plug(Lockspire.Web.AdminMount, router: unquote(caller.module))
      end

      Phoenix.Router.scope unquote(path), alias: false do
        Lockspire.Web.AdminRoutes.__validate_effective_path__(
          Phoenix.Router.scoped_path(__MODULE__, "/")
        )

        Phoenix.Router.pipe_through(unquote(pipelines ++ [:lockspire_admin_mount]))

        Phoenix.LiveView.Router.live_session :lockspire_admin, unquote(native_options) do
          Lockspire.Web.AdminRoutes.__admin_live_routes__()
        end
      end
    end
  end

  @doc false
  def __validate_effective_path__(path), do: validate_admin_path!(path, "effective admin path")

  defp validate_options!(options) when is_list(options) do
    allowed = [:pipe_through, :on_mount, :root_layout, :layout, :session]

    cond do
      not Keyword.keyword?(options) ->
        raise ArgumentError, "Lockspire.Web.AdminRoutes options must be a keyword list"

      Enum.any?(Keyword.keys(options), &(&1 not in allowed)) ->
        unknown = Enum.find(Keyword.keys(options), &(&1 not in allowed))
        raise ArgumentError, "unknown Lockspire admin route option #{inspect(unknown)}"

      length(Keyword.keys(options)) != length(Enum.uniq(Keyword.keys(options))) ->
        raise ArgumentError, "duplicate Lockspire admin route option"

      not Keyword.has_key?(options, :pipe_through) or not Keyword.has_key?(options, :on_mount) ->
        raise ArgumentError,
              "pipe_through and on_mount are required Lockspire admin route options"

      true ->
        validate_pipeline_option!(Keyword.get(options, :pipe_through))
        validate_hook_option!(Keyword.get(options, :on_mount))
        validate_native_options!(options)
    end
  end

  defp validate_options!(_options) do
    raise ArgumentError, "Lockspire.Web.AdminRoutes options must be a literal keyword list"
  end

  defp validate_pipeline_option!(pipelines) when is_list(pipelines) and pipelines != [] do
    unless Enum.all?(pipelines, &(is_atom(&1) and &1 not in [nil, true, false])) do
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

  defp validate_native_options!(options) do
    if Keyword.has_key?(options, :root_layout),
      do: validate_layout_option!(Keyword.get(options, :root_layout), :root_layout)

    if Keyword.has_key?(options, :layout),
      do: validate_layout_option!(Keyword.get(options, :layout), :layout)

    if Keyword.has_key?(options, :session),
      do: validate_session_option!(Keyword.get(options, :session))
  end

  defp validate_layout_option!(false, _key), do: :ok

  defp validate_layout_option!({module, template}, _key)
       when is_atom(module) and is_atom(template), do: :ok

  defp validate_layout_option!({:{}, _meta, [module, template]}, _key)
       when is_atom(module) and is_atom(template),
       do: :ok

  defp validate_layout_option!(_layout, key) do
    raise ArgumentError, "#{key} must be false or a {module, template} tuple of atoms"
  end

  defp validate_session_option!(session) when is_map(session) do
    unless Enum.all?(Map.keys(session), &is_binary/1) do
      raise ArgumentError, "session maps must use string keys"
    end
  end

  defp validate_session_option!({:%{}, _meta, entries}) when is_list(entries) do
    unless Enum.all?(entries, fn
             {key, _value} when is_binary(key) -> true
             _other -> false
           end) do
      raise ArgumentError, "session maps must use string keys"
    end
  end

  defp validate_session_option!({module, function, args})
       when is_atom(module) and is_atom(function) and is_list(args),
       do: :ok

  defp validate_session_option!({:{}, _meta, [module, function, args]})
       when is_atom(module) and is_atom(function) and is_list(args),
       do: :ok

  defp validate_session_option!(_session) do
    raise ArgumentError,
          "session must be a string-keyed map or {module, function, args} MFA tuple"
  end

  defp valid_hook?(module) when is_atom(module) and module not in [nil, true, false], do: true

  defp valid_hook?({module, _arg}) when is_atom(module) and module not in [nil, true, false],
    do: true

  defp valid_hook?(_hook), do: false

  defp normalize_hooks!(hooks) when is_list(hooks), do: hooks
  defp normalize_hooks!(hook), do: [hook]

  defp route_mount_prefix(route_path) do
    Enum.find_value(@admin_live_routes, fn {relative_path, _view, _action} ->
      cond do
        relative_path == "/" and
            (route_path == "/" or String.ends_with?(route_path, "/admin")) ->
          String.trim_trailing(route_path, "/")

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
      raise ArgumentError, "#{label} must be a static slash-prefixed path ending in /admin"
    end
  end

  defp validate_admin_path!(_path, label) do
    raise ArgumentError, "#{label} must be a literal nonempty slash-prefixed path"
  end
end

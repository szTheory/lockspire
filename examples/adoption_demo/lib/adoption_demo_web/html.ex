defmodule AdoptionDemoWeb.HTML do
  @moduledoc false

  @brand "Billingo"
  @tagline "Subscription billing for teams that ship usage-based products."
  @scope_meanings %{
    "openid" => "Confirm which Billingo user approved this request.",
    "email" => "Share the email claim when Billingo allows it.",
    "profile" => "Share basic profile claims when Billingo allows it.",
    "read:billing" => "Read Billingo billing summaries when product policy allows it.",
    "write:reports" => "Write Billingo reports when product policy allows it."
  }
  @fallback_scope_meaning "Requested access defined by Billingo policy."

  def page(conn, title, body) do
    account = conn.assigns[:current_account]
    csrf = Plug.CSRFProtection.get_csrf_token()
    current_path = conn.request_path || "/"

    """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>#{escape(title)} - #{@brand}</title>
        <style>
          #{styles()}
        </style>
      </head>
      <body>
        <header class="site-header">
          <div class="shell">
            <div class="topbar">
              <a class="brand" href="/" aria-label="#{@brand} home">
                <span class="brand-mark" aria-hidden="true">B</span>
                <span>
                  <strong>#{@brand}</strong>
                  <small>Example host SaaS</small>
                </span>
              </a>
              <div class="session-box">
                <span class="session-label">Signed in as</span>
                <strong>#{account_label(account)}</strong>
                #{session_action(account, csrf)}
              </div>
            </div>
            <p class="brand-line">#{@tagline}</p>
            <nav class="nav" aria-label="Billingo demo navigation">
              #{nav_link("/", "Dashboard", current_path)}
              #{nav_link("/developer/apps", "Developer console", current_path)}
              #{nav_link("/authorized-apps", "Authorized apps", current_path)}
              #{nav_link("/verify", "Device code", current_path)}
              #{nav_link("/lockspire/.well-known/openid-configuration", "Discovery", current_path)}
              #{nav_link("/lockspire/admin", "Lockspire admin", current_path)}
            </nav>
          </div>
        </header>
        <main class="shell main">
          #{flash_region(conn)}
          #{body}
        </main>
      </body>
    </html>
    """
  end

  def escape(value) do
    value
    |> to_string()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  def account_label(nil), do: "anonymous"

  def account_label(account) do
    "#{escape(account.name)} (#{escape(account.email)})"
  end

  def scope_meaning_list(scopes) when is_binary(scopes) do
    scopes
    |> String.split(~r/\s+/, trim: true)
    |> scope_meaning_list()
  end

  def scope_meaning_list(scopes) when is_list(scopes) do
    rows =
      scopes
      |> Enum.map(&to_string/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map_join("\n", &scope_meaning_row/1)

    ~s(<div class="scope-meaning-list">#{rows}</div>)
  end

  defp flash_region(conn) do
    flash = conn.assigns[:flash] || %{}

    messages =
      [{:info, "callout"}, {:error, "inline-alert"}]
      |> Enum.map(fn {key, class} -> {class, Phoenix.Flash.get(flash, key)} end)
      |> Enum.reject(fn {_class, message} -> message in [nil, ""] end)

    case messages do
      [] ->
        ""

      messages ->
        banners =
          Enum.map_join(messages, "\n", fn {class, message} ->
            ~s(<p class="#{class}">#{escape(message)}</p>)
          end)

        ~s(<div class="flash-stack" role="status" aria-live="polite">#{banners}</div>)
    end
  end

  defp session_action(nil, _csrf) do
    ~s(<a class="button ghost compact" href="/login">Choose account</a>)
  end

  defp session_action(_account, csrf) do
    """
    <form action="/logout" method="post">
      <input type="hidden" name="_csrf_token" value="#{csrf}" />
      <button class="button ghost compact" type="submit">Sign out</button>
    </form>
    """
  end

  defp nav_link(path, label, current_path) do
    active? =
      case path do
        "/" -> current_path == "/"
        "/lockspire/.well-known/openid-configuration" -> false
        _ -> String.starts_with?(current_path, path)
      end

    class = if active?, do: "nav-link active", else: "nav-link"
    ~s(<a class="#{class}" href="#{path}">#{label}</a>)
  end

  defp scope_meaning_row(scope) do
    meaning = Map.get(@scope_meanings, scope, @fallback_scope_meaning)

    """
    <div class="scope-meaning-row">
      <span class="status-pill neutral">#{escape(scope)}</span>
      <p>#{escape(meaning)}</p>
    </div>
    """
  end

  defp styles do
    """
    :root {
      --ink: #17202a;
      --muted: #667085;
      --line: #d9e0e7;
      --paper: #fffdf8;
      --panel: #ffffff;
      --panel-soft: #f6fbf8;
      --blue: #2251d1;
      --mint: #00a884;
      --saffron: #f4b740;
      --coral: #e26d5a;
      --violet: #6f5cc2;
      --section-gap: clamp(24px, 2.5vw, 32px);
      --shadow: 0 18px 46px rgba(30, 41, 59, 0.11);
    }

    * { box-sizing: border-box; }

    html {
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    body {
      margin: 0;
      color: var(--ink);
      background:
        linear-gradient(135deg, rgba(255, 253, 248, 0.98), rgba(241, 248, 246, 0.94)),
        repeating-linear-gradient(90deg, rgba(34, 81, 209, 0.045) 0, rgba(34, 81, 209, 0.045) 1px, transparent 1px, transparent 38px);
      font-family: "Avenir Next", "Trebuchet MS", ui-sans-serif, system-ui, sans-serif;
      line-height: 1.5;
      min-width: 320px;
    }

    a { color: var(--blue); text-decoration-thickness: 0.08em; text-underline-offset: 0.18em; }
    a:hover { color: #153da6; }

    h1, h2, h3, p { margin-top: 0; }
    h1, h2, h3 { letter-spacing: 0; line-height: 1.08; text-wrap: balance; }
    h1 { font-size: 4.6rem; max-width: 11ch; }
    h2 { font-size: 1.45rem; }
    h3 { font-size: 1.02rem; }
    p { color: #3f4b5a; text-wrap: pretty; }

    .shell { width: min(1180px, calc(100vw - 36px)); margin: 0 auto; }
    .site-header { border-bottom: 1px solid rgba(23, 32, 42, 0.12); background: rgba(255, 253, 248, 0.88); backdrop-filter: blur(18px); }
    .topbar { display: flex; align-items: center; justify-content: space-between; gap: 18px; padding: 22px 0 10px; }
    .brand { display: inline-flex; align-items: center; gap: 12px; color: var(--ink); max-width: 100%; min-width: 0; text-decoration: none; }
    .brand > span:last-child { min-width: 0; }
    .brand-mark { display: grid; place-items: center; width: 42px; height: 42px; border-radius: 8px; color: white; font-weight: 900; background: linear-gradient(135deg, var(--blue), var(--mint)); box-shadow: 0 10px 28px rgba(34, 81, 209, 0.22); }
    .brand strong { display: block; font-size: 1.18rem; }
    .brand small, .brand-line, .session-label, .eyebrow, .kicker { color: var(--muted); font-size: 0.74rem; font-weight: 800; letter-spacing: 0; text-transform: uppercase; }
    .brand small, .brand-line { overflow-wrap: anywhere; word-break: normal; }
    .brand-line { margin: 0 0 16px 54px; }
    .session-box { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; justify-content: flex-end; color: #334155; }
    .session-box strong { font-size: 0.9rem; }
    .session-box form { margin: 0; }

    .nav { display: flex; flex-wrap: wrap; gap: 8px; padding: 0 0 18px; }
    .nav-link { border: 1px solid transparent; border-radius: 8px; color: #475467; overflow-wrap: anywhere; padding: 9px 12px; text-decoration: none; }
    .nav-link:hover, .nav-link.active { background: white; border-color: var(--line); color: var(--blue); box-shadow: 0 8px 24px rgba(30, 41, 59, 0.07); }

    .main { padding: 32px 0 72px; }
    .flash-stack { display: grid; gap: 12px; margin: 0 auto 22px; max-width: 960px; }
    .flash-stack p { margin-bottom: 0; }
    .main > section + section { margin-top: var(--section-gap); }
    .hero { display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(300px, 0.9fr); gap: 24px; align-items: stretch; }
    .hero-copy, .panel, .card, .visual-card { background: rgba(255, 255, 255, 0.92); border: 1px solid rgba(23, 32, 42, 0.11); border-radius: 8px; box-shadow: var(--shadow); min-width: 0; }
    .hero-copy { padding: clamp(24px, 5vw, 52px); position: relative; overflow: hidden; }
    .hero-copy::after { content: ""; position: absolute; inset: auto 28px 26px auto; width: 116px; height: 10px; background: linear-gradient(90deg, var(--saffron), var(--coral), var(--mint)); border-radius: 999px; }
    .hero-copy p { max-width: 66ch; font-size: 1.06rem; }
    .hero-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 22px; }
    .visual-card { padding: 24px; background: linear-gradient(160deg, #102a43, #1b4965 58%, #0b6b61); color: white; overflow: hidden; }
    .visual-card p, .visual-card .muted { color: rgba(255, 255, 255, 0.74); }
    .ledger-row { display: grid; grid-template-columns: minmax(0, 0.52fr) minmax(0, 1fr); gap: 12px; min-width: 0; padding: 13px 0; border-bottom: 1px solid rgba(255, 255, 255, 0.16); }
    .ledger-row span { min-width: 0; overflow-wrap: anywhere; }
    .ledger-row strong { color: white; font-variant-numeric: tabular-nums; min-width: 0; overflow-wrap: anywhere; text-align: right; }
    .total-line { margin-top: 22px; padding: 18px; border: 1px solid rgba(255, 255, 255, 0.22); border-radius: 8px; background: rgba(255, 255, 255, 0.09); }

    .grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 18px; }
    .grid.two { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .panel, .card { padding: 22px; overflow-wrap: break-word; }
    .card.highlight { border-color: rgba(0, 168, 132, 0.26); background: linear-gradient(180deg, #ffffff, var(--panel-soft)); }
    .metric { font-size: 2rem; font-weight: 900; font-variant-numeric: tabular-nums; line-height: 1; color: var(--ink); }
    .metric-label { color: var(--muted); font-size: 0.76rem; font-weight: 800; letter-spacing: 0; text-transform: uppercase; }
    .stack { display: grid; gap: 14px; }
    .split { display: grid; grid-template-columns: minmax(0, 1fr) minmax(280px, 0.8fr); gap: 18px; align-items: start; }
    .consent-stage { max-width: 900px; margin-inline: auto; }
    .consent-card { overflow: hidden; padding: clamp(24px, 4vw, 44px); position: relative; }
    .consent-card::before { content: ""; position: absolute; inset: 0 0 auto; height: 6px; background: linear-gradient(90deg, var(--blue), var(--mint), var(--saffron)); }
    .consent-card-header { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 18px; align-items: start; padding-bottom: 24px; border-bottom: 1px solid rgba(23, 32, 42, 0.1); }
    .consent-heading { min-width: 0; }
    .consent-card-header h1 { font-size: clamp(2.3rem, 6vw, 3.6rem); line-height: 1.03; max-width: 12ch; margin-bottom: 18px; }
    .consent-card-header p { max-width: 66ch; min-width: 0; margin-bottom: 0; font-size: 1.04rem; overflow-wrap: anywhere; }
    .consent-card-header .status-pill { flex: 0 0 auto; margin-top: 2px; }
    .consent-grid { display: grid; grid-template-columns: minmax(0, 1fr) minmax(260px, 0.62fr); gap: 28px; align-items: start; padding-top: 26px; }
    .consent-summary { display: grid; gap: 16px; min-width: 0; }
    .consent-detail-row { display: grid; grid-template-columns: minmax(118px, 0.42fr) minmax(0, 1fr); gap: 14px; min-width: 0; padding: 12px 0; border-bottom: 1px solid rgba(23, 32, 42, 0.08); }
    .consent-detail-row:first-child { padding-top: 0; }
    .consent-detail-row span { color: var(--muted); font-size: 0.74rem; font-weight: 900; letter-spacing: 0; text-transform: uppercase; }
    .consent-detail-row strong { min-width: 0; overflow-wrap: anywhere; }
    .scope-block { border: 1px solid rgba(34, 81, 209, 0.13); border-radius: 8px; background: #f8fbff; padding: 16px; }
    .scope-block .kicker { margin-bottom: 10px; }
    .scope-chip-list { display: flex; flex-wrap: wrap; gap: 8px; list-style: none; margin: 0; padding: 0; }
    .scope-chip-list .status-pill { max-width: 100%; overflow-wrap: anywhere; }
    .scope-meaning-list { display: grid; gap: 10px; }
    .scope-meaning-row { display: grid; grid-template-columns: auto minmax(0, 1fr); gap: 10px; align-items: start; padding: 10px; border-radius: 8px; background: #ffffff; box-shadow: 0 0 0 1px rgba(34, 81, 209, 0.08); }
    .scope-meaning-row .status-pill { justify-self: start; }
    .scope-meaning-row p { margin-bottom: 0; font-size: 0.91rem; }
    .consent-decision { display: grid; gap: 14px; border-left: 1px solid rgba(0, 168, 132, 0.22); padding-left: 24px; }
    .consent-decision h2 { font-size: 1.28rem; margin-bottom: 0; }
    .consent-decision p { margin-bottom: 0; }
    .approve-form, .deny-form { display: grid; gap: 12px; }
    .remember-consent { display: flex; align-items: flex-start; gap: 10px; margin: 0; padding: 14px; border: 1px solid rgba(0, 168, 132, 0.18); border-radius: 8px; background: #ffffff; }
    .remember-consent input[type="checkbox"] { flex: 0 0 auto; margin: 3px 0 0; }
    .remember-consent span, .remember-consent strong, .remember-consent small { min-width: 0; overflow-wrap: anywhere; }
    .remember-consent span { display: grid; gap: 2px; }
    .remember-consent small { color: var(--muted); font-size: 0.86rem; font-weight: 600; line-height: 1.35; }
    .consent-decision button { width: 100%; }

    .task-stage, .result-stage { max-width: 780px; margin-inline: auto; }
    .task-stage.wide, .result-stage.wide { max-width: 960px; }
    .task-card, .result-card { overflow: hidden; padding: clamp(24px, 4vw, 40px); position: relative; }
    .task-card::before, .result-card::before { content: ""; position: absolute; inset: 0 0 auto; height: 6px; background: linear-gradient(90deg, var(--blue), var(--mint), var(--saffron)); }
    .task-header, .result-header, .record-header { display: grid; gap: 12px; padding-bottom: 22px; border-bottom: 1px solid rgba(23, 32, 42, 0.1); }
    .task-header.split-header, .result-header.split-header { grid-template-columns: minmax(0, 1fr) auto; align-items: start; gap: 18px; }
    .task-header .status-pill, .result-header .status-pill, .record-side > .status-pill { justify-self: start; }
    .task-header h1, .result-header h1, .record-header h1 { font-size: clamp(2rem, 5vw, 3rem); line-height: 1.04; max-width: 15ch; margin-bottom: 0; }
    .task-header p, .result-header p, .record-header p { max-width: 66ch; margin-bottom: 0; }
    .task-form { display: grid; gap: 16px; margin-top: 22px; }
    .task-actions, .record-actions, .result-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; }
    .task-actions + .fine-print { margin-top: 12px; }
    .task-note, .demo-note { margin-top: 22px; padding: 16px; border-radius: 8px; background: #f8fbff; border: 1px solid rgba(34, 81, 209, 0.12); }
    .task-note p:last-child, .demo-note p:last-child { margin-bottom: 0; }
    .inline-alert { border-left: 4px solid var(--coral); background: #fff5f3; border-radius: 8px; color: #9f2f20; font-weight: 800; padding: 12px 14px; }
    .record-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(280px, 0.42fr); gap: 18px; align-items: start; }
    .record-main, .record-side { padding: 24px; }
    .record-section { padding-top: 18px; }
    .record-side { display: grid; gap: 14px; }
    .app-list { display: grid; gap: 14px; margin-top: 22px; }
    .app-row { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 18px; align-items: start; padding: 18px 0; border-bottom: 1px solid rgba(23, 32, 42, 0.09); }
    .app-row:last-child { border-bottom: 0; padding-bottom: 0; }
    .app-row h2 { margin-bottom: 6px; }
    .app-row p:last-child { margin-bottom: 0; }
    .app-meta { display: flex; flex-wrap: wrap; gap: 8px; justify-content: flex-end; }
    .integration-map { padding: 24px; }
    .section-heading { max-width: 760px; margin-bottom: 18px; }
    .section-heading h2 { max-width: 26ch; }
    .boundary-list { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
    .boundary-item { border-top: 1px solid rgba(23, 32, 42, 0.11); padding-top: 14px; }
    .boundary-item p:last-child { margin-bottom: 0; }
    .result-card pre { margin-top: 20px; }
    .handoff-steps { display: grid; gap: 12px; margin: 0; padding: 0; list-style: none; }
    .handoff-step { display: grid; grid-template-columns: 32px minmax(0, 1fr); gap: 10px; align-items: start; }
    .handoff-step p { margin-bottom: 0; }
    .step-index { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 8px; background: #eef4ff; color: var(--blue); font-weight: 900; font-variant-numeric: tabular-nums; }
    .receipt-list { display: grid; gap: 0; margin-top: 20px; }
    .receipt-row { display: grid; grid-template-columns: minmax(128px, 0.34fr) minmax(0, 1fr); gap: 16px; padding: 15px 0; border-bottom: 1px solid rgba(23, 32, 42, 0.09); }
    .receipt-row:first-child { padding-top: 0; }
    .receipt-row:last-child { border-bottom: 0; padding-bottom: 0; }
    .receipt-row > span { color: var(--muted); font-size: 0.74rem; font-weight: 900; text-transform: uppercase; }
    .receipt-row p { margin: 4px 0 0; }
    .raw-details { margin-top: 22px; }
    .raw-details summary { cursor: pointer; font-weight: 900; min-height: 40px; padding: 8px 0; }
    .raw-details pre { margin-top: 10px; }
    .status-pill.bad { background: #fff5f3; color: #9f2f20; }

    .button, button, a.primary {
      align-items: center;
      background: var(--blue);
      border: 1px solid var(--blue);
      border-radius: 8px;
      color: white;
      cursor: pointer;
      display: inline-flex;
      font: inherit;
      font-weight: 800;
      justify-content: center;
      min-height: 42px;
      padding: 10px 14px;
      text-decoration: none;
      transition-duration: 150ms;
      transition-property: background-color, border-color, box-shadow, color, scale;
      transition-timing-function: ease-out;
    }
    .button:hover, button:hover, a.primary:hover { background: #153da6; color: white; }
    .button:active, button:active, a.primary:active { scale: 0.96; }
    .button.secondary, button.secondary { background: white; border-color: var(--line); color: var(--ink); }
    .button.ghost, button.ghost { background: transparent; border-color: var(--line); color: #344054; }
    .button.compact, button.compact { min-height: 40px; padding: 8px 11px; }
    .button.danger, button.danger { background: #fff5f3; border-color: rgba(226, 109, 90, 0.42); color: #9f2f20; }

    dl { display: grid; gap: 10px; margin: 0; }
    dt { color: var(--muted); font-size: 0.73rem; font-weight: 900; letter-spacing: 0; text-transform: uppercase; }
    dd { margin: 0 0 6px; }
    .data-list { display: grid; gap: 12px; }
    .data-row { display: grid; grid-template-columns: minmax(120px, 0.42fr) minmax(0, 1fr); gap: 14px; min-width: 0; padding: 13px 0; border-bottom: 1px solid rgba(23, 32, 42, 0.09); }
    .data-row:last-child { border-bottom: 0; }

    code, pre {
      background: #eef6f2;
      border: 1px solid rgba(0, 168, 132, 0.16);
      border-radius: 6px;
      color: #18372f;
      font-family: "SFMono-Regular", Consolas, "Liberation Mono", monospace;
      font-size: 0.92em;
      padding: 2px 6px;
      overflow-wrap: anywhere;
    }
    pre { display: block; padding: 16px; overflow-x: auto; white-space: pre-wrap; }

    label { display: block; font-weight: 800; margin-bottom: 7px; }
    input, select {
      width: 100%;
      min-height: 44px;
      border: 1px solid #cbd5e1;
      border-radius: 8px;
      color: var(--ink);
      font: inherit;
      padding: 10px 12px;
      background: white;
    }
    input[type="checkbox"] { width: auto; min-height: 0; margin-right: 8px; }
    input:focus, select:focus, button:focus, a:focus { outline: 3px solid rgba(244, 183, 64, 0.5); outline-offset: 2px; }
    form { margin: 0; }
    .form-actions { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
    .form-actions form { display: grid; gap: 10px; }

    .pill, .status-pill { display: inline-flex; align-items: center; border-radius: 999px; font-size: 0.78rem; font-weight: 900; gap: 6px; padding: 5px 9px; }
    .pill { background: #eef4ff; color: #1d4ed8; }
    .status-pill.good { background: #e9f8f1; color: #027a48; }
    .status-pill.warn { background: #fff7df; color: #946200; }
    .status-pill.neutral { background: #f1f5f9; color: #475467; }
    .callout { border-left: 4px solid var(--mint); background: #f2fbf7; border-radius: 8px; padding: 16px; }
    .danger { color: #b42318; }
    .muted { color: var(--muted); }
    .fine-print { color: var(--muted); font-size: 0.88rem; }

    @media (max-width: 820px) {
      .topbar, .session-box { align-items: flex-start; flex-direction: column; justify-content: flex-start; }
      .brand-line { margin-left: 0; }
      .hero, .split, .grid, .grid.two, .consent-grid { grid-template-columns: 1fr; }
      .hero-copy { padding: 24px; }
      .consent-card-header { grid-template-columns: 1fr; }
      .consent-card-header h1 { max-width: none; }
      .consent-card-header .status-pill { justify-self: start; }
      .consent-decision { border-left: 0; border-top: 1px solid rgba(0, 168, 132, 0.22); padding-left: 0; padding-top: 22px; }
      .task-header.split-header, .result-header.split-header, .record-layout, .app-row, .boundary-list { grid-template-columns: 1fr; }
      .app-meta { justify-content: flex-start; }
      h1 { font-size: 2.75rem; max-width: none; }
    }

    @media (max-width: 520px) {
      .shell { max-width: 1180px; width: calc(100vw - 24px); }
      .main { padding-top: 28px; }
      .brand-line { max-width: 30ch; }
      .hero-copy, .panel, .card, .visual-card, .task-card, .result-card, .record-main, .record-side, .integration-map { padding: 20px; }
      .consent-card { padding: 20px; }
      .consent-grid { gap: 18px; padding-top: 20px; }
      .ledger-row { grid-template-columns: 1fr; gap: 4px; }
      .ledger-row strong { text-align: left; }
      .consent-detail-row, .receipt-row, .scope-meaning-row { grid-template-columns: 1fr; gap: 4px; }
      .remember-consent { padding: 12px; }
      h1 { font-size: 2rem; line-height: 1.12; }
      .nav-link { width: 100%; }
      .data-row { grid-template-columns: 1fr; gap: 4px; }
      .hero-actions, .form-actions, .task-actions, .record-actions, .result-actions { flex-direction: column; }
      .button, button, a.primary { width: 100%; }
    }
    """
  end
end

import { spawn } from "node:child_process";
import { accessSync, constants, mkdtempSync, readFileSync, rmSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { setTimeout as delay } from "node:timers/promises";

const ID = "tracer.browser_join_navigation";
const MAX_MS = 30000;
export const FULL_CASE_IDS = Object.freeze([
  "allowed_entry", "assets", "live_navigation", "params_patch", "detail_task", "allowed_reconnect",
  "anonymous_http_denied", "nonstaff_http_denied", "cached_join_denied", "reconnect_denied",
  "params_denied", "public_session_denied", "consent_session_denied", "public_discovery",
  "public_jwks", "public_protocol_error"
]);
const FULL_COUNT_FIELDS = Object.freeze(["assets", "websocket_handshakes", "successful_joins", "navigations", "params_checks", "http_checks", "staff_checks"]);
const FULL_OBSERVATION_FIELDS = Object.freeze([
  "static_200", "assets_200", "join_allowed", "protected_content", "live_navigation", "params_patch",
  "detail_task", "socket_closed", "reconnect_join", "interaction_after_reconnect", "anonymous_denied",
  "nonstaff_denied", "cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied",
  "consent_session_denied", "discovery_200", "jwks_200", "protocol_error_shape", "no_staff_checks",
  "protected_content_absent", "prefix_ok"
]);
const FULL_CASE_EVIDENCE = Object.freeze({
  allowed_entry: ["static_200", "join_allowed", "protected_content", "prefix_ok"],
  assets: ["assets_200"], live_navigation: ["live_navigation", "prefix_ok"],
  params_patch: ["params_patch", "prefix_ok"], detail_task: ["detail_task", "prefix_ok"],
  allowed_reconnect: ["socket_closed", "reconnect_join", "interaction_after_reconnect"],
  anonymous_http_denied: ["anonymous_denied", "protected_content_absent", "prefix_ok"],
  nonstaff_http_denied: ["nonstaff_denied", "protected_content_absent", "prefix_ok"],
  cached_join_denied: ["static_200", "cached_join_denied", "protected_content_absent"],
  reconnect_denied: ["reconnect_denied", "protected_content_absent"],
  params_denied: ["params_denied", "protected_content_absent"],
  public_session_denied: ["public_session_denied", "protected_content_absent"],
  consent_session_denied: ["consent_session_denied", "protected_content_absent"],
  public_discovery: ["discovery_200", "no_staff_checks"], public_jwks: ["jwks_200", "no_staff_checks"],
  public_protocol_error: ["protocol_error_shape", "no_staff_checks"]
});

export function supportedNode(version = process.versions.node) {
  const [major, minor] = version.split(".").map(Number);
  return Number.isInteger(major) && (major > 22 || (major === 22 && minor >= 15));
}

export function validateBrowserObservation(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  const fields = ["login", "overview", "clients", "authorized_http", "connected_hook"];
  return fields.every((field) => typeof value[field] === "boolean") &&
    Object.keys(value).length === fields.length && fields.every((field) => value[field]);
}

export function validateTracerEvidence(observations, counts) {
  return validateBrowserObservation(observations) &&
    counts && typeof counts === "object" &&
    Number.isInteger(counts.assets) && counts.assets >= 2 &&
    Number.isInteger(counts.websocket_handshakes) && counts.websocket_handshakes >= 2 &&
    Number.isInteger(counts.successful_joins) && counts.successful_joins >= 2 &&
    Number.isInteger(counts.navigations) && counts.navigations >= 4;
}

export function validateFullScenarios(scenarios) {
  if (!Array.isArray(scenarios) || scenarios.length !== FULL_CASE_IDS.length) return false;
  const seen = new Set();
  for (const scenario of scenarios) {
    if (!scenario || !FULL_CASE_IDS.includes(scenario.id) || seen.has(scenario.id) || scenario.outcome !== "passed") return false;
    seen.add(scenario.id);
    if (!scenario.observations || Object.keys(scenario.observations).length !== FULL_OBSERVATION_FIELDS.length ||
      !FULL_OBSERVATION_FIELDS.every((key) => typeof scenario.observations[key] === "boolean") ||
      !scenario.counts || Object.keys(scenario.counts).length !== FULL_COUNT_FIELDS.length ||
      !FULL_COUNT_FIELDS.every((key) => Number.isInteger(scenario.counts[key]) && scenario.counts[key] >= 0) ||
      !FULL_CASE_EVIDENCE[scenario.id].every((key) => scenario.observations[key])) return false;
  }
  return FULL_CASE_IDS.every((id) => seen.has(id));
}

export function isSuccessfulJoinFrame(payload) {
  try {
    const frame = JSON.parse(payload);
    return Array.isArray(frame) && frame[3] === "phx_reply" &&
      frame[4]?.status === "ok" && frame[4]?.response && typeof frame[4].response === "object";
  } catch {
    return false;
  }
}

export function isFailedJoinFrame(payload) {
  try {
    const frame = JSON.parse(payload);
    return Array.isArray(frame) && (
      (frame[3] === "phx_reply" && frame[4]?.status === "error") || frame[3] === "phx_close"
    );
  } catch {
    return false;
  }
}

function chromePath() {
  const pathCandidates = (process.env.PATH || "").split(path.delimiter).flatMap((dir) =>
    ["google-chrome", "chromium", "chromium-browser"].map((name) => path.join(dir, name))
  );
  const candidates = [
    process.env.CHROME_BIN,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    ...pathCandidates,
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser"
  ].filter(Boolean);
  for (const candidate of candidates) {
    try { accessSync(candidate, constants.X_OK); return candidate; } catch {}
  }
  throw new Error("chrome_missing");
}

function timed(promise, ms, label) {
  return Promise.race([
    promise,
    delay(ms).then(() => { throw new Error(label); })
  ]);
}

async function waitFor(evaluate, predicate, ms = MAX_MS) {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline) {
    const value = await evaluate();
    if (predicate(value)) return value;
    await delay(50);
  }
  throw new Error("browser_timeout");
}

async function runFullMatrix({ cdp, origin, input, mount, control, hostObservations, events, statusByPath }) {
  const adminPath = `${mount}/admin` || "/admin";
  const clientsPath = `${adminPath}/clients`;
  const urlFor = (path) => `${origin.origin}${path}`;
  const beforeEvents = () => events();
  const blank = async () => {
    await control("reset");
    await cdp.send("Network.clearBrowserCookies");
    statusByPath.clear();
    await cdp.send("Page.navigate", { url: "about:blank" });
    await waitFor(() => cdp.evaluate("location.href"), (href) => href === "about:blank", 10000);
  };
  const go = async (path) => {
    statusByPath.delete(path.split("?")[0]);
    await cdp.send("Page.navigate", { url: urlFor(path) });
    await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === path.split("?")[0], 15000);
  };
  const setTrue = (record, ...keys) => { for (const key of keys) record.observations[key] = true; };
  const newRecord = (id) => ({
    id, outcome: "failed", duration_ms: 0,
    counts: Object.fromEntries(FULL_COUNT_FIELDS.map((key) => [key, 0])),
    observations: Object.fromEntries(FULL_OBSERVATION_FIELDS.map((key) => [key, false]))
  });
  const login = async (record, mode = "staff", pauseConnect = false) => {
    let pauseScript = null;
    if (pauseConnect) {
      pauseScript = await cdp.send("Page.addScriptToEvaluateOnNewDocument", { source: "window.__phase170PauseLiveSocket = true;" });
    }
    await go("/login");
    await waitFor(() => cdp.evaluate("document.querySelector('form') !== null"), Boolean, 10000);
    const actionMode = mode === "staff" ? "" : `?mode=${mode}`;
    await cdp.evaluate(`(() => { const form = document.querySelector('form'); if (!form) return false; form.action = ${JSON.stringify(urlFor(`/login${actionMode}`))}; form.requestSubmit(); return true; })()`);
    await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === adminPath, 15000);
    if (pauseScript) await cdp.send("Page.removeScriptToEvaluateOnNewDocument", { identifier: pauseScript.identifier });
    const status = await waitFor(() => statusByPath.get(adminPath), (value) => Number.isInteger(value), 10000);
    if (status === 200 && mode === "staff" && !pauseConnect) {
      await waitFor(() => cdp.evaluate("window.liveSocket && document.querySelector('.phx-connected') !== null"), Boolean, 15000);
      await waitFor(() => hostObservations(), (obs) => obs.live_connected_allowed > 0, 15000);
      record.observations.static_200 = true;
      record.observations.join_allowed = true;
      record.observations.protected_content = await cdp.evaluate("document.body.innerText.includes('Apps and access')");
      record.observations.prefix_ok = (await cdp.evaluate("location.pathname")) === adminPath;
    }
    return { status, pauseScript };
  };
  const clickLivePath = async (record, pathname, callback) => {
    const docsBefore = events().documentNavigations;
    const click = await cdp.evaluate(`(() => { const link = [...document.querySelectorAll('a[data-phx-link][href]')].find((node) => new URL(node.href).pathname === ${JSON.stringify(pathname)}); if (!link) return false; link.click(); return true; })()`);
    if (!click) throw new Error("clients_link_missing");
    await waitFor(() => cdp.evaluate("location.pathname"), (path) => path === pathname, 15000);
    await callback();
    if (events().documentNavigations !== docsBefore) throw new Error("document_reload_during_navigation");
    record.counts.navigations += 1;
  };
  const filterClients = async (record) => {
    const before = await hostObservations();
    const docsBefore = events().documentNavigations;
    const submitted = await cdp.evaluate(`(() => { const form = document.querySelector('form[phx-submit="filter_inventory"]'); const input = document.querySelector('#client_search'); if (!form || !input) return false; input.value = "Phase 170 Browser App"; input.dispatchEvent(new Event('input', {bubbles: true})); form.requestSubmit(); return true; })()`);
    if (!submitted) throw new Error("clients_link_missing");
    await waitFor(() => cdp.evaluate("location.search"), (search) => search.includes("q="), 15000);
    await waitFor(async () => hostObservations(), (obs) => obs.params > before.params, 15000);
    if (events().documentNavigations !== docsBefore) throw new Error("document_reload_during_navigation");
    setTrue(record, "params_patch", "prefix_ok");
    record.counts.navigations += 1;
  };
  const readHttpStatus = async (path) => waitFor(() => statusByPath.get(path), (value) => Number.isInteger(value), 10000);
  const records = [];

  for (const id of FULL_CASE_IDS) {
    const record = newRecord(id);
    const started = performance.now();
    const initialEvents = beforeEvents();
    let initialHost = null;
    let finalHost = null;
    try {
      await blank();
      initialHost = await hostObservations();
      if (id === "allowed_entry" || id === "assets" || id === "live_navigation" || id === "params_patch" || id === "detail_task" || id === "allowed_reconnect") {
        const joinStart = events().joins;
        const { status } = await login(record);
        if (status !== 200) throw new Error("browser_failure");
        const afterLoginEvents = events();
        record.counts.assets = Math.max(0, afterLoginEvents.assetResponses - initialEvents.assetResponses);
        record.counts.websocket_handshakes = Math.max(0, afterLoginEvents.handshakes - initialEvents.handshakes);
        record.counts.successful_joins = Math.max(0, afterLoginEvents.joins - joinStart);
        const current = await hostObservations();
        if (id === "allowed_entry") {
          if (record.counts.successful_joins < 1) throw new Error("live_join_timeout");
        } else if (id === "assets") {
          if (record.counts.assets < 2) throw new Error("assets_missing");
          setTrue(record, "assets_200");
        } else if (id === "live_navigation") {
          const before = current.live_connected;
          await clickLivePath(record, clientsPath, async () => {
            await waitFor(() => cdp.evaluate("document.body.innerText"), (text) => text.includes("Apps"), 15000);
            await waitFor(async () => hostObservations(), (obs) => obs.live_connected > before, 15000);
          });
          setTrue(record, "live_navigation", "prefix_ok");
        } else if (id === "params_patch") {
          const before = current.live_connected;
          await clickLivePath(record, clientsPath, async () => {
            await waitFor(async () => hostObservations(), (obs) => obs.live_connected > before, 15000);
          });
          await filterClients(record);
        } else if (id === "detail_task") {
          const before = current.live_connected;
          await clickLivePath(record, clientsPath, async () => {
            await waitFor(async () => hostObservations(), (obs) => obs.live_connected > before, 15000);
          });
          const detailPath = `${clientsPath}/phase170-browser-client`;
          const beforeParams = (await hostObservations()).params;
          await clickLivePath(record, detailPath, async () => {
            await waitFor(() => cdp.evaluate("document.body.innerText"), (text) => text.includes("Phase 170 Browser App"), 15000);
            await waitFor(async () => hostObservations(), (obs) => obs.params > beforeParams, 15000);
          });
          const editPath = `${detailPath}/edit`;
          const beforeEditParams = (await hostObservations()).params;
          await clickLivePath(record, editPath, async () => {
            await waitFor(() => cdp.evaluate("document.querySelector('[data-client-task-context]') !== null"), Boolean, 15000);
            await waitFor(async () => hostObservations(), (obs) => obs.params > beforeEditParams, 15000);
          });
          setTrue(record, "detail_task", "prefix_ok");
        } else if (id === "allowed_reconnect") {
          const closeStart = events().socketCloses;
          const joinsBefore = events().joins;
          const protectedBefore = current.protected_callbacks;
          await cdp.evaluate("window.liveSocket.disconnect()");
          await waitFor(() => events().socketCloses, (value) => value > closeStart, 10000);
          setTrue(record, "socket_closed");
          await cdp.evaluate("window.liveSocket.connect()");
          await waitFor(() => events().joins, (value) => value > joinsBefore, 15000);
          await waitFor(async () => hostObservations(), (obs) => obs.live_connected_allowed > current.live_connected_allowed, 15000);
          await cdp.evaluate("window.liveSocket.execJS(document.querySelector('#lockspire-admin-nav a[data-phx-link]'), '');").catch(() => {});
          const afterReconnect = await hostObservations();
          record.observations.reconnect_join = afterReconnect.protected_callbacks > protectedBefore;
          const navBefore = afterReconnect.live_connected;
          await clickLivePath(record, clientsPath, async () => {
            await waitFor(() => cdp.evaluate("document.body.innerText"), (text) => text.includes("Apps"), 15000);
            await waitFor(async () => hostObservations(), (obs) => obs.live_connected > navBefore, 15000);
          });
          setTrue(record, "interaction_after_reconnect");
          record.counts.websocket_handshakes = events().handshakes - initialEvents.handshakes;
          record.counts.successful_joins = events().joins - joinStart;
        }
      } else if (id === "anonymous_http_denied" || id === "nonstaff_http_denied") {
        if (id === "nonstaff_http_denied") {
          await go("/login");
          const formReady = await waitFor(() => cdp.evaluate("document.querySelector('form') !== null"), Boolean, 10000);
          if (!formReady) throw new Error("login_form_missing");
          await cdp.evaluate(`(() => { const form = document.querySelector('form'); form.action = ${JSON.stringify(urlFor("/login?mode=nonstaff"))}; form.requestSubmit(); return true; })()`);
          await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === adminPath, 15000);
        } else {
          await go(adminPath);
        }
        const status = await readHttpStatus(adminPath);
        finalHost = await hostObservations();
        const denied = status === 403 && finalHost.http_denied > initialHost.http_denied && !await cdp.evaluate("document.body.innerText.includes('Apps and access')");
        if (!denied) throw new Error("http_denial_missing");
        setTrue(record, id === "anonymous_http_denied" ? "anonymous_denied" : "nonstaff_denied", "protected_content_absent", "prefix_ok");
        record.counts.http_checks = finalHost.http - initialHost.http;
        record.counts.staff_checks = record.counts.http_checks;
      } else if (id === "cached_join_denied") {
        const pause = await cdp.send("Page.addScriptToEvaluateOnNewDocument", { source: "window.__phase170PauseLiveSocket = true;" });
        await go("/login");
        await waitFor(() => cdp.evaluate("document.querySelector('form') !== null"), Boolean, 10000);
        await cdp.evaluate(`(() => { const form = document.querySelector('form'); form.action = ${JSON.stringify(urlFor("/login"))}; form.requestSubmit(); return true; })()`);
        await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === adminPath, 15000);
        await cdp.send("Page.removeScriptToEvaluateOnNewDocument", { identifier: pause.identifier });
        const staticStatus = await readHttpStatus(adminPath);
        const staticProtected = await cdp.evaluate("document.body.innerText.includes('Apps and access') && !!window.liveSocket && !document.querySelector('.phx-connected')");
        if (staticStatus !== 200 || !staticProtected) throw new Error("cached_static_missing");
        setTrue(record, "static_200");
        const before = await hostObservations();
        await control("withdraw");
        const failedStart = events().failedJoins;
        await cdp.evaluate("window.liveSocket.connect()");
        await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === "/login", 15000);
        const after = await hostObservations();
        if (after.live_connected_denied <= before.live_connected_denied || after.protected_callbacks !== before.protected_callbacks || events().failedJoins <= failedStart) throw new Error("denied_join_missing");
        setTrue(record, "cached_join_denied", "protected_content_absent");
        record.counts.staff_checks = (after.live_connected - before.live_connected) + (after.http - before.http);
        record.counts.http_checks = after.http - before.http;
      } else if (id === "reconnect_denied") {
        const joinsBefore = events().joins;
        const { status } = await login(record);
        if (status !== 200 || events().joins <= joinsBefore) throw new Error("live_join_timeout");
        const before = await hostObservations();
        await control("invalidate-session");
        const closeStart = events().socketCloses;
        const failedStart = events().failedJoins;
        await cdp.evaluate("window.liveSocket.disconnect()");
        await waitFor(() => events().socketCloses, (value) => value > closeStart, 10000);
        setTrue(record, "socket_closed");
        await cdp.evaluate("window.liveSocket.connect()");
        await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === "/login", 15000);
        const after = await hostObservations();
        if (after.live_connected_denied <= before.live_connected_denied || after.protected_callbacks !== before.protected_callbacks || events().failedJoins <= failedStart) throw new Error("denied_join_missing");
        setTrue(record, "reconnect_denied", "protected_content_absent");
        record.counts.staff_checks = after.live_connected - before.live_connected;
      } else if (id === "params_denied") {
        await login(record);
        const beforeNav = (await hostObservations()).live_connected;
        await clickLivePath(record, clientsPath, async () => waitFor(async () => hostObservations(), (obs) => obs.live_connected > beforeNav, 15000));
        const before = await hostObservations();
        await control("delete-identity");
        const submitted = await cdp.evaluate(`(() => { const form = document.querySelector('form[phx-submit="filter_inventory"]'); const input = document.querySelector('#client_search'); if (!form || !input) return false; input.value = "no-match"; input.dispatchEvent(new Event('input', {bubbles: true})); form.requestSubmit(); return true; })()`);
        if (!submitted) throw new Error("clients_link_missing");
        await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === "/login", 15000);
        const after = await hostObservations();
        if (after.params_denied <= before.params_denied || after.protected_callbacks !== before.protected_callbacks) throw new Error("denied_params_missing");
        setTrue(record, "params_denied", "protected_content_absent");
        record.counts.params_checks = after.params_denied - before.params_denied;
        record.counts.staff_checks = record.counts.params_checks;
      } else if (id === "public_session_denied" || id === "consent_session_denied") {
        const surface = id === "public_session_denied" ? "public" : "consent";
        const path = `${mount}/__proof/${surface}` || `/__proof/${surface}`;
        await go(path);
        const marker = surface === "public" ? "[data-proof-public-session]" : "[data-proof-consent-session]";
        await waitFor(() => cdp.evaluate(`document.querySelector(${JSON.stringify(marker)}) !== null`), Boolean, 10000);
        const clicked = await cdp.evaluate(`(() => { const link = document.querySelector(${JSON.stringify(marker + " a[href]")}); if (!link) return false; link.click(); return true; })()`);
        if (!clicked) throw new Error("cross_session_link_missing");
        await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === adminPath, 15000);
        const status = await readHttpStatus(adminPath);
        finalHost = await hostObservations();
        if (status !== 403 || finalHost.http_denied <= initialHost.http_denied || await cdp.evaluate("document.body.innerText.includes('Apps and access')")) throw new Error("cross_session_admin_denial_missing");
        setTrue(record, id, "protected_content_absent");
        record.counts.http_checks = finalHost.http - initialHost.http;
        record.counts.staff_checks = record.counts.http_checks;
      } else if (id === "public_discovery" || id === "public_jwks" || id === "public_protocol_error") {
        await go("/login");
        const path = id === "public_discovery" ? `${mount}/.well-known/openid-configuration` : id === "public_jwks" ? `${mount}/jwks` : `${mount}/token`;
        const response = await cdp.evaluate(`(async () => { const options = ${id === "public_protocol_error" ? `{method:"POST", credentials:"omit", headers:{"Accept":"application/json","Content-Type":"application/x-www-form-urlencoded"}, body:"grant_type=proof_unsupported"}` : `{credentials:"omit"}`}; const response = await fetch(${JSON.stringify(urlFor(path))}, options); let error = null; if (${id === "public_protocol_error"}) { try { error = (await response.json()).error; } catch {} } return {status: response.status, error}; })()`);
        finalHost = await hostObservations();
        const checks = finalHost.http + finalHost.live_mount + finalHost.live_connected + finalHost.params + finalHost.params_denied;
        if (checks !== 0) throw new Error("public_route_staff_check");
        setTrue(record, "no_staff_checks");
        if (id === "public_discovery" && response.status === 200) setTrue(record, "discovery_200");
        else if (id === "public_jwks" && response.status === 200) setTrue(record, "jwks_200");
        else if (id === "public_protocol_error" && response.status === 400 && response.error === "unsupported_grant_type") setTrue(record, "protocol_error_shape");
        else throw new Error("public_protocol_status_invalid");
        record.counts.staff_checks = 0;
      }
      finalHost ||= await hostObservations();
      const staffDelta = (finalHost.http || 0) + (finalHost.live_mount || 0) + (finalHost.live_connected || 0) + (finalHost.params || 0) + (finalHost.params_denied || 0) -
        ((initialHost.http || 0) + (initialHost.live_mount || 0) + (initialHost.live_connected || 0) + (initialHost.params || 0) + (initialHost.params_denied || 0));
      if (record.counts.staff_checks === 0 && staffDelta > 0 && !["public_discovery", "public_jwks", "public_protocol_error", "anonymous_http_denied", "nonstaff_http_denied", "public_session_denied", "consent_session_denied"].includes(id)) record.counts.staff_checks = staffDelta;
      record.counts.assets = Math.max(record.counts.assets, events().assetResponses - initialEvents.assetResponses);
      record.counts.websocket_handshakes = Math.max(record.counts.websocket_handshakes, events().handshakes - initialEvents.handshakes);
      record.counts.successful_joins = Math.max(record.counts.successful_joins, events().joins - initialEvents.joins);
      record.outcome = FULL_CASE_EVIDENCE[id].every((key) => record.observations[key]) ? "passed" : "failed";
    } catch (error) {
      record.outcome = "failed";
      const safeFailures = new Set([
        "browser_timeout", "clients_link_missing", "document_reload_during_navigation", "live_join_timeout",
        "assets_missing", "http_denial_missing", "cached_static_missing", "denied_join_missing",
        "denied_params_missing", "cross_session_link_missing", "cross_session_admin_denial_missing",
        "public_route_staff_check", "public_protocol_status_invalid", "login_form_missing", "browser_failure",
        "host_observations_failed", "page_evaluation_failed", "cdp_command_failed", "cdp_command_timeout"
      ]);
      const message = String(error?.message || "");
      record.failure = safeFailures.has(message) ? message : "case_failed";
    }
    record.duration_ms = Math.max(0, Math.round(performance.now() - started));
    records.push(record);
  }
  return records;
}

class CDP {
  constructor(socket) {
    this.socket = socket;
    this.nextId = 0;
    this.pending = new Map();
    this.listeners = new Map();
    socket.addEventListener("message", (event) => {
      let message;
      try { message = JSON.parse(event.data); } catch { return; }
      if (message.id && this.pending.has(message.id)) {
        const pending = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) pending.reject(new Error("cdp_command_failed"));
        else pending.resolve(message.result);
      } else if (message.method) {
        for (const listener of this.listeners.get(message.method) || []) listener(message.params);
      }
    });
  }

  static async connect(url) {
    const socket = new WebSocket(url);
    await timed(new Promise((resolve, reject) => {
      socket.addEventListener("open", resolve, { once: true });
      socket.addEventListener("error", () => reject(new Error("cdp_connect_failed")), { once: true });
    }), 10000, "cdp_connect_timeout");
    return new CDP(socket);
  }

  on(method, listener) {
    if (!this.listeners.has(method)) this.listeners.set(method, []);
    this.listeners.get(method).push(listener);
  }

  send(method, params = {}) {
    const id = ++this.nextId;
    return timed(new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    }), 10000, "cdp_command_timeout");
  }

  async evaluate(expression) {
    const result = await this.send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
    if (result.exceptionDetails) throw new Error("page_evaluation_failed");
    return result.result?.value;
  }
}

async function readInput() {
  let input = "";
  for await (const chunk of process.stdin) input += chunk;
  const value = JSON.parse(input);
  if (!value || typeof value.capability !== "string" || value.capability.length < 32) throw new Error("control_capability_missing");
  return value;
}

async function main() {
  let browser = null;
  let cdp = null;
  let profile = null;
  let result = {
    id: ID, outcome: "failed", duration_ms: 0,
    counts: { assets: 0, websocket_handshakes: 0, successful_joins: 0, navigations: 0 },
    observations: { login: false, overview: false, clients: false, authorized_http: false, connected_hook: false },
    runtime: { node: process.versions.node, chrome: "unknown" }
  };
  let cleanupPromise;
  const cleanup = () => cleanupPromise ||= (async () => {
    try { cdp?.socket.close(); } catch {}
    if (browser?.pid) {
      const exited = browser.exitCode !== null || browser.signalCode !== null;
      const waiting = exited ? Promise.resolve() : new Promise((resolve) => browser.once("exit", resolve));
      try {
        if (process.platform === "win32") browser.kill("SIGTERM");
        else process.kill(-browser.pid, "SIGTERM");
        await timed(waiting, 2500, "chrome_stop_timeout").catch(() => {});
      } catch {}
      try {
        if (process.platform === "win32") browser.kill("SIGKILL");
        else process.kill(-browser.pid, "SIGKILL");
      } catch {}
      await timed(waiting, 1000, "chrome_stop_timeout").catch(() => {});
    }
    if (profile) {
      try { rmSync(profile, { recursive: true, force: false }); result.profile_removed = true; }
      catch { result.profile_removed = false; }
    }
  })();
  let interrupted = false;
  const interrupt = (code) => {
    if (interrupted) return;
    interrupted = true;
    result.outcome = "failed";
    cleanup().finally(() => process.exit(code));
  };
  const terminate = () => interrupt(143);
  const cancel = () => interrupt(130);
  process.on("SIGTERM", terminate);
  process.on("SIGINT", cancel);
  const deadline = setTimeout(() => interrupt(124), 175000);
  const started = performance.now();
  let stage = "preflight";
  let loginGetStatus = 0;
  let loginGetIsHtml = false;
  let loginGetRequestId = null;
  let loginGetBodyBytes = 0;
  let loginPostStatus = 0;
  let loginPostSeen = false;
  let loginPostFailed = false;
  let loginSubmitEventSeen = false;
  let assetResponses = 0;
  let failedJoins = 0;
  let scenarioMode = "tracer";
  const statusByPath = new Map();
  try {
    if (!supportedNode() || typeof fetch !== "function" || typeof WebSocket !== "function") throw new Error("node_unsupported");
    const input = await readInput();
    scenarioMode = input.scenario === "full" ? "full" : "tracer";
    const origin = new URL(input.origin);
    if (origin.hostname !== "127.0.0.1" || !["http:", "https:"].includes(origin.protocol)) throw new Error("origin_invalid");
    const mount = input.mount === "/" ? "" : input.mount;
    if (!["", "/lockspire", "/teams/ops/identity"].includes(mount)) throw new Error("mount_invalid");
    const executable = chromePath();
    stage = "chrome_start";
    profile = mkdtempSync(path.join(input.runRoot || os.tmpdir(), "chrome-profile-"));
    browser = spawn(executable, [
      "--headless=new", "--no-first-run", "--no-default-browser-check", "--disable-background-networking",
      "--remote-debugging-port=0", `--user-data-dir=${profile}`, "about:blank"
    ], { stdio: "ignore", detached: process.platform !== "win32" });
    let spawnFailed = false;
    browser.on("error", () => { spawnFailed = true; });
    const activeFile = path.join(profile, "DevToolsActivePort");
    let port = null;
    const launchDeadline = Date.now() + 15000;
    while (Date.now() < launchDeadline && browser.exitCode === null && !spawnFailed) {
      try { port = Number(readFileSync(activeFile, "utf8").split("\n")[0]); if (port > 0) break; } catch {}
      await delay(50);
    }
    if (!port) throw new Error(spawnFailed ? "chrome_spawn_failed" : "chrome_start_failed");
    const targetResponse = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT", signal: AbortSignal.timeout(5000) });
    if (!targetResponse.ok) throw new Error("chrome_target_failed");
    const target = await targetResponse.json();
    cdp = await CDP.connect(target.webSocketDebuggerUrl);
    stage = "cdp_setup";
    const assets = new Set();
    const requestMethods = new Map();
    let handshakes = 0;
    let joins = 0;
    let socketCloses = 0;
    let documentNavigations = 0;
    let mainLoaderId = null;
    cdp.on("Network.responseReceived", ({ response }) => {
      const pathname = new URL(response.url).pathname;
      statusByPath.set(pathname, response.status);
      if (response.status >= 200 && response.status < 300 && /\/(?:phoenix\.js|phoenix_live_view\.js)$/.test(response.url)) {
        assets.add(response.url);
        assetResponses += 1;
      }
    });
    cdp.on("Network.requestWillBeSent", ({ requestId, request }) => {
      requestMethods.set(requestId, request.method);
      if (request.method === "POST" && new URL(request.url).pathname === "/login") loginPostSeen = true;
    });
    cdp.on("Network.responseReceived", ({ requestId, response }) => {
      if (new URL(response.url).pathname === "/login") {
        if (requestMethods.get(requestId) === "GET") {
          loginGetStatus = response.status;
          loginGetIsHtml = response.mimeType === "text/html";
          loginGetRequestId = requestId;
        }
        if (requestMethods.get(requestId) === "POST") loginPostStatus = response.status;
      }
    });
    cdp.on("Network.loadingFailed", ({ requestId }) => {
      if (requestMethods.get(requestId) === "POST") loginPostFailed = true;
    });
    cdp.on("Network.loadingFinished", ({ requestId, encodedDataLength }) => {
      if (requestId === loginGetRequestId) loginGetBodyBytes = Number.isFinite(encodedDataLength) ? encodedDataLength : 0;
    });
    cdp.on("Network.webSocketHandshakeResponseReceived", () => { handshakes += 1; });
    cdp.on("Network.webSocketFrameReceived", ({ response }) => {
      if (isSuccessfulJoinFrame(response.payloadData)) joins += 1;
      if (isFailedJoinFrame(response.payloadData)) failedJoins += 1;
    });
    cdp.on("Network.webSocketClosed", () => { socketCloses += 1; });
    cdp.on("Page.frameNavigated", ({ frame }) => {
      if (!frame.parentId && frame.loaderId) {
        if (mainLoaderId && mainLoaderId !== frame.loaderId) documentNavigations += 1;
        mainLoaderId = frame.loaderId;
      }
    });
    await cdp.send("Page.enable");
    await cdp.send("Runtime.enable");
    await cdp.send("Network.enable");
    await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
    const adminPath = `${mount}/admin` || "/admin";
    const control = async (route, method = "POST") => {
      const response = await fetch(`${origin.origin}/__proof/${route}`, {
        method,
        headers: { "x-lockspire-proof-capability": input.capability },
        signal: AbortSignal.timeout(5000)
      });
      if (!response.ok) throw new Error("host_observations_failed");
      return response;
    };
    const hostObservations = async () => (await (await control("observations", "GET")).json());
    const seeded = await (await control("seed")).json();
    if (seeded.client_id !== "phase170-browser-client") throw new Error("host_observations_failed");
    const events = () => ({ assetResponses, handshakes, joins, failedJoins, socketCloses, documentNavigations });
    if (scenarioMode === "full") {
      stage = "full_matrix";
      result.id = "full";
      result.scenarios = await runFullMatrix({ cdp, origin, input, mount, control, hostObservations, events, statusByPath });
      result.outcome = validateFullScenarios(result.scenarios) ? "passed" : "failed";
      if (result.outcome !== "passed") result.failure = "case_failed";
      result.runtime.chrome = (await cdp.send("Browser.getVersion")).product;
    } else {
    stage = "login_load";
    await cdp.send("Page.navigate", { url: `${origin.origin}/login` });
    await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === "/login");
    await waitFor(() => cdp.evaluate("document.querySelector('form') !== null"), Boolean);
    stage = "login_submit";
    await cdp.evaluate("window.__phase170SubmitSeen = false; document.querySelector('form').addEventListener('submit', () => { window.__phase170SubmitSeen = true; }, {once: true})");
    await cdp.evaluate("document.querySelector('form')?.requestSubmit()");
    loginSubmitEventSeen = await cdp.evaluate("window.__phase170SubmitSeen === true");
    stage = "login_redirect";
    await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === adminPath);
    result.observations.login = true;
    stage = "overview_render";
    result.observations.overview = await waitFor(
      () => cdp.evaluate("({path: location.pathname, text: document.body.innerText, connected: !!document.querySelector('.phx-connected')})"),
      (page) => page.path === adminPath && page.text.includes("Apps and access")
    ).then(() => true);
    stage = "live_socket_connected";
    await waitFor(() => cdp.evaluate("window.liveSocket && document.querySelector('.phx-connected') !== null"), Boolean);
    stage = "live_join";
    await waitFor(() => joins, (count) => count > 0);
    const expectedClients = `${adminPath}/clients`;
    stage = "clients_navigation";
    const beforeClientsHook = (await hostObservations()).live_connected;
    const beforeClientsDocument = documentNavigations;
    const clicked = await cdp.evaluate(`(() => { const link = [...document.querySelectorAll('a[data-phx-link][href]')].find((node) => new URL(node.href).pathname === ${JSON.stringify(expectedClients)}); if (!link) return false; link.click(); return true; })()`);
    if (!clicked) throw new Error("clients_link_missing");
    stage = "clients_destination";
    await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === expectedClients);
    stage = "clients_content";
    await waitFor(() => cdp.evaluate("document.body.innerText"), (text) => text.includes("Apps"));
    stage = "clients_hook";
    await waitFor(async () => (await hostObservations()).live_connected, (count) => count > beforeClientsHook);
    if (documentNavigations !== beforeClientsDocument) throw new Error("document_reload_during_navigation");
    result.observations.clients = true;
    result.counts.navigations = 1;
    let beforeParams = (await hostObservations()).params;
    const filterSubmitted = await cdp.evaluate(`(() => { const form = document.querySelector('form[phx-submit="filter_inventory"]'); const field = document.querySelector('#client_search'); if (!form || !field) return false; field.value = "Phase 170 Browser App"; field.dispatchEvent(new Event('input', {bubbles: true})); form.requestSubmit(); return true; })()`);
    if (!filterSubmitted) throw new Error("clients_link_missing");
    await waitFor(() => cdp.evaluate("({search: location.search, text: document.body.innerText})"), (page) => page.search.includes("Phase+170+Browser+App") || page.search.includes("Phase%20170%20Browser%20App"));
    const afterParams = await waitFor(async () => (await hostObservations()).params, (count) => count > beforeParams);
    if (afterParams <= beforeParams) throw new Error("browser_failure");
    result.counts.navigations += 1;
    const detailPath = `${expectedClients}/phase170-browser-client`;
    beforeParams = afterParams;
    const beforeDetailDocument = documentNavigations;
    const detailClicked = await cdp.evaluate(`(() => { const link = [...document.querySelectorAll('a[data-phx-link][href]')].find((node) => new URL(node.href).pathname === ${JSON.stringify(detailPath)}); if (!link) return false; link.click(); return true; })()`);
    if (!detailClicked) throw new Error("clients_link_missing");
    await waitFor(() => cdp.evaluate("({path: location.pathname, text: document.body.innerText})"), (page) => page.path === detailPath && page.text.includes("Phase 170 Browser App"));
    await waitFor(async () => (await hostObservations()).params, (count) => count > beforeParams);
    if (documentNavigations !== beforeDetailDocument) throw new Error("document_reload_during_navigation");
    result.counts.navigations += 1;
    const editPath = `${detailPath}/edit`;
    const beforeEditParams = (await hostObservations()).params;
    const beforeEditDocument = documentNavigations;
    const editClicked = await cdp.evaluate(`(() => { const link = [...document.querySelectorAll('a[data-phx-link][href]')].find((node) => new URL(node.href).pathname === ${JSON.stringify(editPath)}); if (!link) return false; link.click(); return true; })()`);
    if (!editClicked) throw new Error("clients_link_missing");
    await waitFor(() => cdp.evaluate("({path: location.pathname, marker: !!document.querySelector('[data-client-task-context]')})"), (page) => page.path === editPath && page.marker);
    await waitFor(async () => (await hostObservations()).params, (count) => count > beforeEditParams);
    if (documentNavigations !== beforeEditDocument) throw new Error("document_reload_during_navigation");
    result.counts.navigations += 1;
    const beforeClose = socketCloses;
    const beforeReconnectJoin = joins;
    await cdp.evaluate("window.liveSocket.disconnect()");
    await waitFor(() => socketCloses, (count) => count > beforeClose);
    await cdp.evaluate("window.liveSocket.connect()");
    await waitFor(() => joins, (count) => count > beforeReconnectJoin);
    await waitFor(() => cdp.evaluate("document.querySelector('.phx-connected') !== null"), Boolean);
    result.counts.navigations += 1;
    const observationsResponse = await fetch(`${origin.origin}/__proof/observations`, {
      headers: { "x-lockspire-proof-capability": input.capability }, signal: AbortSignal.timeout(5000)
    });
    if (!observationsResponse.ok) throw new Error("host_observations_failed");
    const host = await observationsResponse.json();
    result.observations.authorized_http = Number.isInteger(host.http) && host.http > 0;
    result.observations.connected_hook = Number.isInteger(host.live_connected) && host.live_connected > 0;
    result.counts.assets = assets.size;
    result.counts.websocket_handshakes = handshakes;
    result.counts.successful_joins = joins;
    result.runtime.chrome = (await cdp.send("Browser.getVersion")).product;
    result.outcome = socketCloses > 0 && validateTracerEvidence(result.observations, result.counts) ? "passed" : "failed";
    }
  } catch (error) {
    const message = String(error?.message || "");
    const timeoutFailure = message === "browser_timeout" ? `${stage}_timeout` : null;
    const loginLoadFailure = stage === "login_load" && message === "browser_timeout"
      ? !loginGetIsHtml ? "login_response_non_html" : loginGetBodyBytes <= 0 ? "login_response_empty" : "login_form_missing"
      : null;
    const safeFailure = stage === "login_redirect" && message === "browser_timeout" && loginPostStatus ? `login_redirect_status_${loginPostStatus}` : null;
    const loginSubmissionFailure = stage === "login_redirect" && message === "browser_timeout"
      ? loginPostFailed ? "login_post_network_failed" : loginPostSeen ? "login_post_no_redirect" : loginSubmitEventSeen ? "login_post_not_observed" : "login_post_not_sent"
      : null;
    const loginPageFailure = message === "login_form_missing" ? "login_form_missing" : message.startsWith("login_page_status_") && /^login_page_status_(?:200|403|404|500)$/.test(message) ? message : null;
    const allowed = new Set(["chrome_missing", "node_unsupported", "origin_invalid", "mount_invalid", "chrome_spawn_failed", "chrome_start_failed", "chrome_target_failed", "browser_timeout", "login_load_timeout", "login_response_non_html", "login_response_empty", "login_path_mismatch", "login_form_missing", "login_content_type_invalid", "login_response_content_missing", "login_page_status_200", "login_page_status_403", "login_page_status_404", "login_page_status_500", "login_redirect_timeout", "login_post_not_sent", "login_post_not_observed", "login_post_network_failed", "login_post_no_redirect", "login_redirect_status_302", "login_redirect_status_403", "login_redirect_status_404", "login_redirect_status_422", "login_redirect_status_500", "overview_render_timeout", "live_socket_connected_timeout", "live_join_timeout", "clients_render_timeout", "clients_destination_timeout", "clients_content_timeout", "clients_hook_timeout", "document_reload_during_navigation", "cdp_connect_failed", "cdp_connect_timeout", "cdp_command_failed", "cdp_command_timeout", "page_evaluation_failed", "clients_link_missing", "host_observations_failed", "control_capability_missing"]);
    result.failure = loginLoadFailure && allowed.has(loginLoadFailure) ? loginLoadFailure : loginPageFailure && allowed.has(loginPageFailure) ? loginPageFailure : safeFailure && allowed.has(safeFailure) ? safeFailure : loginSubmissionFailure && allowed.has(loginSubmissionFailure) ? loginSubmissionFailure : timeoutFailure && allowed.has(timeoutFailure) ? timeoutFailure : allowed.has(message) ? message : "browser_failure";
  } finally {
    result.stage = stage;
    result.duration_ms = Math.max(0, Math.round(performance.now() - started));
    await cleanup();
    clearTimeout(deadline);
    process.off("SIGTERM", terminate);
    process.off("SIGINT", cancel);
    console.log(JSON.stringify(result));
  }
  return result.outcome === "passed" && result.profile_removed === true ? 0 : 1;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().then((code) => { process.exitCode = code; }).catch(() => { process.stdout.write('{"failure":"runner_failure"}\n'); process.exitCode = 1; });
}

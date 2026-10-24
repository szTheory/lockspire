import { spawn } from "node:child_process";
import { accessSync, constants, mkdtempSync, readFileSync, rmSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { setTimeout as delay } from "node:timers/promises";

const ID = "tracer.browser_join_navigation";
const MAX_MS = 30000;

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

export function isSuccessfulJoinFrame(payload) {
  try {
    const frame = JSON.parse(payload);
    return Array.isArray(frame) && frame[3] === "phx_reply" &&
      frame[4]?.status === "ok" && frame[4]?.response && typeof frame[4].response === "object";
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
  try {
    if (!supportedNode() || typeof fetch !== "function" || typeof WebSocket !== "function") throw new Error("node_unsupported");
    const input = await readInput();
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
    cdp.on("Network.responseReceived", ({ response }) => {
      if (response.status >= 200 && response.status < 300 && /\/(?:phoenix\.js|phoenix_live_view\.js)$/.test(response.url)) assets.add(response.url);
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
    });
    await cdp.send("Page.enable");
    await cdp.send("Runtime.enable");
    await cdp.send("Network.enable");
    stage = "login_load";
    await cdp.send("Page.navigate", { url: `${origin.origin}/login` });
    await waitFor(() => cdp.evaluate("location.pathname"), (pathname) => pathname === "/login");
    await waitFor(() => cdp.evaluate("document.querySelector('form') !== null"), Boolean);
    stage = "login_submit";
    await cdp.evaluate("window.__phase170SubmitSeen = false; document.querySelector('form').addEventListener('submit', () => { window.__phase170SubmitSeen = true; }, {once: true})");
    await cdp.evaluate("document.querySelector('form')?.requestSubmit()");
    loginSubmitEventSeen = await cdp.evaluate("window.__phase170SubmitSeen === true");
    const adminPath = `${mount}/admin` || "/admin";
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
    const clicked = await cdp.evaluate(`(() => { const link = [...document.querySelectorAll('a[href]')].find((node) => new URL(node.href).pathname === ${JSON.stringify(expectedClients)}); if (!link) return false; link.click(); return true; })()`);
    if (!clicked) throw new Error("clients_link_missing");
    stage = "clients_render";
    await waitFor(() => cdp.evaluate("({path: location.pathname, text: document.body.innerText})"), (page) => page.path === expectedClients && page.text.includes("Apps"));
    await waitFor(() => joins, (count) => count > 0);
    result.observations.clients = true;
    result.counts.navigations = 1;
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
    result.outcome = result.observations.login && result.observations.overview && result.observations.clients &&
      result.observations.authorized_http && result.observations.connected_hook && assets.size >= 2 && handshakes > 0 && joins > 0 ? "passed" : "failed";
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
    const allowed = new Set(["chrome_missing", "node_unsupported", "origin_invalid", "mount_invalid", "chrome_spawn_failed", "chrome_start_failed", "chrome_target_failed", "browser_timeout", "login_load_timeout", "login_response_non_html", "login_response_empty", "login_path_mismatch", "login_form_missing", "login_content_type_invalid", "login_response_content_missing", "login_page_status_200", "login_page_status_403", "login_page_status_404", "login_page_status_500", "login_redirect_timeout", "login_post_not_sent", "login_post_not_observed", "login_post_network_failed", "login_post_no_redirect", "login_redirect_status_302", "login_redirect_status_403", "login_redirect_status_404", "login_redirect_status_422", "login_redirect_status_500", "overview_render_timeout", "live_socket_connected_timeout", "live_join_timeout", "clients_render_timeout", "cdp_connect_failed", "cdp_connect_timeout", "cdp_command_failed", "cdp_command_timeout", "page_evaluation_failed", "clients_link_missing", "host_observations_failed", "control_capability_missing"]);
    result.failure = loginLoadFailure && allowed.has(loginLoadFailure) ? loginLoadFailure : loginPageFailure && allowed.has(loginPageFailure) ? loginPageFailure : safeFailure && allowed.has(safeFailure) ? safeFailure : loginSubmissionFailure && allowed.has(loginSubmissionFailure) ? loginSubmissionFailure : timeoutFailure && allowed.has(timeoutFailure) ? timeoutFailure : allowed.has(message) ? message : "browser_failure";
  } finally {
    result.stage = stage;
    result.duration_ms = Math.max(0, Math.round(performance.now() - started));
    try { cdp?.socket.close(); } catch {}
    if (browser && browser.exitCode === null) {
      try {
        if (process.platform === "win32") browser.kill();
        else process.kill(-browser.pid, "SIGTERM");
        await timed(new Promise((resolve) => browser.once("exit", resolve)), 3000, "chrome_stop_timeout").catch(() => {
          if (process.platform === "win32") browser.kill("SIGKILL");
          else process.kill(-browser.pid, "SIGKILL");
        });
      } catch {}
    }
    if (profile) {
      try { rmSync(profile, { recursive: true, force: false }); } catch { result.profile_removed = false; }
      if (result.profile_removed !== false) result.profile_removed = true;
    }
    console.log(JSON.stringify(result));
  }
  return result.outcome === "passed" && result.profile_removed === true ? 0 : 1;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().then((code) => { process.exitCode = code; }).catch(() => { process.stdout.write('{"failure":"runner_failure"}\n'); process.exitCode = 1; });
}

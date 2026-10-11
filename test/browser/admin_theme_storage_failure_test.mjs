import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync } from "node:fs";
import { readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const outputDir = path.join(
  repoRoot,
  ".planning/phases/147-surface-coherence-and-working-preview/captures/gap-closure"
);
const layoutPath = path.join(repoRoot, "lib/lockspire/web/live/admin_layout_live.ex");
const browserSession = "lockspire-p147-theme-storage-failure";
const route = new URL(
  process.env.LOCKSPIRE_THEME_FAILURE_URL || "http://127.0.0.1:4123/lockspire/admin/clients"
);
const sourceRevision = process.env.LOCKSPIRE_EXPECTED_SOURCE_REVISION;

function browser(session, ...args) {
  return execFileSync("agent-browser", ["--session", session, ...args], {
    cwd: repoRoot,
    encoding: "utf8",
    timeout: 60_000,
    maxBuffer: 2 * 1024 * 1024
  }).trim();
}

function browserJson(session, script) {
  const raw = browser(session, "eval", script);
  const first = JSON.parse(raw);
  return typeof first === "string" ? JSON.parse(first) : first;
}

function fingerprint(value) {
  const bytes = Buffer.from(value, "utf8");
  return { bytes: bytes.length, sha256: createHash("sha256").update(bytes).digest("hex") };
}

function normalizedFingerprint(value) {
  return fingerprint(value.trim());
}

function sourceCss() {
  const env = {
    ...process.env,
    ASDF_ELIXIR_VERSION: "1.20.4-otp-29",
    ASDF_ERLANG_VERSION: "29.1.1",
    MIX_ENV: "dev"
  };
  const encoded = execFileSync(
    "mix",
    ["run", "--no-start", "-e", "IO.write(Base.encode64(Lockspire.Web.Admin.CSS.get()))"],
    { cwd: repoRoot, encoding: "utf8", env, timeout: 120_000, maxBuffer: 2 * 1024 * 1024 }
  )
    .split(/\r?\n/)
    .findLast((line) => /^[A-Za-z0-9+/]+={0,2}$/.test(line));
  assert.ok(encoded, "mix run returned the source stylesheet fingerprint input");
  return Buffer.from(encoded, "base64").toString("utf8");
}

function ensureOpsSession(session) {
  browser(session, "open", route.href);
  let current = browser(session, "get", "url");
  if (new URL(current).pathname === "/login") {
    browser(
      session,
      "eval",
      'document.querySelector("#login").value = "ops"; document.querySelector("form").requestSubmit(); "submitted"'
    );
    browser(session, "wait", "2000");
    current = browser(session, "get", "url");
  }

  assert.equal(new URL(current).pathname, route.pathname, "synthetic ops sign-in returns to the requested route");
  const baseline = browserJson(
    session,
    'JSON.stringify({route: location.pathname, title: document.title, hasTheme: Boolean(document.querySelector("[data-lockspire-theme-select]")), synthetic: document.body.innerText.includes("Billingo")})'
  );
  assert.equal(baseline.route, route.pathname);
  assert.ok(baseline.hasTheme, "mounted admin route contains the native theme selector");
  assert.ok(baseline.synthetic, "the disposable page shows the synthetic Billingo data identity");
  return browserJson(
    session,
    'JSON.stringify({userAgent: navigator.userAgent, servedCss: document.querySelector("style")?.textContent || ""})'
  );
}

async function exerciseFailure({ operation, theme, expectedStatus, screenshot }) {
  const session = `${browserSession}-${operation}`;
  const secret = "SYNTHETIC_STORAGE_FAILURE_SECRET_DO_NOT_RENDER";

  try {
    browser(session, "set", "media", "dark");
    const browserBaseline = ensureOpsSession(session);
    assert.equal(browserBaseline.servedCss.length > 0, true, "the shell stylesheet is present on the failure route");

    const result = browserJson(session, `
      (async () => {
        const operation = ${JSON.stringify(operation)};
        const theme = ${JSON.stringify(theme)};
        const secret = ${JSON.stringify(secret)};
        const style = document.querySelector("style").textContent;
        const shell = document.querySelector(".lockspire-admin-shell").outerHTML;
        const shellScript = Array.from(document.scripts).find((node) => node.textContent.includes("lockspire-admin-theme"))?.textContent;
        if (!shellScript) throw new Error("shared shell script was not found");
        const initScript = "(() => {"
          + "const operation = " + JSON.stringify(operation) + ";"
          + "const secret = " + JSON.stringify(secret) + ";"
          + "const values = { \\\"lockspire-admin-theme\\\": \\\"dark\\\" };"
          + "const calls = [];"
          + "const storage = { getItem(key) { calls.push(\\\"getItem\\\"); if (operation === \\\"getItem\\\") throw new DOMException(secret, \\\"SecurityError\\\"); return values[key] ?? null; },"
          + "setItem(key, value) { calls.push(\\\"setItem\\\"); if (operation === \\\"setItem\\\") throw new DOMException(secret, \\\"QuotaExceededError\\\"); values[key] = value; },"
          + "removeItem(key) { calls.push(\\\"removeItem\\\"); if (operation === \\\"removeItem\\\") throw new DOMException(secret, \\\"SecurityError\\\"); delete values[key]; } };"
          + "Object.defineProperty(window, \\\"__lockspireThemeStorage\\\", { configurable: true, value: { values, calls } });"
          + "Object.defineProperty(window, \\\"localStorage\\\", { configurable: true, value: storage });"
          + "})();";
        const safeScript = (script) => script.replace(/<\\/script/gi, "<\\\\/script");
        const frame = document.createElement("iframe");
        frame.title = "Theme storage failure verification";
        frame.style.cssText = "position:fixed;inset:0;width:100vw;height:100vh;border:0;z-index:2147483647";
        document.body.replaceChildren(frame);
        frame.srcdoc = "<!doctype html><html><head><meta charset=\\\"utf-8\\\"><style>" + style + "</style>"
          + "<style>html,body{margin:0;min-height:100%;background:transparent}</style></head><body>"
          + "<script>" + safeScript(initScript) + "</script><script>" + safeScript(shellScript) + "</script>" + shell + "</body></html>";
        await new Promise((resolve) => frame.addEventListener("load", resolve, { once: true }));
        const page = frame.contentWindow;
        if (theme !== null) {
          const select = page.document.querySelector("[data-lockspire-theme-select]");
          select.value = theme;
          select.dispatchEvent(new page.Event("change", { bubbles: true }));
        }
        await new Promise((resolve) => page.requestAnimationFrame(() => page.requestAnimationFrame(resolve)));
        const pageShell = page.document.querySelector(".lockspire-admin-shell");
        const status = page.document.querySelector("[data-lockspire-theme-status]");
        const storage = page.__lockspireThemeStorage;
        return JSON.stringify({
          operation,
          route: location.pathname + location.search,
          selectedTheme: page.document.querySelector("[data-lockspire-theme-select]").value,
          themeAttribute: page.document.documentElement.getAttribute("data-theme"),
          systemDarkPreference: page.matchMedia("(prefers-color-scheme: dark)").matches,
          effectiveBackground: page.getComputedStyle(pageShell).backgroundColor,
          status: status?.textContent || "",
          statusRole: status?.getAttribute("role"),
          storedPreference: storage.values["lockspire-admin-theme"] ?? null,
          calls: storage.calls,
          exceptionRendered: page.document.body.innerText.includes(secret)
        });
      })()
    `);
    assert.equal(result.operation, operation);
    assert.equal(result.route, route.pathname, "storage failure keeps the operator on the same route");
    assert.equal(result.status, expectedStatus);
    assert.equal(result.statusRole, "status");
    assert.ok(result.calls.includes(operation), `${operation} was invoked by the browser test`);
    assert.equal(result.exceptionRendered, false, "raw browser exception details are not rendered");

    if (operation === "getItem") {
      assert.equal(result.selectedTheme, "system");
      assert.equal(result.themeAttribute, null);
      assert.equal(result.systemDarkPreference, true);
      assert.equal(result.effectiveBackground, "rgb(11, 18, 32)");
    } else if (operation === "setItem") {
      assert.equal(result.selectedTheme, "light");
      assert.equal(result.themeAttribute, "light");
      assert.equal(result.effectiveBackground, "rgb(248, 250, 252)");
      assert.equal(result.storedPreference, "dark", "failed save preserves the previous stored preference");
    } else {
      assert.equal(result.selectedTheme, "system");
      assert.equal(result.themeAttribute, null);
      assert.equal(result.systemDarkPreference, true);
      assert.equal(result.effectiveBackground, "rgb(11, 18, 32)");
      assert.equal(result.storedPreference, "dark", "failed clear preserves the previous stored preference");
    }

    const screenshotPath = path.join(outputDir, screenshot);
    browser(session, "screenshot", screenshotPath);
    assert.ok((await stat(screenshotPath)).size > 0, `${screenshot} was captured`);
    return { ...result, screenshot };
  } finally {
    browser(session, "close");
  }
}

test("theme storage failures keep the current-page choice and announce the outcome", async () => {
  const source = await readFile(layoutPath, "utf8");
  assert.ok(/let currentPageTheme = "system"/.test(source), "page theme state is independent of saved preference");
  assert.ok(/role="status"/.test(source), "storage outcomes use a status region");
  assert.ok(/aria-live="polite"/.test(source), "the status region is announced accessibly");
  assert.ok(/Your saved theme preference could not be read\./.test(source), "read failure is explained");
  assert.ok(/Your theme is applied for this page, but the saved preference was not updated\./.test(source), "save failure is explained");
  assert.ok(/Your theme is applied for this page, but the saved preference was not cleared\./.test(source), "remove failure is explained");
  assert.ok(!/\$\{_error\.message\}/.test(source), "browser exception details are not rendered");

  assert.ok(sourceRevision, "LOCKSPIRE_EXPECTED_SOURCE_REVISION is supplied");
  const actualHead = execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim();
  assert.equal(sourceRevision, actualHead, "expected source revision is the current committed source");

  mkdirSync(outputDir, { recursive: true });
  const baselineSession = `${browserSession}-baseline`;
  browser(baselineSession, "set", "media", "dark");
  const browserBaseline = ensureOpsSession(baselineSession);
  browser(baselineSession, "close");
  const css = sourceCss();
  const sourceStyle = fingerprint(css);
  const normalizedSourceStyle = normalizedFingerprint(css);
  const servedStyle = fingerprint(browserBaseline.servedCss);
  const normalizedServedStyle = normalizedFingerprint(browserBaseline.servedCss);
  assert.equal(normalizedServedStyle.sha256, normalizedSourceStyle.sha256, "browser serves the committed stylesheet");
  assert.equal(normalizedServedStyle.bytes, normalizedSourceStyle.bytes, "served stylesheet byte length matches source");

  const cases = [];
  cases.push(
    await exerciseFailure({
      operation: "getItem",
      theme: null,
      expectedStatus: "Your saved theme preference could not be read.",
      screenshot: "147-theme-storage-failure-read.png"
    })
  );
  cases.push(
    await exerciseFailure({
      operation: "setItem",
      theme: "light",
      expectedStatus: "Your theme is applied for this page, but the saved preference was not updated.",
      screenshot: "147-theme-storage-failure-save.png"
    })
  );
  cases.push(
    await exerciseFailure({
      operation: "removeItem",
      theme: "system",
      expectedStatus: "Your theme is applied for this page, but the saved preference was not cleared.",
      screenshot: "147-theme-storage-failure-clear.png"
    })
  );

  const receipt = {
    expected_source_revision: sourceRevision,
    app_source_revision: actualHead,
    browser_version: execFileSync("agent-browser", ["--version"], { encoding: "utf8" }).trim(),
    browser_user_agent: browserBaseline.userAgent,
    route: route.pathname,
    synthetic_data_identity: "Phase 145 disposable adoption demo; seeded Billingo records and synthetic ops account",
    source_style: { raw: sourceStyle, normalized: normalizedSourceStyle },
    served_style: { raw: servedStyle, normalized: normalizedServedStyle },
    style_match: normalizedServedStyle.sha256 === normalizedSourceStyle.sha256,
    operating_system_preference: "dark",
    outcomes: cases
  };
  assert.equal(receipt.expected_source_revision, receipt.app_source_revision);
  assert.equal(receipt.style_match, true);
  await writeFile(
    path.join(outputDir, "147-theme-storage-failure-results.json"),
    `${JSON.stringify(receipt, null, 2)}\n`
  );
});

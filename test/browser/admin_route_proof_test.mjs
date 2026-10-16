// Pure-helper tests for the local admin route proof harness. No browser is
// launched. Local-only: the harness is not run in CI (D-05).
import assert from "node:assert/strict";
import test from "node:test";

import {
  ALLOWED_WIDTHS,
  CHANGED_PAGES,
  RESERVED_EXAMPLE_HOST,
  SENSITIVE_PATTERNS,
  assessObservation,
  DEFAULT_THEMES,
  DEFAULT_WIDTHS,
  buildMatrix,
  collectScanText,
  concretePath,
  formatEvidenceRow,
  isLocalDevHost,
  matrixSize,
  parseWidths,
  routeTemplates,
  scanSensitive,
  sectionPlan
} from "./admin_route_proof.mjs";

test("routeTemplates returns the 30 sorted admin templates", () => {
  const routes = routeTemplates();
  assert.equal(routes.length, 30);
  assert.deepEqual(routes, [...routes].sort());
  assert.equal(new Set(routes).size, 30);
  for (const required of [
    "/admin",
    "/admin/overview",
    "/admin/clients/new",
    "/admin/clients/:client_id/edit?workflow=logout-propagation"
  ]) {
    assert.ok(routes.includes(required), `${required} is listed`);
  }
});

test("concretePath substitutes synthetic fixtures", () => {
  assert.equal(
    concretePath("/admin/clients/:client_id/rotate-registration-access-token"),
    "/admin/clients/northstar-payables-portal/rotate-registration-access-token"
  );
  assert.equal(concretePath("/admin/clients/:client_id"), "/admin/clients/billingo-reports-backend");
  assert.equal(concretePath("/admin/clients/:client_id/rotate-secret"), "/admin/clients/billingo-reports-backend/rotate-secret");
  assert.equal(concretePath("/admin/keys/:id"), "/admin/keys/1");
  assert.equal(concretePath("/admin/consents/:id"), "/admin/consents/1");
  assert.equal(concretePath("/admin/tokens/:id"), "/admin/tokens/3");
  assert.equal(concretePath("/admin/overview"), "/admin/overview");
});

test("buildMatrix yields unique route/width/theme/motion entries", () => {
  const matrix = buildMatrix({ widths: [320, 390], themes: ["light", "dark"] });
  assert.equal(matrix.length, 30 * 2 * 2);
  const keys = matrix.map((e) => `${e.route}|${e.width}|${e.theme}|${e.motion}`);
  assert.equal(new Set(keys).size, keys.length);
  const withMotion = buildMatrix({ widths: [320], themes: ["light"], motions: ["default", "reduced-motion"] });
  assert.equal(withMotion.length, 60);
});

test("scanSensitive flags secrets and passes ordinary synthetic copy", () => {
  assert.ok(scanSensitive("-----BEGIN RSA PRIVATE KEY-----").includes("private key"));
  assert.ok(
    scanSensitive("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890").includes(
      "JWT-looking token"
    )
  );
  assert.ok(scanSensitive("client_secret=abcdefghij").includes("plaintext credential"));
  assert.deepEqual(scanSensitive("Billingo Reports Backend has 3 redirect URIs and a healthy signing key."), []);
});

test("field values and data attributes are scanned even when visible text is clean", () => {
  const jwt = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890";
  const inField = collectScanText({
    innerText: "Clients",
    fieldValues: [{ value: jwt, attr: "" }],
    dataAttributes: []
  });
  assert.ok(scanSensitive(inField).includes("JWT-looking token"));

  const inData = collectScanText({
    innerText: "Clients",
    fieldValues: [],
    dataAttributes: [{ name: "data-secret", value: "-----BEGIN PRIVATE KEY-----" }]
  });
  assert.ok(scanSensitive(inData).includes("private key"));

  const clean = collectScanText({
    innerText: "Clients",
    fieldValues: [{ value: "ops", attr: "ops", optionText: "Light" }],
    dataAttributes: [{ name: "data-phx-main", value: "true" }]
  });
  assert.deepEqual(scanSensitive(clean), []);
});

test("hidden text and title, aria-label, alt and href values are scanned", () => {
  const jwt = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890";
  const hidden = collectScanText({ innerText: "Clients", textContent: `Clients ${jwt}` });
  assert.ok(scanSensitive(hidden).includes("JWT-looking token"));

  for (const name of ["title", "aria-label", "alt", "href"]) {
    const text = collectScanText({
      innerText: "Clients",
      attributeValues: [{ name, value: `https://auth.acme-corp.com/cb?access_token=${jwt}` }]
    });
    const hits = scanSensitive(text);
    assert.ok(hits.includes("token parameter") && hits.includes("production-looking hostname"), `${name} is scanned`);
  }
});

test("the harness re-scans the page after the keyboard sweep and before every screenshot", async () => {
  const { readFile } = await import("node:fs/promises");
  const source = await readFile(new URL("./admin_route_proof.mjs", import.meta.url), "utf8");
  const screenshots = source.match(/browser\(session, "screenshot"/g) ?? [];
  const guarded = source.match(/assertNoSensitivePage\(session, template, [^\n]*\);\n\s*browser\(session, "screenshot"/g) ?? [];
  assert.ok(screenshots.length > 0);
  assert.equal(guarded.length, screenshots.length, "every screenshot is preceded by a page scan");
  assert.match(source, /keyboard = keyboardSweep\(session\);\n\s*\/\/[^\n]*\n\s*assertNoSensitivePage\(session, template, "after keyboard sweep"\)/);
});

test("matrixSize and CHANGED_PAGES are derived, not hard-coded", () => {
  assert.equal(matrixSize(), routeTemplates().length * DEFAULT_WIDTHS.length * DEFAULT_THEMES.length);
  assert.equal(matrixSize(), 630);
  assert.equal(CHANGED_PAGES.length, 12);
  const routes = routeTemplates();
  for (const page of CHANGED_PAGES) assert.ok(routes.includes(page), `${page} is a known template`);
});

test("formatEvidenceRow emits 14 cells and fails on overflow", () => {
  const row = formatEvidenceRow({
    route: "/admin/clients",
    journey: "Configure",
    width: 320,
    theme: "dark",
    scrollWidth: 330,
    clientWidth: 320
  });
  const cells = row.replace(/^\| /, "").replace(/ \|$/, "").split(" | ");
  assert.equal(cells.length, 14);
  assert.equal(cells[0], "`/admin/clients`");
  assert.equal(cells[9], "fail");
  const ok = formatEvidenceRow({ route: "/admin", journey: "Orient", width: 390, theme: "light", scrollWidth: 390, clientWidth: 390 });
  assert.ok(ok.includes("| pass |"));
});

test("sectionPlan returns one slice per heading group", () => {
  const headings = [
    { text: "Summary", top: 100 },
    { text: "Details", top: 3000 },
    { text: "Activity", top: 6000 }
  ];
  const slices = sectionPlan(9000, 900, headings);
  assert.equal(slices.length, 3);
  assert.deepEqual(slices.map((s) => s.heading), ["Summary", "Details", "Activity"]);
  assert.ok(slices.every((s) => s.height === 900 && s.scrollY >= 0));
  assert.equal(sectionPlan(1800, 900, []).length, 2);
});

test("scanSensitive allows reserved example domains but flags real-looking hosts", () => {
  assert.deepEqual(scanSensitive("Endpoint https://partners.northstar.example.com/backchannel-logout"), []);
  assert.ok(scanSensitive("Endpoint https://auth.acme-corp.com/callback").includes("production-looking hostname"));
});

test("the example-domain exemption only applies when example is a whole DNS label", () => {
  assert.deepEqual(scanSensitive("https://example.com/cb and billing.example.org"), []);
  for (const host of [
    "https://auth.acme-example.com/cb",
    "https://login.my-example.org",
    "acme-example.com",
    "notexample.com",
    "https://example.com.attacker.io/cb"
  ]) {
    assert.ok(scanSensitive(host).includes("production-looking hostname"), `${host} is flagged`);
  }
});

test("harness source never clicks, types, or submits anything but the synthetic login", async () => {
  const { readFile } = await import("node:fs/promises");
  const source = await readFile(new URL("./admin_route_proof.mjs", import.meta.url), "utf8");

  const verbs = new Set([...source.matchAll(/browser\(session, "([a-z]+)"/g)].map((m) => m[1]));
  const allowed = new Set(["open", "get", "eval", "set", "wait", "press", "reload", "screenshot", "close"]);
  for (const verb of verbs) assert.ok(allowed.has(verb), `unexpected agent-browser verb: ${verb}`);
  const dynamic = source.match(/(?<!function )browser\(session(?!, ")/g) ?? [];
  assert.equal(dynamic.length, 0, "every browser call names a literal verb");
  assert.equal((source.match(/execFileSync\("agent-browser"/g) ?? []).length, 1, "agent-browser runs only through the wrapper");

  const keys = [...source.matchAll(/browser\(session, "press", "([^"]+)"/g)].map((m) => m[1]);
  assert.deepEqual([...new Set(keys)].sort(), ["Escape", "Tab"]);

  assert.doesNotMatch(source, /\.click\(|dispatchEvent\(|\.submit\(\)/);
  const submits = source.match(/requestSubmit\(/g) ?? [];
  assert.equal(submits.length, 1, "only the login form is submitted");
  assert.match(source, /document\.querySelector\("#login"\)\?\.form;/);
  assert.match(source, /f\.matches\(\\'form\[action\$="\/login"\]\\'\)/);
  assert.match(source, /f\.requestSubmit\(\)/);
  assert.doesNotMatch(source, /document\.querySelector\("form"\)/);
});

test("isLocalDevHost allows only local dev hosts", () => {
  for (const url of [
    "http://localhost:4000/lockspire",
    "http://127.0.0.1:4000/lockspire",
    "http://lockspire-ui-review.localhost/lockspire",
    "https://demo.lockspire.test/lockspire"
  ]) {
    assert.ok(isLocalDevHost(url), `${url} is local`);
  }
  for (const url of [
    "https://auth.acme-corp.com/lockspire",
    "https://localhost.acme-corp.com/",
    "https://test.example.com/",
    "http://192.168.1.10/",
    "http://evil.localhost.io/",
    "not a url"
  ]) {
    assert.ok(!isLocalDevHost(url), `${url} is refused`);
  }
});

test("assessObservation fails a row on every measured defect", () => {
  const sweep = { pathname: "/lockspire/admin", scrollWidth: 390, clientWidth: 390, clipped: [], unlabeled: [], h1Count: 1 };
  const stops = [{ indicator: true, inViewport: true }, { indicator: true, inViewport: true }];
  const keyboard = { stops, indicated: 2, offscreen: 0, disclosuresBefore: 1, disclosuresAfter: 0 };
  assert.deepEqual(assessObservation({ loaded: true, sweep, keyboard }), { result: "pass", gaps: [] });
  assert.equal(assessObservation({ loaded: true, sweep }).result, "pass");

  for (const [label, override] of [
    ["missing indicator", { keyboard: { ...keyboard, indicated: 1 } }],
    ["offscreen stop", { keyboard: { ...keyboard, offscreen: 1 } }],
    ["open disclosure after Escape", { keyboard: { ...keyboard, disclosuresAfter: 1 } }],
    ["no h1", { sweep: { ...sweep, h1Count: 0 } }],
    ["two h1s", { sweep: { ...sweep, h1Count: 2 } }],
    ["document overflow", { sweep: { ...sweep, scrollWidth: 400 } }],
    ["clipped element", { sweep: { ...sweep, clipped: ["div.x 10<20"] } }],
    ["unlabeled control", { sweep: { ...sweep, unlabeled: ["input[name]"] } }]
  ]) {
    const assessed = assessObservation({ loaded: true, sweep, keyboard, ...override });
    assert.equal(assessed.result, "fail", label);
    assert.equal(assessed.gaps.length, 1, label);
  }
  assert.equal(assessObservation({ loaded: false, sweep }).result, "blocked");
});

test("only the focused element or a :focus-within rule counts as a focus indicator", async () => {
  const { readFile } = await import("node:fs/promises");
  const source = await readFile(new URL("./admin_route_proof.mjs", import.meta.url), "utf8");
  const [, body] = source.match(/const FOCUS_SCRIPT = `([\s\S]*?)`;\n/);
  assert.match(body, /n\.matches\(":focus-within"\) && \(paintedOutline\(c\) \|\| paintedShadow\(c\)\) && focusWithinRuleMatches\(n\)/);
  assert.match(body, /!transparent\(c\.outlineColor\)/);
});

test("JS sensitive patterns match BrowserEvidence source for source", async () => {
  const { readFile } = await import("node:fs/promises");
  const elixir = await readFile(
    new URL("../support/lockspire/web/admin_proof/browser_evidence.ex", import.meta.url),
    "utf8"
  );
  const list = elixir.slice(elixir.indexOf("defp sensitive_patterns do"));
  const pairs = [...list.matchAll(/\{"([^"]+)",\s*~r\/((?:\\\/|[^/])*)\/([a-z]*)\}/g)].map((m) => [m[1], m[2], m[3]]);
  assert.deepEqual(
    pairs,
    SENSITIVE_PATTERNS.map(([label, pattern]) => [label, pattern.source, pattern.flags])
  );

  const [, reservedSource, reservedFlags] = elixir.match(/defp reserved_example_host do\s*~r\/((?:\\\/|[^/])*)\/([a-z]*)/);
  assert.equal(RESERVED_EXAMPLE_HOST.source, reservedSource);
  assert.equal(RESERVED_EXAMPLE_HOST.flags.replace("g", ""), reservedFlags);
});

test("the hostname rule covers more production TLDs and keeps reserved names exempt", () => {
  for (const host of ["https://api.acme.co/x", "acme.ai", "https://auth.acme.dev/cb", "billing.acme.co.uk", "login.acme.io:8443/"]) {
    assert.ok(scanSensitive(host).includes("production-looking hostname"), `${host} is flagged`);
  }
  for (const host of [
    "http://lockspire-ui-review.localhost/lockspire",
    "https://billingo.test/callback",
    "https://partners.northstar.example.com/cb",
    "https://app.example/cb",
    "https://bad.invalid/",
    "admin_route_proof.mjs and 154-BROWSER-EVIDENCE.md"
  ]) {
    assert.deepEqual(scanSensitive(host), [], `${host} is not flagged`);
  }
});

test("parseWidths rejects a bare --width and widths BrowserEvidence would reject", () => {
  assert.deepEqual(parseWidths(undefined, [390]), [390]);
  assert.deepEqual(parseWidths("320,1280", []), [320, 1280]);
  assert.deepEqual(parseWidths("390", []), [390]);
  assert.throws(() => parseWidths(true, [390]), /needs a value/);
  for (const bad of ["1", "641", "abc", "", "390,12"]) assert.throws(() => parseWidths(bad, [390]), /--width/);
});

test("ALLOWED_WIDTHS mirrors the BrowserEvidence viewport list", async () => {
  const { readFile } = await import("node:fs/promises");
  const elixir = await readFile(
    new URL("../support/lockspire/web/admin_proof/browser_evidence.ex", import.meta.url),
    "utf8"
  );
  const [, block] = elixir.match(/@allowed_viewports \[([^\]]*)\]/);
  const viewports = [...block.matchAll(/"(\d+)px"/g)].map((m) => Number(m[1]));
  assert.deepEqual(ALLOWED_WIDTHS, viewports);
  for (const width of DEFAULT_WIDTHS) assert.ok(ALLOWED_WIDTHS.includes(width));
});

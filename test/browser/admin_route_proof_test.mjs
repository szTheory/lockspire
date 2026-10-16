// Pure-helper tests for the local admin route proof harness. No browser is
// launched. Local-only: the harness is not run in CI (D-05).
import assert from "node:assert/strict";
import test from "node:test";

import {
  CHANGED_PAGES,
  DEFAULT_THEMES,
  DEFAULT_WIDTHS,
  buildMatrix,
  collectScanText,
  concretePath,
  formatEvidenceRow,
  matrixSize,
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
  assert.match(source, /querySelector\("#login"\)\.value = "ops"; document\.querySelector\("form"\)\.requestSubmit\(\)/);
});

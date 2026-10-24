import assert from "node:assert/strict";
import test from "node:test";

import {
  FULL_CASE_IDS,
  isFailedJoinFrame,
  isSuccessfulJoinFrame,
  supportedNode,
  validateBrowserObservation,
  validateFullScenarios,
  validateTracerEvidence
} from "./packaged_admin_proof.mjs";

test("supportedNode accepts the documented Node floor", () => {
  assert.equal(supportedNode("22.15.0"), true);
  assert.equal(supportedNode("23.0.0"), true);
  assert.equal(supportedNode("22.14.9"), false);
  assert.equal(supportedNode("invalid"), false);
});

test("browser observations require every host authorization and navigation check", () => {
  const complete = {
    login: true,
    overview: true,
    clients: true,
    authorized_http: true,
    connected_hook: true
  };
  assert.equal(validateBrowserObservation(complete), true);
  assert.equal(validateBrowserObservation({ ...complete, clients: false }), false);
  assert.equal(validateBrowserObservation({ ...complete, secret_cookie: "sentinel" }), false);
  assert.equal(validateBrowserObservation(null), false);
});

test("only a successful Phoenix LiveView join reply counts as a join", () => {
  assert.equal(isSuccessfulJoinFrame(JSON.stringify(["1", "2", "lv:1", "phx_reply", { status: "ok", response: {} }])), true);
  assert.equal(isSuccessfulJoinFrame(JSON.stringify(["1", "2", "lv:1", "phx_reply", { status: "error", response: {} }])), false);
  assert.equal(isSuccessfulJoinFrame(JSON.stringify(["1", "2", "lv:1", "phx_close", { status: "ok", response: {} }])), false);
  assert.equal(isSuccessfulJoinFrame("not-json"), false);
});

test("failed join replies are distinct from successful joins", () => {
  assert.equal(isFailedJoinFrame(JSON.stringify(["1", "2", "lv:1", "phx_reply", { status: "error" }])), true);
  assert.equal(isFailedJoinFrame(JSON.stringify(["1", "2", "lv:1", "phx_reply", { status: "ok" }])), false);
  assert.equal(isFailedJoinFrame("not-json"), false);
});

test("full browser results require the exact unique case set and boolean evidence", () => {
  const scenarios = FULL_CASE_IDS.map((id) => ({
    id,
    outcome: "passed",
    counts: { assets: 0, websocket_handshakes: 0, successful_joins: 0, navigations: 0, params_checks: 0, http_checks: 0, staff_checks: 0 },
    observations: Object.fromEntries([
      "static_200", "assets_200", "join_allowed", "protected_content", "live_navigation", "params_patch",
      "detail_task", "socket_closed", "reconnect_join", "interaction_after_reconnect", "anonymous_denied",
      "nonstaff_denied", "cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied",
      "consent_session_denied", "discovery_200", "jwks_200", "protocol_error_shape", "no_staff_checks",
      "protected_content_absent", "prefix_ok"
    ].map((key) => [key, true]))
  }));
  assert.equal(validateFullScenarios(scenarios), true);
  assert.equal(validateFullScenarios(scenarios.slice(1)), false);
  assert.equal(validateFullScenarios([...scenarios.slice(1), scenarios[0], scenarios[0]]), false);
  assert.equal(validateFullScenarios(scenarios.map((item, index) => index ? item : { ...item, id: "secret_cookie" })), false);
  assert.equal(validateFullScenarios(scenarios.map((item, index) => index ? item : { ...item, observations: { ...item.observations, cached_join_denied: "sentinel" } })), false);
});

test("tracer evidence requires transport reconnect and four native transitions", () => {
  const observations = { login: true, overview: true, clients: true, authorized_http: true, connected_hook: true };
  const counts = { assets: 2, websocket_handshakes: 2, successful_joins: 2, navigations: 4 };
  assert.equal(validateTracerEvidence(observations, counts), true);
  assert.equal(validateTracerEvidence(observations, { ...counts, websocket_handshakes: 1 }), false);
  assert.equal(validateTracerEvidence(observations, { ...counts, navigations: 1 }), false);
});

test("the Node suite retains its exact known case count", async () => {
  const { readFile } = await import("node:fs/promises");
  const source = await readFile(new URL("./packaged_admin_proof_test.mjs", import.meta.url), "utf8");
  assert.equal([...source.matchAll(/^test\(/gm)].length, 7);
});

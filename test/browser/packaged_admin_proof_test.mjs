import assert from "node:assert/strict";
import test from "node:test";

import {
  isSuccessfulJoinFrame,
  supportedNode,
  validateBrowserObservation,
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
  assert.equal([...source.matchAll(/^test\(/gm)].length, 5);
});

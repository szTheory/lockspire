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
  assert.equal([...source.matchAll(/^test\(/gm)].length, 8);
});


test("SIGTERM and SIGINT remove the owned Chrome process and profile", { timeout: 15000 }, async () => {
  const { mkdtemp, writeFile, readFile, access, rm, chmod } = await import("node:fs/promises");
  const { spawn } = await import("node:child_process");
  const { tmpdir } = await import("node:os");
  const root = await mkdtemp(`${tmpdir()}/lockspire-node-signal-`);
  try {
    const fake = `${root}/chrome`;
    await writeFile(fake, `#!/usr/bin/env python3
import os, signal, sys, time
from pathlib import Path
root = Path(os.environ['PROOF_SIGNAL_ROOT'])
profile = next(arg.split('=', 1)[1] for arg in sys.argv if arg.startswith('--user-data-dir='))
(root / 'owned').write_text(str(os.getpid()) + '\\n' + profile)
signal.signal(signal.SIGTERM, signal.SIG_IGN)
while True: time.sleep(1)
`);
    await chmod(fake, 0o700);
    for (const sig of ["SIGTERM", "SIGINT"]) {
      await rm(`${root}/owned`, { force: true });
      const child = spawn(process.execPath, [new URL("./packaged_admin_proof.mjs", import.meta.url).pathname], {
        env: { ...process.env, CHROME_BIN: fake, PROOF_SIGNAL_ROOT: root }, stdio: ["pipe", "pipe", "pipe"]
      });
      let output = "";
      child.stdout.on("data", (chunk) => { output += chunk; });
      child.stderr.on("data", (chunk) => { output += chunk; });
      child.stdin.end(JSON.stringify({ capability: "x".repeat(48), origin: "http://127.0.0.1:12345", mount: "/", runRoot: root }));
      let owned;
      for (let n = 0; n < 100; n++) {
        try { owned = (await readFile(`${root}/owned`, "utf8")).split("\n"); break; } catch {}
        await new Promise((resolve) => setTimeout(resolve, 20));
      }
      assert.ok(owned, "fake Chrome actually started");
      const exited = new Promise((resolve) => child.once("exit", (code) => resolve(code)));
      child.kill(sig);
      assert.equal(await exited, sig === "SIGTERM" ? 143 : 130);
      assert.throws(() => process.kill(Number(owned[0]), 0));
      await assert.rejects(access(owned[1]));
      assert.doesNotMatch(output, /x{48}/);
    }
  } finally { await rm(root, { recursive: true, force: true }); }
});

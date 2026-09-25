'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..', '..');
const routerPath = path.join(__dirname, 'lockspire-finalize-command-router.cjs');
const supervisorPath = path.join(__dirname, 'lockspire-finalizer-process-supervisor.cjs');
const manifestPath = path.join(__dirname, 'capability.json');

function loadRouter() {
  assert.equal(fs.existsSync(routerPath), true, 'tracked router must exist');
  delete require.cache[require.resolve(routerPath)];
  return require(routerPath);
}

async function waitForFile(target, attempts = 100) {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    if (fs.existsSync(target)) return;
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  assert.fail(`timed out waiting for ${target}`);
}

async function waitForMissingFile(target, attempts = 100) {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    if (!fs.existsSync(target)) return;
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  assert.fail(`timed out waiting for removal of ${target}`);
}

async function waitForProcessExit(pid, attempts = 100) {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      process.kill(pid, 0);
    } catch (error) {
      if (error && error.code === 'ESRCH') return;
      throw error;
    }
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  assert.fail(`timed out waiting for process ${pid}`);
}

function assertProcessExited(pid, message) {
  assert.throws(
    () => process.kill(pid, 0),
    (error) => error && error.code === 'ESRCH',
    message,
  );
}

function invoke(router, args, options = {}) {
  const errors = [];
  const calls = [];
  router.setSpawnSyncForTests((binary, argv, spawnOptions) => {
    calls.push({ binary, argv, options: spawnOptions });
    return options.result || { status: 0, signal: null, error: null };
  });
  process.exitCode = undefined;
  router.routeLockspireFinalizeCommand({
    args,
    cwd: options.cwd || root,
    raw: options.raw !== false,
    error: (message) => errors.push(message),
  });
  const exitCode = process.exitCode;
  process.exitCode = undefined;
  router.resetSpawnSyncForTests();
  return { calls, errors, exitCode };
}

test('manifest declares supported refresh and blocking final-acceptance boundaries', () => {
  assert.equal(fs.existsSync(manifestPath), true, 'tracked capability manifest must exist');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  assert.equal(manifest.id, 'lockspire-phase-finalizer');
  assert.equal(manifest.version, '1.2.0');
  assert.deepEqual(manifest.commands, [{
    family: 'lockspire-finalize',
    module: 'lockspire-finalize-command-router.cjs',
    router: 'routeLockspireFinalizeCommand',
  }]);
  assert.deepEqual(manifest.hooks, []);
  assert.deepEqual(manifest.skills, []);
  assert.deepEqual(manifest.agents, []);
  assert.deepEqual(manifest.contributions, []);
  assert.deepEqual(manifest.steps, []);
  assert.deepEqual(manifest.gates, [{
    point: 'execute:post',
    check: { predicate: {
      kind: 'command-exit-zero',
      command: 'test "${PHASE_NUMBER}" != 139 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh pre-verify 139',
      timeout: 900,
    } },
    blocking: true,
    onError: 'halt',
  }, {
    point: 'plan:pre',
    check: { predicate: {
      kind: 'command-exit-zero',
      command: 'test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139',
      timeout: 2400,
    } },
    blocking: true,
    onError: 'halt',
  }]);
});

test('138-33-1 rejects undeclared capability surfaces [phase138_prohibition]', () => {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  assert.deepEqual(manifest.hooks, []);
  assert.deepEqual(manifest.skills, []);
  assert.deepEqual(manifest.agents, []);
  assert.deepEqual(manifest.contributions, []);
  assert.deepEqual(manifest.steps, []);
  assert.deepEqual(manifest.gates.map(({ point }) => point), ['execute:post', 'plan:pre']);
  assert.deepEqual(manifest.commands.map(({ family }) => family), ['lockspire-finalize']);
});

test('138-33-2 rejects invalid routing input without constructing a child process [phase138_prohibition]', () => {
  const router = loadRouter();
  for (const args of [['lockspire-finalize', 'unknown', '--phase', '138']]) {
    const rejected = invoke(router, args);
    assert.equal(rejected.calls.length, 0);
    assert.equal(rejected.exitCode, 2);
    assert.equal(rejected.errors.length, 1);
  }

  for (const [mode, phase] of [['pre-verify', '137'], ['post-transition', '140']]) {
    const inert = invoke(router, ['lockspire-finalize', mode, '--phase', phase]);
    assert.equal(inert.calls.length, 0);
    assert.equal(inert.exitCode, undefined);
    assert.match(inert.errors[0], /not applicable/);
  }

  const accepted = invoke(router, ['lockspire-finalize', 'pre-verify', '--phase', '138']);
  assert.equal(accepted.calls.length, 1);
  assert.equal(accepted.calls[0].binary, process.execPath);
  assert.equal(accepted.calls[0].options.shell, false);
  assert.equal(accepted.calls[0].argv[1], fs.realpathSync(root));
  assert.equal(accepted.calls[0].argv[5], '900000');
  assert.equal(accepted.calls[0].argv[0], supervisorPath);
  assert.deepEqual(accepted.errors, []);
});

test('both exact modes spawn one no-shell process-group supervisor', () => {
  const router = loadRouter();
  for (const mode of ['pre-verify', 'post-transition']) {
    const result = invoke(router, ['lockspire-finalize', mode, '--phase', '138']);
    assert.equal(result.exitCode, undefined);
    assert.deepEqual(result.errors, []);
    assert.equal(result.calls.length, 1);
    assert.equal(result.calls[0].binary, process.execPath);
    assert.deepEqual(result.calls[0].argv, [
      supervisorPath,
      fs.realpathSync(root),
      'scripts/maintainer/finalize_phase_138_inventory.sh',
      mode,
      '138',
      '900000',
      '1000',
    ]);
    assert.deepEqual(result.calls[0].options, {
      cwd: fs.realpathSync(root),
      shell: false,
      stdio: 'inherit',
    });
  }
});

test('Phase 139 routes pre-verify and post-transition to their exact bounded children', () => {
  const router = loadRouter();
  const cases = [
    ['pre-verify', 'scripts/maintainer/finalize_phase_138_inventory.sh', 900000],
    ['post-transition', 'scripts/maintainer/finalize_phase_139_acceptance.sh', 2400000],
  ];
  for (const [mode, child, timeout] of cases) {
    const result = invoke(router, ['lockspire-finalize', mode, '--phase', '139']);
    assert.equal(result.exitCode, undefined);
    assert.deepEqual(result.errors, []);
    assert.equal(result.calls.length, 1);
    assert.deepEqual(result.calls[0].argv, [
      supervisorPath, fs.realpathSync(root), child, mode, '139', String(timeout), '1000',
    ]);
    assert.equal(result.calls[0].options.shell, false);
    assert.equal(result.calls[0].options.stdio, 'inherit');
  }
});

test('process-group timeout kills a resistant descendant and lets the finalizer remove its lock', () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-finalizer-timeout-'));
  const script = path.join(fixture, 'finalizer.sh');
  const lock = path.join(fixture, 'lockspire-phase-139-acceptance.lock');
  const pidFile = path.join(fixture, 'descendant.pid');
  let descendant;
  try {
    fs.writeFileSync(script, [
      '#!/usr/bin/env bash',
      'set -euo pipefail',
      `lock=${JSON.stringify(lock)}`,
      `pid_file=${JSON.stringify(pidFile)}`,
      'mkdir "$lock"',
      'cleanup() { rmdir "$lock" 2>/dev/null || true; }',
      "trap cleanup EXIT",
      "trap 'cleanup; exit 143' TERM",
      "bash -c 'trap \"\" TERM; while :; do sleep 1; done' &",
      'descendant=$!',
      'printf "%s\\n" "$descendant" > "$pid_file"',
      'wait "$descendant"',
    ].join('\n') + '\n', { mode: 0o755 });

    const started = Date.now();
    const result = spawnSync(process.execPath, [
      supervisorPath, fixture, path.basename(script), 'post-transition', '139', '200', '100',
    ], {
      cwd: fixture,
      encoding: 'utf8',
      shell: false,
      timeout: 3000,
    });
    const elapsed = Date.now() - started;
    descendant = Number(fs.readFileSync(pidFile, 'utf8').trim());

    assert.equal(result.status, 124, `${result.stdout}\n${result.stderr}`);
    assert.ok(elapsed < 1500, `timeout took ${elapsed}ms`);
    assert.equal(fs.existsSync(lock), false, 'finalizer signal cleanup must remove its lock');
    assert.throws(
      () => process.kill(descendant, 0),
      (error) => error && error.code === 'ESRCH',
      'resistant descendant must not survive the timeout',
    );
  } finally {
    if (Number.isInteger(descendant)) {
      try { process.kill(descendant, 'SIGKILL'); } catch (_) { /* already gone */ }
    }
    fs.rmSync(fixture, { recursive: true, force: true });
  }
});

test('cancelling only the production router terminates and reaps its complete finalizer process group', async () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-finalizer-cancel-'));
  const cases = ['SIGHUP', 'SIGINT', 'SIGTERM'];
  const livePids = new Set();
  try {
    for (const signal of cases) {
      const directory = path.join(fixture, signal.toLowerCase());
      const script = path.join(directory, 'scripts/maintainer/finalize_phase_139_acceptance.sh');
      const lock = path.join(directory, 'lockspire-phase-139-acceptance.lock');
      const finalizerPidFile = path.join(directory, 'finalizer.pid');
      const descendantPidFile = path.join(directory, 'descendant.pid');
      const mutation = path.join(directory, 'post-cancellation-mutation');
      fs.mkdirSync(path.dirname(script), { recursive: true });
      fs.mkdirSync(path.join(directory, '.planning/phases/138-baseline-inventory-evidence-taxonomy'), { recursive: true });
      fs.mkdirSync(path.join(directory, '.planning/phases/139-required-truth-reconciliation'), { recursive: true });
      fs.writeFileSync(path.join(directory, 'scripts/maintainer/finalize_phase_138_inventory.sh'), '#!/usr/bin/env bash\nexit 0\n', { mode: 0o755 });
      fs.writeFileSync(script, [
        '#!/usr/bin/env bash',
        'set -euo pipefail',
        `lock=${JSON.stringify(lock)}`,
        `finalizer_pid_file=${JSON.stringify(finalizerPidFile)}`,
        `descendant_pid_file=${JSON.stringify(descendantPidFile)}`,
        `mutation=${JSON.stringify(mutation)}`,
        'mkdir "$lock"',
        'cleanup() { rmdir "$lock" 2>/dev/null || true; }',
        "trap cleanup EXIT",
        "trap 'cleanup; exit 129' HUP",
        "trap 'cleanup; exit 130' INT",
        "trap 'cleanup; exit 143' TERM",
        'printf "%s\\n" "$$" > "$finalizer_pid_file"',
        "bash -c 'trap \"\" HUP INT TERM; while :; do sleep 1; done' &",
        'descendant=$!',
        'printf "%s\\n" "$descendant" > "$descendant_pid_file"',
        'wait "$descendant"',
        'printf mutated > "$mutation"',
      ].join('\n') + '\n', { mode: 0o755 });

      const router = spawn(process.execPath, [
        '-e',
        `require(${JSON.stringify(routerPath)}).routeLockspireFinalizeCommand({args:['lockspire-finalize','post-transition','--phase','139'],cwd:${JSON.stringify(directory)},raw:true,error:console.error})`,
      ], {
        cwd: directory,
        shell: false,
        stdio: 'ignore',
      });
      livePids.add(router.pid);
      await Promise.all([waitForFile(finalizerPidFile), waitForFile(descendantPidFile)]);
      const finalizerPid = Number(fs.readFileSync(finalizerPidFile, 'utf8').trim());
      const descendantPid = Number(fs.readFileSync(descendantPidFile, 'utf8').trim());
      livePids.add(finalizerPid);
      livePids.add(descendantPid);

      const started = Date.now();
      process.kill(router.pid, signal);
      const result = await new Promise((resolve) => {
        router.once('exit', (code, exitSignal) => resolve({ code, signal: exitSignal }));
      });
      const elapsed = Date.now() - started;
      livePids.delete(router.pid);
      livePids.delete(finalizerPid);
      livePids.delete(descendantPid);

      assert.equal(result.signal, signal);
      assert.ok(elapsed < 1500, `${signal} cancellation took ${elapsed}ms`);
      await Promise.all([
        waitForMissingFile(lock),
        waitForProcessExit(finalizerPid),
        waitForProcessExit(descendantPid),
      ]);
      assert.equal(fs.existsSync(lock), false, `${signal} must allow finalizer lock cleanup`);
      assert.equal(fs.existsSync(mutation), false, `${signal} must prevent post-cancellation mutation`);
      assertProcessExited(finalizerPid, `${signal} finalizer must not survive cancellation`);
      assertProcessExited(descendantPid, `${signal} descendant must not survive cancellation`);
    }
  } finally {
    for (const pid of livePids) {
      try { process.kill(pid, 'SIGKILL'); } catch (_) { /* already gone */ }
    }
    fs.rmSync(fixture, { recursive: true, force: true });
  }
});

test('other strictly numeric phases are inert successes', () => {
  const router = loadRouter();
  for (const phase of ['1', '137', '140', '141', '999', '139.1']) {
    for (const mode of ['pre-verify', 'post-transition']) {
      const result = invoke(router, ['lockspire-finalize', mode, '--phase', phase]);
      assert.equal(result.exitCode, undefined);
      assert.equal(result.calls.length, 0);
      assert.equal(result.errors.length, 1);
      assert.match(result.errors[0], /not applicable/);
    }
  }
});

test('invalid raw mode argv phase and cwd reject without spawning', () => {
  const router = loadRouter();
  const invalid = [
    { args: ['lockspire-finalize', 'pre-verify', '--phase', '138'], raw: false },
    { args: ['lockspire-finalize', 'unknown', '--phase', '138'] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase', ''] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase', 'phase139'] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase', '0139'] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase', '139.'] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase'] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase', '138', 'extra'] },
    { args: ['wrong-family', 'pre-verify', '--phase', '138'] },
    { args: ['lockspire-finalize', 'pre-verify', '--phase', '138'], cwd: os.tmpdir() },
  ];
  for (const item of invalid) {
    const result = invoke(router, item.args, item);
    assert.equal(result.calls.length, 0);
    assert.equal(result.exitCode, 2);
    assert.equal(result.errors.length, 1);
  }
});

test('ordinary child nonzero statuses are preserved', () => {
  const router = loadRouter();
  for (const status of [1, 2, 42, 129, 130, 143, 255]) {
    const result = invoke(router, ['lockspire-finalize', 'post-transition', '--phase', '138'], {
      result: { status, signal: null, error: null },
    });
    assert.equal(result.calls.length, 1);
    assert.equal(result.exitCode, status);
    assert.equal(result.errors.length, 1);
  }
});

test('timeout signal spawn error and missing status remain distinct', () => {
  const router = loadRouter();
  const cases = [
    [{ status: null, signal: 'SIGTERM', error: Object.assign(new Error('timeout detail'), { code: 'ETIMEDOUT' }) }, 124, 'timed out'],
    [{ status: null, signal: 'SIGKILL', error: null }, 125, 'signal'],
    [{ status: null, signal: null, error: new Error('private spawn detail') }, 126, 'failed to start'],
    [{ status: null, signal: null, error: null }, 127, 'no exit status'],
  ];
  for (const [child, status, diagnostic] of cases) {
    const result = invoke(router, ['lockspire-finalize', 'pre-verify', '--phase', '138'], { result: child });
    assert.equal(result.exitCode, status);
    assert.equal(result.errors.length, 1);
    assert.match(result.errors[0], new RegExp(diagnostic));
    assert.doesNotMatch(result.errors[0], /private|detail|SIGKILL/);
  }
});

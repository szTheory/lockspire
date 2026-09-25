'use strict';

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..', '..');
const tools = [
  process.env.GSD_TOOLS,
  path.join(root, 'gsd-core/bin/gsd-tools.cjs'),
  path.join(root, '.codex/gsd-core/bin/gsd-tools.cjs'),
  path.join(root, '.claude/gsd-core/bin/gsd-tools.cjs'),
  ...['.codex', '.claude', '.hermes', '.cursor', '.gemini', '.copilot', '.agents']
    .map((runtime) => path.join(os.homedir(), runtime, 'gsd-core/bin/gsd-tools.cjs')),
].filter(Boolean).find((candidate) => fs.existsSync(candidate));
const fixturePath = process.env.LOCKSPIRE_GSD_HOST_FIXTURE
  ? path.resolve(root, process.env.LOCKSPIRE_GSD_HOST_FIXTURE)
  : null;
const hostFixture = fixturePath ? JSON.parse(fs.readFileSync(fixturePath, 'utf8')) : null;
assert.ok(tools || hostFixture, 'GSD runtime tools or LOCKSPIRE_GSD_HOST_FIXTURE must be available');
const mixAvailable = spawnSync('mix', ['--version'], { encoding: 'utf8' }).status === 0;
const skipBeamIntegration = !mixAvailable || process.env.LOCKSPIRE_SKIP_BEAM_INTEGRATION === '1';
const core = tools ? path.dirname(path.dirname(path.resolve(tools))) : null;
const trackedCapabilityRoot = path.join(root, 'tools/gsd-capabilities/lockspire-phase-finalizer');
const stateHelper = path.join(trackedCapabilityRoot, 'post-completion-finalizer-state.cjs');
const registryPath = path.join(root, '.gsd-capabilities.json');
const expectedFixtureKeys = [
  'schema', 'supportedPoints', 'gates', 'stateHelperProtocol', 'trackedRuntimeFiles',
];
const expectedTrackedRuntimeFiles = [
  'capability.json',
  'lockspire-finalize-command-router.cjs',
  'lockspire-finalizer-process-supervisor.cjs',
  'post-completion-finalizer-state.cjs',
];
const expectedGates = {
  'execute:post': {
    phase: '139',
    command: 'test "${PHASE_NUMBER}" != 139 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh pre-verify 139',
    timeout: 900,
  },
  'plan:pre': {
    phase: '140',
    command: 'test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139',
    timeout: 2400,
  },
};

if (hostFixture) {
  assert.equal(
    fixturePath,
    path.join(trackedCapabilityRoot, 'fixtures/gsd-host-contract.json'),
    'portable lifecycle expectations must come from the tracked host contract fixture',
  );
  assert.deepEqual(Object.keys(hostFixture).sort(), [...expectedFixtureKeys].sort());
  assert.equal(hostFixture.schema, 1);
  assert.deepEqual(hostFixture.supportedPoints, ['execute:post', 'plan:pre']);
  assert.deepEqual(hostFixture.gates, expectedGates);
  assert.equal(hostFixture.stateHelperProtocol, 'gsd-transition-v1');
  assert.deepEqual(hostFixture.trackedRuntimeFiles, expectedTrackedRuntimeFiles);
}
const originalHome = process.env.HOME;
const originalGsdTools = process.env.GSD_TOOLS;
let portableHome;

if (!tools && hostFixture) {
  portableHome = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-gsd-portable-'));
  const portableCore = path.join(portableHome, '.codex/gsd-core');
  const portableTools = path.join(portableCore, 'bin/gsd-tools.cjs');
  fs.mkdirSync(path.dirname(portableTools), { recursive: true });
  fs.mkdirSync(path.join(portableCore, 'workflows'), { recursive: true });
  const fixtureLiteral = JSON.stringify(fixturePath);
  fs.writeFileSync(portableTools, `#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const fixture = JSON.parse(fs.readFileSync(${fixtureLiteral}, 'utf8'));
const point = process.argv[2] === 'loop' && process.argv[3] === 'render-hooks' ? process.argv[4] : null;
if (!point || !fixture.supportedPoints.includes(point)) process.exit(2);
const expected = fixture.gates[point];
process.stdout.write(JSON.stringify({ activeHooks: [{
  kind: 'gate', capId: 'lockspire-phase-finalizer',
  check: { predicate: { kind: 'command-exit-zero', command: expected.command, timeout: expected.timeout } },
  blocking: true, onError: 'halt'
}] }));
`);
  fs.chmodSync(portableTools, 0o755);
  for (const [file, bytes] of [
    ['execute-phase.md', '# Portable host contract test input\\nexecute:post\\n'],
    ['plan-phase.md', '# Portable host contract test input\\nplan:pre\\n'],
    ['transition.md', '# Portable host contract test input\\ngsd-transition-v1\\n'],
  ]) fs.writeFileSync(path.join(portableCore, 'workflows', file), bytes);
  process.env.HOME = portableHome;
  process.env.GSD_TOOLS = portableTools;
}

test.after(() => {
  if (originalHome === undefined) delete process.env.HOME;
  else process.env.HOME = originalHome;
  if (originalGsdTools === undefined) delete process.env.GSD_TOOLS;
  else process.env.GSD_TOOLS = originalGsdTools;
  if (portableHome) fs.rmSync(portableHome, { recursive: true, force: true });
});

function installedCapability() {
  if (!tools && hostFixture) {
    return {
      entry: { version: '1.2.0', files: expectedTrackedRuntimeFiles },
      root: trackedCapabilityRoot,
      portable: true,
    };
  }

  const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
  const entry = registry.entries && registry.entries['lockspire-phase-finalizer'];
  assert.ok(entry, 'project capability registry must contain lockspire-phase-finalizer');
  assert.equal(entry.files.length, 1);
  return { entry, root: path.resolve(root, entry.files[0]), portable: false };
}

function run(binary, args, options = {}) {
  return spawnSync(binary, args, {
    cwd: options.cwd || root,
    encoding: 'utf8',
    input: options.input,
    env: { ...process.env, ...(options.env || {}) },
    maxBuffer: 32 * 1024 * 1024,
    timeout: options.timeout || 120000,
  });
}

function mustRun(binary, args, options = {}) {
  const result = run(binary, args, options);
  assert.equal(result.status, 0, `${binary} ${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
  return result.stdout;
}

function routeInRepository(args, cwd) {
  const routerPath = path.join(
    installedCapability().root,
    'lockspire-finalize-command-router.cjs',
  );
  delete require.cache[require.resolve(routerPath)];
  const router = require(routerPath);
  const errors = [];
  process.exitCode = undefined;
  router.routeLockspireFinalizeCommand({ args, cwd, raw: true, error: (message) => errors.push(message) });
  const exitCode = process.exitCode;
  process.exitCode = undefined;
  return { errors, exitCode };
}

test('installed capability renders fresh ordered lifecycle hooks', () => {
  const installed = installedCapability();
  if (installed.portable) {
    for (const relative of expectedTrackedRuntimeFiles) {
      assert.equal(fs.existsSync(path.join(trackedCapabilityRoot, relative)), true,
        `tracked runtime dependency is missing: ${relative}`);
    }
  } else {
    assert.equal(installed.entry.version, '1.2.0');
    for (const relative of expectedTrackedRuntimeFiles) {
      const tracked = path.join(trackedCapabilityRoot, relative);
      const active = path.join(installed.root, relative);
      assert.equal(fs.existsSync(active), true, `installed runtime dependency is missing: ${relative}`);
      assert.equal(fs.readFileSync(active).equals(fs.readFileSync(tracked)), true, `${relative} drifted`);
    }
  }

  const installedRoute = routeInRepository(
    ['lockspire-finalize', 'post-transition', '--phase', '140'],
    root,
  );
  assert.equal(installedRoute.exitCode, undefined);
  assert.match(installedRoute.errors.join('\n'), /not applicable/);

  if (tools) {
    const listed = JSON.parse(mustRun('node', [tools, 'capability', 'list', '--scope', 'project', '--json']));
    assert.ok(listed.some((item) => item.id === 'lockspire-phase-finalizer' && item.version === '1.2.0' && item.status === 'active'));

    for (const point of hostFixture ? hostFixture.supportedPoints : ['execute:post', 'plan:pre']) {
      const rendered = JSON.parse(mustRun('node', [tools, 'loop', 'render-hooks', point, '--raw']));
      const gates = rendered.activeHooks.filter((hook) => hook.kind === 'gate' && hook.capId === 'lockspire-phase-finalizer');
      assert.equal(gates.length, 1);
      assert.equal(gates[0].blocking, true);
      assert.equal(gates[0].onError, 'halt');
      assert.deepEqual(gates[0].check, { predicate: {
        kind: 'command-exit-zero',
        command: hostFixture ? hostFixture.gates[point].command : expectedGates[point].command,
        timeout: hostFixture ? hostFixture.gates[point].timeout : expectedGates[point].timeout,
      } });
    }
  } else {
    assert.ok(hostFixture, 'portable mode requires the tracked host contract fixture');
  }

  const stalePreInstallEnvelope = { activeHooks: [] };
  assert.equal(stalePreInstallEnvelope.activeHooks.some((hook) => hook.capId === 'lockspire-phase-finalizer'), false);
});

test('router cannot activate legacy Phase 139 acceptance test seams from ambient variables', () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-finalizer-legacy-env-'));
  const legacyVariables = [
    'LOCKSPIRE_ACCEPTANCE_TEST_MODE',
    'LOCKSPIRE_ACCEPTANCE_TEST_STOP_AFTER_LANDING',
    'LOCKSPIRE_ACCEPTANCE_TEST_BARRIER',
    'LOCKSPIRE_ACCEPTANCE_HYGIENE_SCRIPT',
  ];
  const prior = Object.fromEntries(
    ['PATH', ...legacyVariables].map((name) => [name, process.env[name]]),
  );
  try {
    for (const directory of [
      'scripts/maintainer',
      '.planning/phases/138-baseline-inventory-evidence-taxonomy',
      '.planning/phases/139-required-truth-reconciliation',
      'bin',
    ]) fs.mkdirSync(path.join(fixture, directory), { recursive: true });

    fs.copyFileSync(
      path.join(root, 'scripts/maintainer/finalize_phase_139_acceptance.sh'),
      path.join(fixture, 'scripts/maintainer/finalize_phase_139_acceptance.sh'),
    );
    fs.writeFileSync(
      path.join(fixture, 'scripts/maintainer/finalize_phase_138_inventory.sh'),
      '#!/usr/bin/env bash\nexit 0\n',
    );
    const gitMarker = path.join(fixture, 'git-was-invoked');
    const fakeGit = path.join(fixture, 'bin/git');
    fs.writeFileSync(fakeGit, `#!/usr/bin/env bash\nprintf invoked > ${JSON.stringify(gitMarker)}\nexit 1\n`, {
      mode: 0o755,
    });

    process.env.PATH = path.join(fixture, 'bin') + path.delimiter + prior.PATH;
    for (const name of legacyVariables) process.env[name] = path.join(fixture, name);

    const result = routeInRepository(
      ['lockspire-finalize', 'post-transition', '--phase', '139'],
      fixture,
    );
    assert.equal(result.exitCode, 1);
    assert.match(result.errors.join('\n'), /child exited nonzero \(1\)/);
    assert.equal(fs.existsSync(gitMarker), false, 'legacy variables must be rejected before Git mutation');
  } finally {
    for (const [name, value] of Object.entries(prior)) {
      if (value === undefined) delete process.env[name];
      else process.env[name] = value;
    }
    fs.rmSync(fixture, { recursive: true, force: true });
  }
});

test('host workflows expose only supported fresh lifecycle boundaries', () => {
  for (const file of [
    path.join(root, 'scripts/maintainer/baseline_inventory.sh'),
    path.join(root, 'test/support/lockspire/release_proof/package_assertions.ex'),
    __filename,
  ]) {
    assert.doesNotMatch(fs.readFileSync(file, 'utf8'), new RegExp('/' + 'Users' + '/'));
  }

  if (tools) {
    const execute = fs.readFileSync(path.join(core, 'workflows/execute-phase.md'), 'utf8');
    const plan = fs.readFileSync(path.join(core, 'workflows/plan-phase.md'), 'utf8');
    const hostContract = fs.readFileSync(path.join(core, 'bin/lib/loop-host-contract.cjs'), 'utf8');
    assert.match(execute, /EXECUTE_POST_HOOKS_JSON=\$\(gsd_run loop render-hooks execute:post --raw\)/);
    assert.match(plan, /PLAN_PRE_HOOKS_JSON=\$\(gsd_run loop render-hooks plan:pre --raw\)/);
    assert.match(hostContract, /"plan:pre"/);
    assert.match(hostContract, /"execute:post"/);
    assert.doesNotMatch(hostContract, /execute:complete:post/);
  } else {
    assert.ok(hostFixture, 'portable mode requires the tracked host contract fixture');
    assert.deepEqual(hostFixture.supportedPoints, ['execute:post', 'plan:pre']);
  }
});

test('138-32-2 rejects a mismatched host receipt while preserving pending recovery state [phase138_prohibition]', () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-phase138-receipt-'));
  try {
    mustRun('git', ['init', '-q', '-b', 'main'], { cwd: fixture });
    mustRun('git', ['config', 'user.name', 'Lifecycle Test'], { cwd: fixture });
    mustRun('git', ['config', 'user.email', 'lifecycle@example.com'], { cwd: fixture });
    for (const [relative, bytes] of [
      ['.planning/PROJECT.md', '# Lockspire\n**Current focus:** Phase 138\n'],
      ['.planning/STATE.md', '---\ncurrent_phase: 138\nstatus: executing\n---\n'],
      ['.planning/ROADMAP.md', '# Roadmap\nPhase 138 in progress\n'],
      ['.planning/REQUIREMENTS.md', '# Requirements\nBASE-01 pending\n'],
    ]) {
      const target = path.join(fixture, relative);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, bytes);
    }
    mustRun('git', ['add', '--all'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'feat: receipt base'], { cwd: fixture });

    mustRun('node', [stateHelper, 'begin', '138'], { cwd: fixture });
    fs.writeFileSync(path.join(fixture, '.planning/PROJECT.md'), '# Lockspire\n**Current focus:** Phase 139\n');
    fs.writeFileSync(path.join(fixture, '.planning/STATE.md'), '---\ncurrent_phase: 139\nstatus: ready_to_plan\n---\n');
    const hooks = JSON.stringify({ activeHooks: [{
      kind: 'step', capId: 'lockspire-phase-finalizer',
      ref: { command: 'lockspire-finalize post-transition' }, onError: 'halt',
    }] });
    mustRun('node', [stateHelper, 'seal', '138'], { cwd: fixture, input: hooks });

    const mismatch = run('node', [stateHelper, 'verify-hooks', '138'], {
      cwd: fixture,
      input: JSON.stringify({ activeHooks: [] }),
    });
    assert.notEqual(mismatch.status, 0);
    assert.equal(JSON.parse(mustRun('node', [stateHelper, 'status'], { cwd: fixture })).status, 'pending');
  } finally {
    fs.rmSync(fixture, { recursive: true, force: true });
  }
});

test('real host receipt preserves pending state across hook mismatch and completes only on success', () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-finalizer-host-'));
  try {
    mustRun('git', ['init', '-q', '-b', 'main'], { cwd: fixture });
    mustRun('git', ['config', 'user.name', 'Lifecycle Test'], { cwd: fixture });
    mustRun('git', ['config', 'user.email', 'lifecycle@example.com'], { cwd: fixture });
    for (const [relative, bytes] of [
      ['.planning/PROJECT.md', '# Lockspire\n**Current focus:** Phase 138\n'],
      ['.planning/STATE.md', '---\ncurrent_phase: 138\nstatus: executing\n---\n'],
      ['.planning/ROADMAP.md', '# Roadmap\nPhase 138 in progress\n'],
      ['.planning/REQUIREMENTS.md', '# Requirements\nBASE-01 pending\n'],
    ]) {
      const target = path.join(fixture, relative);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, bytes);
    }
    mustRun('git', ['add', '--all'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'feat: receipt base'], { cwd: fixture });

    const begin = JSON.parse(mustRun('node', [stateHelper, 'begin', '138'], { cwd: fixture }));
    assert.equal(begin.status, 'preparing');
    assert.deepEqual(begin.writer.allowedPaths, [
      '.planning/PROJECT.md', '.planning/STATE.md', '.planning/ROADMAP.md', '.planning/REQUIREMENTS.md',
    ]);

    fs.writeFileSync(path.join(fixture, '.planning/PROJECT.md'), '# Lockspire\n**Current focus:** Phase 139\n');
    fs.writeFileSync(path.join(fixture, '.planning/STATE.md'), '---\ncurrent_phase: 139\nstatus: ready_to_plan\n---\n');
    const hooks = JSON.stringify({ activeHooks: [{
      kind: 'step', capId: 'lockspire-phase-finalizer',
      ref: { command: 'lockspire-finalize post-transition' }, onError: 'halt',
    }] });
    const seal = JSON.parse(mustRun('node', [stateHelper, 'seal', '138'], { cwd: fixture, input: hooks }));
    assert.equal(seal.status, 'pending');
    assert.equal(seal.transformation.protocol, 'gsd-transition-v1');
    assert.equal(seal.transformation.sha256, crypto.createHash('sha256').update(JSON.stringify({
      protocol: 'gsd-transition-v1', writer: seal.writer, before: seal.before, after: seal.after,
    })).digest('hex'));

    const altered = JSON.stringify({ activeHooks: [] });
    const mismatch = run('node', [stateHelper, 'verify-hooks', '138'], { cwd: fixture, input: altered });
    assert.notEqual(mismatch.status, 0);
    const stillPending = JSON.parse(mustRun('node', [stateHelper, 'status'], { cwd: fixture }));
    assert.equal(stillPending.status, 'pending');
    assert.equal(stillPending.hooksSha256, seal.hooksSha256);

    const verified = JSON.parse(mustRun('node', [stateHelper, 'verify-hooks', '138'], { cwd: fixture, input: hooks }));
    assert.equal(verified.valid, true);
    const completed = JSON.parse(mustRun('node', [stateHelper, 'complete', '138'], { cwd: fixture }));
    assert.equal(completed.completed, true);
    assert.deepEqual(JSON.parse(mustRun('node', [stateHelper, 'status'], { cwd: fixture })), { exists: false });
  } finally {
    fs.rmSync(fixture, { recursive: true, force: true });
  }
});

test('Phase 139 host lifecycle preserves durable post-transition recovery', () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-phase139-lifecycle-'));
  const counters = path.join(fixture, 'counters');
  const preCounter = path.join(counters, 'pre');
  const postCounter = path.join(counters, 'post');
  const failPre = path.join(counters, 'fail-pre-once');
  const failOnce = path.join(counters, 'fail-post-once');
  const ledger = '.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md';
  const prior = {
    GSD_LIFECYCLE_COUNTERS: process.env.GSD_LIFECYCLE_COUNTERS,
    GSD_FINALIZER_STATE_HELPER: process.env.GSD_FINALIZER_STATE_HELPER,
  };
  try {
    mustRun('git', ['init', '-q', '-b', 'main'], { cwd: fixture });
    mustRun('git', ['config', 'user.name', 'Lifecycle Test'], { cwd: fixture });
    mustRun('git', ['config', 'user.email', 'lifecycle@example.com'], { cwd: fixture });
    fs.mkdirSync(counters, { recursive: true });
    for (const directory of [
      '.planning/phases/138-baseline-inventory-evidence-taxonomy',
      '.planning/phases/139-required-truth-reconciliation',
      'scripts/maintainer',
    ]) fs.mkdirSync(path.join(fixture, directory), { recursive: true });
    for (const [relative, bytes] of [
      ['.planning/PROJECT.md', '# Lockspire\n**Current focus:** Phase 139\n'],
      ['.planning/STATE.md', '---\ncurrent_phase: 139\nstatus: verifying\n---\n'],
      ['.planning/ROADMAP.md', '# Roadmap\nPhase 139 in progress\n'],
      ['.planning/REQUIREMENTS.md', '# Requirements\nTRUTH-05 pending\n'],
      ['.planning/phases/139-required-truth-reconciliation/139-01-SUMMARY.md', '---\nstatus: complete\n---\n'],
      ['.planning/phases/139-required-truth-reconciliation/139-REVIEW.md', '---\nstatus: clean\n---\n'],
    ]) fs.writeFileSync(path.join(fixture, relative), bytes);

    const preScript = [
      '#!/usr/bin/env bash',
      'set -euo pipefail',
      'counter="$GSD_LIFECYCLE_COUNTERS/pre"',
      'count=0; [[ ! -f "$counter" ]] || count="$(cat "$counter")"',
      'printf "%s" "$((count + 1))" > "$counter"',
      'if [[ -f "$GSD_LIFECYCLE_COUNTERS/fail-pre-once" && "$count" == 0 ]]; then exit 41; fi',
      `printf '%s\\n' 'proposal-only refreshed ledger' > ${JSON.stringify(ledger)}`,
      `git add ${JSON.stringify(ledger)}`,
      'git commit -qm "docs(phase-139): refresh baseline inventory before verification"',
    ].join('\n') + '\n';
    const postScript = [
      '#!/usr/bin/env bash',
      'set -euo pipefail',
      'counter="$GSD_LIFECYCLE_COUNTERS/post"',
      'count=0; [[ ! -f "$counter" ]] || count="$(cat "$counter")"',
      'count=$((count + 1)); printf "%s" "$count" > "$counter"',
      'if [[ -f "$GSD_LIFECYCLE_COUNTERS/fail-post-once" && "$count" == 1 ]]; then exit 42; fi',
      'node "$GSD_FINALIZER_STATE_HELPER" status | jq -e ".status == \\"pending\\" and .phase == \\"139\\"" >/dev/null',
      'candidate="$(git rev-parse HEAD)"',
      'git update-ref refs/heads/main "$candidate"',
      'common="$(git rev-parse --path-format=absolute --git-common-dir)"',
      'printf "{\\"schema\\":\\"lockspire-phase-139-acceptance-v1\\",\\"baseline_sha\\":\\"%s\\"}\\n" "$candidate" > "$common/lockspire-phase-139-acceptance-v1.json"',
      'chmod 600 "$common/lockspire-phase-139-acceptance-v1.json"',
    ].join('\n') + '\n';
    const prePath = path.join(fixture, 'scripts/maintainer/finalize_phase_138_inventory.sh');
    const postPath = path.join(fixture, 'scripts/maintainer/finalize_phase_139_acceptance.sh');
    fs.writeFileSync(prePath, preScript, { mode: 0o755 });
    fs.writeFileSync(postPath, postScript, { mode: 0o755 });
    mustRun('git', ['add', '--all'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'feat: phase lifecycle base'], { cwd: fixture });
    mustRun('git', ['switch', '-q', '-c', 'phase-139'], { cwd: fixture });

    process.env.GSD_LIFECYCLE_COUNTERS = counters;
    process.env.GSD_FINALIZER_STATE_HELPER = stateHelper;
    const commitsBeforePre = Number(mustRun('git', ['rev-list', '--count', 'HEAD'], { cwd: fixture }).trim());
    fs.writeFileSync(failPre, '1');
    const failedPre = routeInRepository(['lockspire-finalize', 'pre-verify', '--phase', '139'], fixture);
    assert.equal(failedPre.exitCode, 41);
    assert.equal(Number(mustRun('git', ['rev-list', '--count', 'HEAD'], { cwd: fixture }).trim()), commitsBeforePre);
    fs.rmSync(failPre);
    const pre = routeInRepository(['lockspire-finalize', 'pre-verify', '--phase', '139'], fixture);
    assert.equal(pre.exitCode, undefined, pre.errors.join('\n'));
    assert.equal(fs.readFileSync(preCounter, 'utf8'), '2');
    assert.equal(Number(mustRun('git', ['rev-list', '--count', 'HEAD'], { cwd: fixture }).trim()), commitsBeforePre + 1);

    fs.writeFileSync(path.join(fixture, '.planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md'), '---\nstatus: passed\n---\n');
    mustRun('git', ['add', '--all'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'docs(phase-139): record passed verification'], { cwd: fixture });
    fs.writeFileSync(path.join(fixture, '.planning/STATE.md'), '---\ncurrent_phase: 140\nstatus: planning\n---\n');
    mustRun('git', ['add', '--all'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'docs(phase-139): complete phase execution'], { cwd: fixture });
    const candidate = mustRun('git', ['rev-parse', 'HEAD'], { cwd: fixture }).trim();

    fs.writeFileSync(path.join(fixture, '.planning/PROJECT.md'), '# Lockspire\n**Current focus:** Phase 140\n');
    fs.writeFileSync(path.join(fixture, '.planning/STATE.md'), '---\ncurrent_phase: 140\nstatus: ready_to_plan\n---\n');
    const hooks = JSON.stringify({ activeHooks: [{
      kind: 'gate',
      capId: 'lockspire-phase-finalizer',
      check: { predicate: {
        kind: 'command-exit-zero',
        command: 'test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139',
        timeout: 2400,
      } },
      blocking: true,
      onError: 'halt',
    }] });
    const sealed = JSON.parse(mustRun('node', [stateHelper, 'prepare', '139'], { cwd: fixture, input: hooks }));
    assert.equal(sealed.status, 'pending');
    if (hostFixture) assert.equal(sealed.transformation.protocol, hostFixture.stateHelperProtocol);

    const altered = JSON.parse(hooks);
    altered.activeHooks = altered.activeHooks.map((hook) => hook.capId === 'lockspire-phase-finalizer'
      ? { ...hook, blocking: false }
      : hook);
    assert.notEqual(run('node', [stateHelper, 'verify-hooks', '139'], {
      cwd: fixture, input: JSON.stringify(altered),
    }).status, 0);
    assert.equal(JSON.parse(mustRun('node', [stateHelper, 'status'], { cwd: fixture })).status, 'pending');

    fs.writeFileSync(failOnce, '1');
    const failedPost = routeInRepository(['lockspire-finalize', 'post-transition', '--phase', '139'], fixture);
    assert.equal(failedPost.exitCode, 42);
    assert.equal(fs.readFileSync(postCounter, 'utf8'), '1');
    assert.equal(JSON.parse(mustRun('node', [stateHelper, 'status'], { cwd: fixture })).status, 'pending');
    assert.equal(fs.readFileSync(preCounter, 'utf8'), '2');

    const recovered = routeInRepository(['lockspire-finalize', 'post-transition', '--phase', '139'], fixture);
    assert.equal(recovered.exitCode, undefined, recovered.errors.join('\n'));
    assert.equal(fs.readFileSync(postCounter, 'utf8'), '2');
    assert.equal(fs.readFileSync(preCounter, 'utf8'), '2');
    const acceptance = path.join(fixture, '.git/lockspire-phase-139-acceptance-v1.json');
    assert.equal(JSON.parse(fs.readFileSync(acceptance, 'utf8')).baseline_sha, candidate);
    assert.equal(mustRun('git', ['rev-parse', 'refs/heads/main'], { cwd: fixture }).trim(), candidate);
    const commitsAtReceipt = mustRun('git', ['rev-list', '--count', 'HEAD'], { cwd: fixture }).trim();

    const verified = JSON.parse(mustRun('node', [stateHelper, 'verify-hooks', '139'], { cwd: fixture, input: hooks }));
    assert.equal(verified.hooksSha256, sealed.hooksSha256);
    mustRun('node', [stateHelper, 'complete', '139'], { cwd: fixture });
    assert.deepEqual(JSON.parse(mustRun('node', [stateHelper, 'status'], { cwd: fixture })), { exists: false });
    assert.equal(fs.existsSync(acceptance), true);
    assert.equal(mustRun('git', ['rev-list', '--count', 'HEAD'], { cwd: fixture }).trim(), commitsAtReceipt);

    for (const phase of ['140', '141']) {
      const before = [fs.readFileSync(preCounter, 'utf8'), fs.readFileSync(postCounter, 'utf8')];
      const inert = routeInRepository(['lockspire-finalize', 'post-transition', '--phase', phase], fixture);
      assert.equal(inert.exitCode, undefined);
      assert.match(inert.errors[0], /not applicable/);
      assert.deepEqual([fs.readFileSync(preCounter, 'utf8'), fs.readFileSync(postCounter, 'utf8')], before);
    }
  } finally {
    if (prior.GSD_LIFECYCLE_COUNTERS === undefined) delete process.env.GSD_LIFECYCLE_COUNTERS;
    else process.env.GSD_LIFECYCLE_COUNTERS = prior.GSD_LIFECYCLE_COUNTERS;
    if (prior.GSD_FINALIZER_STATE_HELPER === undefined) delete process.env.GSD_FINALIZER_STATE_HELPER;
    else process.env.GSD_FINALIZER_STATE_HELPER = prior.GSD_FINALIZER_STATE_HELPER;
    fs.rmSync(fixture, { recursive: true, force: true });
  }
});

test('Plan 32 finalizer integration remains green under installed host contracts', { skip: skipBeamIntegration }, () => {
  const result = run('mix', [
    'test', 'test/lockspire/release/repository_hygiene_contract_test.exs',
    '--only', 'phase138_finalizer_gap', '--only', 'phase138_finalizer_recovery_gap',
  ], {
    env: { ASDF_ELIXIR_VERSION: '1.19.5-otp-28', ASDF_ERLANG_VERSION: '28.4.1' },
    timeout: 300000,
  });
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  assert.match(result.stdout, /2 tests, 0 failures/);
});

test('Phase 139 exact landing and receipt failure matrices remain green', { skip: skipBeamIntegration }, () => {
  const result = run('mix', [
    'test', 'test/lockspire/release/repository_hygiene_contract_test.exs',
    '--only', 'phase139_final_acceptance', '--only', 'phase139_acceptance_receipt',
  ], {
    env: { ASDF_ELIXIR_VERSION: '1.19.5-otp-28', ASDF_ERLANG_VERSION: '28.1' },
    timeout: 600000,
  });
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  assert.match(result.stdout, /2 tests, 0 failures/);
});

'use strict';

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

const root = path.resolve(__dirname, '..', '..', '..');
const fixturePath = process.env.LOCKSPIRE_GSD_HOST_FIXTURE
  ? path.resolve(root, process.env.LOCKSPIRE_GSD_HOST_FIXTURE)
  : null;
const tools = process.env.GSD_TOOLS
  || (!fixturePath && [
    path.join(root, 'gsd-core/bin/gsd-tools.cjs'),
    path.join(root, '.codex/gsd-core/bin/gsd-tools.cjs'),
    path.join(root, '.claude/gsd-core/bin/gsd-tools.cjs'),
    ...['.codex', '.claude', '.hermes', '.cursor', '.gemini', '.copilot', '.agents']
      .map((runtime) => path.join(os.homedir(), runtime, 'gsd-core/bin/gsd-tools.cjs')),
  ].find((candidate) => fs.existsSync(candidate)));
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

test('Phase 140 recovery preserves stale receipts on replay and rejects overlay edits without ref movement', () => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-phase140-recovery-'));
  let remote = null;
  const ledger = '.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md';
  try {
    const recoveryTools = process.env.GSD_TOOLS || tools;
    assert.ok(recoveryTools, 'recovery fixture requires the GSD tools path');
    mustRun('git', ['init', '-q', '-b', 'main'], { cwd: fixture });
    mustRun('git', ['config', 'user.name', 'Lifecycle Test'], { cwd: fixture });
    mustRun('git', ['config', 'user.email', 'lifecycle@example.com'], { cwd: fixture });
    for (const [relative, bytes] of [
      ['.planning/PROJECT.md', '# Lockspire\n**Current focus:** Phase 139\n'],
      ['.planning/STATE.md', '---\ncurrent_phase: 139\nstatus: verifying\n---\n'],
      ['.planning/ROADMAP.md', '# Roadmap\n'],
      ['.planning/REQUIREMENTS.md', '# Requirements\n'],
    ]) {
      const target = path.join(fixture, relative);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, bytes);
    }
    const helperTarget = path.join(
      fixture,
      'tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs',
    );
    fs.mkdirSync(path.dirname(helperTarget), { recursive: true });
    fs.copyFileSync(stateHelper, helperTarget);
    const inventory = path.join(fixture, 'scripts/maintainer/baseline_inventory.sh');
    fs.mkdirSync(path.dirname(inventory), { recursive: true });
    fs.copyFileSync(path.join(root, 'scripts/maintainer/baseline_inventory.sh'), inventory);
    mustRun('git', ['add', '--all'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'feat: accepted phase base'], { cwd: fixture });
    const baseline = mustRun('git', ['rev-parse', 'HEAD'], { cwd: fixture }).trim();
    fs.writeFileSync(path.join(fixture, '.planning/STATE.md'), '---\ncurrent_phase: 140\nstatus: planning\n---\n');
    mustRun('git', ['add', '.planning/STATE.md'], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'docs: phase 140 planning handoff'], { cwd: fixture });
    const acceptedReceipt = path.join(fixture, '.git/lockspire-phase-139-acceptance-v1.json');
    fs.writeFileSync(acceptedReceipt, JSON.stringify({
      schema: 'lockspire-phase-139-acceptance-v1', baseline_sha: baseline,
    }) + '\n', { mode: 0o600 });
    fs.chmodSync(acceptedReceipt, 0o600);

    const overlayPaths = [
      '.planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md',
      'docs/recovery-note.txt',
    ];
    for (const relative of overlayPaths) {
      const target = path.join(fixture, relative);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, `preserve ${relative}\n`);
    }
    const hooks = JSON.stringify({ activeHooks: [{
      kind: 'gate', capId: 'lockspire-phase-finalizer',
      check: { predicate: {
        kind: 'command-exit-zero',
        command: 'test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139',
        timeout: 2400,
      } },
      blocking: true, onError: 'halt',
    }] });
    const sealed = JSON.parse(mustRun('node', [helperTarget, 'prepare', '139'], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    }));
    assert.equal(sealed.recovery.protocol, 'phase-140-recovery-v1');
    assert.equal(sealed.recovery.baselineSha, baseline);
    assert.deepEqual(sealed.recovery.preservedWorktree.map((entry) => entry.path), overlayPaths.sort());
    const receiptPath = path.join(fixture, '.git/gsd-lifecycle/post-completion-finalizer.json');
    const sealedReceiptBytes = fs.readFileSync(receiptPath);
    const refsBeforeReplay = mustRun('git', ['for-each-ref', '--format=%(refname) %(objectname)'], { cwd: fixture });

    const unchanged = run('bash', [inventory, '--verify-phase-139-posttransition-relation', ledger], {
      cwd: fixture,
      env: { GSD_TOOLS: recoveryTools },
    });
    assert.notEqual(unchanged.status, 0, 'the fixture intentionally lacks the accepted lifecycle chain');
    assert.doesNotMatch(unchanged.stderr + unchanged.stdout, /recovery working-tree identity/);

    fs.appendFileSync(path.join(fixture, overlayPaths[0]), 'changed after seal\n');
    const replayed = JSON.parse(mustRun('node', [helperTarget, 'prepare', '139'], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    }));
    assert.deepEqual(replayed, sealed, 'prepare must not silently refresh a stale pending receipt');
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes, 'stale receipt bytes must remain intact');

    const altered = run('bash', [inventory, '--verify-phase-139-posttransition-relation', ledger], {
      cwd: fixture,
      env: { GSD_TOOLS: recoveryTools },
    });
    assert.notEqual(altered.status, 0);
    assert.match(altered.stderr + altered.stdout, /recovery working-tree identity/);
    assert.equal(
      mustRun('git', ['for-each-ref', '--format=%(refname) %(objectname)'], { cwd: fixture }),
      refsBeforeReplay,
      'stale receipt replay and rejection must not move refs',
    );

    remote = fs.mkdtempSync(path.join(os.tmpdir(), 'lockspire-phase140-origin-'));
    mustRun('git', ['init', '--bare', '-q', remote], { cwd: fixture });
    mustRun('git', ['remote', 'add', 'origin', remote], { cwd: fixture });
    mustRun('git', ['push', '-q', '-u', 'origin', 'main'], { cwd: fixture });
    mustRun('git', ['fetch', '-q', 'origin'], { cwd: fixture });
    mustRun('git', ['switch', '-q', '-c', 'phase140-recovery'], { cwd: fixture });

    const contextPath = '.planning/phases/140-bounded-operational-loose-end-triage/140-CONTEXT.md';
    const discussionPath = '.planning/phases/140-bounded-operational-loose-end-triage/140-DISCUSSION-LOG.md';
    const context = [
      '# Phase 140: Bounded Operational Loose-End Triage - Context',
      ...Array.from({ length: 14 }, (_, index) => `- **D-${String(index + 1).padStart(2, '0')}:** bounded fixture choice`),
      '',
    ].join('\n');
    const discussion = 'The user answered `1` to the bounded fixture choice.\n';
    for (const [relative, bytes] of [[contextPath, context], [discussionPath, discussion]]) {
      const target = path.join(fixture, relative);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, bytes);
    }
    mustRun('git', ['add', contextPath, discussionPath], { cwd: fixture });
    mustRun('git', ['commit', '-qm', 'docs(140): capture phase context (assumptions mode)'], { cwd: fixture });

    const debugOverlay = '.planning/debug/fixture-recovery.md';
    fs.mkdirSync(path.dirname(path.join(fixture, debugOverlay)), { recursive: true });
    fs.writeFileSync(path.join(fixture, debugOverlay), 'fixture recovery evidence\n');
    const staleDigest = crypto.createHash('sha256').update(sealedReceiptBytes).digest('hex');
    const refsBeforeSupersession = mustRun(
      'git', ['for-each-ref', '--format=%(refname) %(objectname)'], { cwd: fixture },
    );
    const wrongDigest = run('node', [helperTarget, 'supersede', '139', '0'.repeat(64)], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    });
    assert.notEqual(wrongDigest.status, 0);
    assert.match(wrongDigest.stderr, /SHA-256 does not match/);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes, 'wrong digest must preserve pending receipt bytes');

    const truncatedAcceptance = run('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    });
    assert.notEqual(truncatedAcceptance.status, 0);
    assert.match(truncatedAcceptance.stderr, /acceptance receipt evidence is malformed/);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes);
    assert.equal(
      fs.existsSync(path.join(fixture, '.git/gsd-lifecycle/receipt-archive', `${staleDigest}.json`)),
      false,
      'invalid durable authority must not create a prior-receipt archive',
    );
    const ciNames = [
      'Dialyzer', 'Release Hygiene Drift', 'Fast Checks', 'Minimum Supported Elixir/OTP',
      'Integration Checks', 'Complete Coverage Evidence', 'Adoption Demo Smoke',
    ];
    const releaseJobs = [
      ['Maintain Release Please PR', 'success'],
      ['Validate exact main head and CI evidence', 'skipped'],
      ['Prove exact package before publication', 'skipped'],
      ['Publish verified release to Hex', 'skipped'],
      ['Verify public install truth', 'skipped'],
    ];
    fs.writeFileSync(acceptedReceipt, `${JSON.stringify({
      schema: 'lockspire-phase-139-acceptance-v1',
      baseline_sha: baseline,
      local_gate: { status: 'pass', exunit_tests: 1 },
      hygiene: { status: 'pass', pass: 1, warn: 0, block: 0 },
      required_ci: {
        status: 'pass', run_id: 1, event: 'push', conclusion: 'success',
        url: 'https://example.invalid/required',
        jobs: ciNames.map((name) => ({ name, status: 'completed', conclusion: 'success' })),
      },
      release_no_publish: {
        status: 'pass', run_id: 2, event: 'push', conclusion: 'success',
        url: 'https://example.invalid/release', outcome: 'no_publish',
        jobs: releaseJobs.map(([name, conclusion]) => ({ name, status: 'completed', conclusion })),
      },
      warn_dispositions: [],
      supplemental_oidf: { classification: 'supplemental_non_certifying', required_gate: false },
      inventory_relation: { status: 'verified' },
      historical_release: {
        source_sha: '5d10ce2219c2e687cf9573c8b280abfb118a47d8',
        ci_run_id: 33141161205,
        release_run_id: 33141484467,
        version: '1.5.0',
        checksum: '30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de',
        tag: 'lockspire-v1.5.0',
        status: 'verified',
      },
      captured_at: '2026-10-05T00:00:00Z',
      repository: 'lockspire/fixture',
    })}\n`, { mode: 0o600 });

    const codePath = 'tools/gsd-capabilities/lockspire-phase-finalizer/untrusted.test.cjs';
    fs.mkdirSync(path.dirname(path.join(fixture, codePath)), { recursive: true });
    fs.writeFileSync(path.join(fixture, codePath), 'untrusted code\n');
    const codeRejected = run('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    });
    assert.notEqual(codeRejected.status, 0);
    assert.match(codeRejected.stderr, /only unstaged planning and debug notes/);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes, 'code-path dirt must preserve pending receipt bytes');
    fs.unlinkSync(path.join(fixture, codePath));

    const syncFailurePreload = path.join(fixture, '.git/sync-failure-preload.cjs');
    fs.writeFileSync(syncFailurePreload, [
      "const fs = require('node:fs');",
      'const original = fs.fsyncSync;',
      'let calls = 0;',
      'fs.fsyncSync = (descriptor) => {',
      '  calls += 1;',
      '  if (calls === Number(process.env.LOCKSPIRE_TEST_FAIL_FSYNC_AT)) {',
      '    const error = new Error("simulated directory sync failure"); error.code = "EIO"; throw error;',
      '  }',
      '  return original(descriptor);',
      '};',
      '',
    ].join('\n'));
    const failedArchiveSync = run('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: {
        GSD_TOOLS: recoveryTools, NODE_OPTIONS: `--require=${syncFailurePreload}`,
        LOCKSPIRE_TEST_FAIL_FSYNC_AT: '2',
      },
    });
    assert.notEqual(failedArchiveSync.status, 0);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes);
    const retryArchiveSync = run('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: {
        GSD_TOOLS: recoveryTools, NODE_OPTIONS: `--require=${syncFailurePreload}`,
        LOCKSPIRE_TEST_FAIL_FSYNC_AT: '1',
      },
    });
    assert.notEqual(retryArchiveSync.status, 0);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes);
    const failedSync = run('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: {
        GSD_TOOLS: recoveryTools, NODE_OPTIONS: `--require=${syncFailurePreload}`,
        LOCKSPIRE_TEST_FAIL_FSYNC_AT: '3',
      },
    });
    assert.notEqual(failedSync.status, 0);
    assert.match(failedSync.stderr, /successor publication failed; prior pending receipt restored/);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes);

    const wrapperDir = path.join(fixture, '.git/test-bin');
    fs.mkdirSync(wrapperDir);
    const gitCounter = path.join(wrapperDir, 'for-each-ref-count');
    fs.writeFileSync(gitCounter, '0\n');
    const gitWrapper = path.join(wrapperDir, 'git');
    fs.writeFileSync(gitWrapper, [
      '#!/bin/sh',
      'if [ "$1" = "for-each-ref" ]; then',
      '  count=$(cat "$LOCKSPIRE_TEST_GIT_COUNTER")',
      '  count=$((count + 1))',
      '  printf "%s\\n" "$count" > "$LOCKSPIRE_TEST_GIT_COUNTER"',
      '  if [ "$count" -eq 4 ]; then',
      '    "$LOCKSPIRE_TEST_GIT_REAL" "$@"',
      '    printf "refs/heads/fixture-drift %040d\\n" 0',
      '    exit 0',
      '  fi',
      'fi',
      'exec "$LOCKSPIRE_TEST_GIT_REAL" "$@"',
      '',
    ].join('\n'), { mode: 0o755 });
    const driftedRefs = run('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: {
        GSD_TOOLS: recoveryTools,
        PATH: `${wrapperDir}:${process.env.PATH}`,
        LOCKSPIRE_TEST_GIT_COUNTER: gitCounter,
        LOCKSPIRE_TEST_GIT_REAL: mustRun('which', ['git']).trim(),
      },
    });
    assert.notEqual(driftedRefs.status, 0);
    assert.match(driftedRefs.stderr, /prior pending receipt restored/);
    assert.deepEqual(fs.readFileSync(receiptPath), sealedReceiptBytes);
    assert.equal(fs.readFileSync(gitCounter, 'utf8').trim(), '4');

    const superseded = JSON.parse(mustRun('node', [helperTarget, 'supersede', '139', staleDigest], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    }));
    const successor = superseded.receipt;
    assert.equal(successor.recovery.protocol, 'phase-140-recovery-v2');
    assert.equal(successor.recovery.baselineSha, baseline);
    assert.equal(successor.recovery.supersedesSha256, staleDigest);
    assert.equal(successor.after.head, mustRun('git', ['rev-parse', 'HEAD'], { cwd: fixture }).trim());
    assert.deepEqual(
      successor.recovery.preservedWorktree.map((entry) => entry.path),
      [...overlayPaths, debugOverlay].sort(),
    );
    const archivePath = path.join(fixture, '.git/gsd-lifecycle/receipt-archive', `${staleDigest}.json`);
    assert.deepEqual(fs.readFileSync(archivePath), sealedReceiptBytes, 'receipt archive must retain exact prior receipt bytes');
    assert.equal(fs.statSync(archivePath).mode & 0o777, 0o600);
    const successorBytes = fs.readFileSync(receiptPath);
    const repeated = run('node', [helperTarget, 'supersede', '139',
      crypto.createHash('sha256').update(successorBytes).digest('hex')], {
      cwd: fixture,
      input: hooks,
      env: { GSD_TOOLS: recoveryTools },
    });
    assert.notEqual(repeated.status, 0);
    assert.match(repeated.stderr, /v2 receipt cannot be superseded again/);
    assert.deepEqual(fs.readFileSync(receiptPath), successorBytes);
    const mutationLock = path.join(fixture, '.git/gsd-lifecycle/receipt-mutation.lock');
    fs.mkdirSync(mutationLock);
    const simultaneousCompletion = run('node', [helperTarget, 'complete', '139'], { cwd: fixture });
    assert.notEqual(simultaneousCompletion.status, 0);
    assert.match(simultaneousCompletion.stderr, /another receipt mutation is active/);
    assert.deepEqual(fs.readFileSync(receiptPath), successorBytes);
    fs.rmdirSync(mutationLock);
    const acceptanceScript = fs.readFileSync(
      path.join(root, 'scripts/maintainer/finalize_phase_139_acceptance.sh'),
      'utf8',
    );
    const resolverMatch = acceptanceScript.match(
      /resolve_sealed_candidate\(\) \{\n  python3 - "\$ROOT" "\$HOST_RECEIPT" <<'PY'\n([\s\S]*?)\nPY\n\}/,
    );
    assert.ok(resolverMatch, 'acceptance script must retain its embedded sealed-candidate resolver');
    const resolvedV2 = run('python3', ['-c', resolverMatch[1], fixture, receiptPath], { cwd: fixture });
    assert.equal(
      resolvedV2.status,
      0,
      `valid v2 lineage must resolve before the publication barrier: ${resolvedV2.stderr}`,
    );
    assert.equal(resolvedV2.stdout.trim(), successor.after.head);
    const tamperedPrior = JSON.parse(fs.readFileSync(archivePath, 'utf8'));
    tamperedPrior.transformation.allowedPaths = ['.planning/debug/attacker.md'];
    const tamperedPriorBytes = Buffer.from(`${JSON.stringify(tamperedPrior)}\n`);
    const tamperedDigest = crypto.createHash('sha256').update(tamperedPriorBytes).digest('hex');
    const tamperedArchivePath = path.join(
      fixture,
      '.git/gsd-lifecycle/receipt-archive',
      `${tamperedDigest}.json`,
    );
    fs.writeFileSync(tamperedArchivePath, tamperedPriorBytes, { mode: 0o600 });
    const tamperedSuccessor = structuredClone(successor);
    tamperedSuccessor.recovery.supersedesSha256 = tamperedDigest;
    fs.writeFileSync(receiptPath, `${JSON.stringify(tamperedSuccessor)}\n`, { mode: 0o600 });
    const alteredLineage = run('python3', ['-c', resolverMatch[1], fixture, receiptPath], { cwd: fixture });
    assert.notEqual(alteredLineage.status, 0, 'changed archived allowedPaths must fail closed');
    assert.match(alteredLineage.stderr, /superseded receipt lineage/);
    fs.unlinkSync(tamperedArchivePath);
    fs.writeFileSync(receiptPath, `${JSON.stringify(successor)}\n`, { mode: 0o600 });
    assert.equal(fs.statSync(receiptPath).mode & 0o777, 0o600);
    const validSuccessor = run('bash', [
      path.join(root, 'scripts/maintainer/baseline_inventory.sh'),
      '--verify-phase-139-posttransition-relation',
      ledger,
    ], { cwd: fixture, env: { GSD_TOOLS: recoveryTools } });
    assert.notEqual(validSuccessor.status, 0, 'the fixture intentionally lacks the complete accepted lifecycle chain');
    assert.doesNotMatch(
      validSuccessor.stderr + validSuccessor.stdout,
      /recovery envelope|supersession envelope|superseded receipt archive|superseded receipt lineage|recovery working-tree identity/,
      'a valid v2 receipt must pass identity and lineage validation before the unrelated chain fixture fails',
    );
    fs.appendFileSync(path.join(fixture, debugOverlay), 'changed after supersession\n');
    const driftedSuccessor = run('bash', [
      path.join(root, 'scripts/maintainer/baseline_inventory.sh'),
      '--verify-phase-139-posttransition-relation',
      ledger,
    ], { cwd: fixture, env: { GSD_TOOLS: recoveryTools } });
    assert.notEqual(driftedSuccessor.status, 0);
    assert.match(driftedSuccessor.stderr + driftedSuccessor.stdout, /recovery working-tree identity/);
    const driftedResolver = run('python3', ['-c', resolverMatch[1], fixture, receiptPath], { cwd: fixture });
    assert.notEqual(driftedResolver.status, 0, 'overlay drift must fail sealed-candidate authentication');
    assert.match(driftedResolver.stderr, /sealed repository state changed|preserved planning worktree changed/);
    assert.deepEqual(
      mustRun('git', ['for-each-ref', '--format=%(refname) %(objectname)'], { cwd: fixture }),
      refsBeforeSupersession,
      'receipt supersession must not move any refs',
    );
    const inventoryScript = fs.readFileSync(path.join(root, 'scripts/maintainer/baseline_inventory.sh'), 'utf8');
    assert.match(acceptanceScript, /phase-140-recovery-v2/);
    assert.match(
      acceptanceScript,
      /candidate preparation is blocked until its exact SHA is explicitly published/,
      'supersession must preserve the separate exact-SHA publication barrier',
    );
    assert.match(inventoryScript, /phase-140-recovery-v2\)[\s\S]*?git merge-base --is-ancestor/);
  } finally {
    if (remote) fs.rmSync(remote, { recursive: true, force: true });
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

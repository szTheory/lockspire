'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const childProcess = require('node:child_process');

const MAX_RECEIPT_BYTES = 1024 * 1024;
const ALLOWED_PATHS = [
  '.planning/PROJECT.md',
  '.planning/STATE.md',
  '.planning/ROADMAP.md',
  '.planning/REQUIREMENTS.md',
];

function fail(message) {
  process.stderr.write(`lockspire finalizer state: ${message}\n`);
  process.exit(1);
}

function git(args, options = {}) {
  const result = childProcess.spawnSync('git', args, {
    cwd: options.cwd || process.cwd(),
    encoding: options.encoding === undefined ? 'utf8' : options.encoding,
    shell: false,
    maxBuffer: MAX_RECEIPT_BYTES,
  });
  if (result.status !== 0) fail('Git observation failed');
  return result.stdout;
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function compact(value) {
  return JSON.stringify(value);
}

function projectRoot() {
  return fs.realpathSync(git(['rev-parse', '--show-toplevel']).trim());
}

function commonDir(root) {
  return fs.realpathSync(git(['rev-parse', '--path-format=absolute', '--git-common-dir'], { cwd: root }).trim());
}

function receiptPath(root) {
  return path.join(commonDir(root), 'gsd-lifecycle', 'post-completion-finalizer.json');
}

function readSmallRegularFile(target) {
  const stat = fs.lstatSync(target);
  if (!stat.isFile() || stat.size <= 0 || stat.size > MAX_RECEIPT_BYTES) fail('unsafe receipt file');
  return fs.readFileSync(target, 'utf8');
}

function readReceipt(root) {
  const target = receiptPath(root);
  if (!fs.existsSync(target)) return null;
  let receipt;
  try {
    receipt = JSON.parse(readSmallRegularFile(target));
  } catch (_) {
    fail('receipt is malformed');
  }
  return receipt;
}

function writeReceipt(root, receipt) {
  const target = receiptPath(root);
  const directory = path.dirname(target);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const temporary = path.join(directory, `.post-completion-finalizer.${process.pid}.${crypto.randomBytes(8).toString('hex')}`);
  const bytes = compact(receipt) + '\n';
  if (Buffer.byteLength(bytes) > MAX_RECEIPT_BYTES) fail('receipt exceeds size limit');
  try {
    fs.writeFileSync(temporary, bytes, { mode: 0o600, flag: 'wx' });
    fs.chmodSync(temporary, 0o600);
    fs.renameSync(temporary, target);
    fs.chmodSync(target, 0o600);
  } finally {
    try { fs.unlinkSync(temporary); } catch (_) { /* already published */ }
  }
}

function identity(root, relative) {
  const target = path.join(root, relative);
  if (!fs.existsSync(target)) return { exists: false };
  const stat = fs.lstatSync(target);
  if (!stat.isFile()) return { exists: true, type: 'non-file', mode: stat.mode & 0o777 };
  const bytes = fs.readFileSync(target);
  return {
    exists: true,
    type: 'file',
    mode: stat.mode & 0o777,
    size: bytes.length,
    sha256: sha256(bytes),
  };
}

function observation(root) {
  const porcelain = git(['status', '--porcelain=v1', '-z', '--untracked-files=all'], {
    cwd: root,
    encoding: null,
  });
  const result = {
    head: git(['rev-parse', 'HEAD'], { cwd: root }).trim(),
    porcelainSha256: sha256(porcelain),
  };
  for (const relative of ALLOWED_PATHS) {
    const key = path.basename(relative, '.md').toLowerCase();
    result[key] = identity(root, relative);
  }
  return { result, porcelain };
}

function committedIdentity(root, head, relative) {
  const probe = childProcess.spawnSync('git', ['cat-file', '-e', `${head}:${relative}`], {
    cwd: root,
    shell: false,
    stdio: 'ignore',
  });
  if (probe.status !== 0) return { exists: false };
  const bytes = git(['show', `${head}:${relative}`], { cwd: root, encoding: null });
  const entry = git(['ls-tree', head, '--', relative], { cwd: root }).trim().split(/\s+/)[0];
  return {
    exists: true,
    type: 'file',
    mode: entry === '100755' ? 0o755 : 0o644,
    size: bytes.length,
    sha256: sha256(bytes),
  };
}

function committedObservation(root, head) {
  const result = { head, porcelainSha256: sha256(Buffer.alloc(0)) };
  for (const relative of ALLOWED_PATHS) {
    const key = path.basename(relative, '.md').toLowerCase();
    result[key] = committedIdentity(root, head, relative);
  }
  return result;
}

function resolveCore(root) {
  const candidates = [
    process.env.GSD_TOOLS,
    path.join(root, 'gsd-core/bin/gsd-tools.cjs'),
    path.join(root, '.codex/gsd-core/bin/gsd-tools.cjs'),
    path.join(root, '.claude/gsd-core/bin/gsd-tools.cjs'),
    path.join(root, 'tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.codex/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.claude/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.hermes/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.cursor/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.gemini/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.copilot/gsd-core/bin/gsd-tools.cjs'),
    path.join(os.homedir(), '.agents/gsd-core/bin/gsd-tools.cjs'),
  ].filter(Boolean);
  const tools = candidates.find((candidate) => {
    try { return fs.lstatSync(candidate).isFile(); } catch (_) { return false; }
  });
  if (!tools) fail('GSD runtime is unavailable');
  return path.dirname(path.dirname(fs.realpathSync(tools)));
}

function descriptor(target, relative) {
  const stat = fs.lstatSync(target);
  if (!stat.isFile() || stat.size <= 0 || stat.size > MAX_RECEIPT_BYTES) fail('writer dependency is unsafe');
  const bytes = fs.readFileSync(target);
  return { path: relative, mode: stat.mode & 0o777, size: bytes.length, sha256: sha256(bytes) };
}

function writer(root) {
  const core = resolveCore(root);
  return {
    protocol: 'gsd-transition-v1',
    allowedPaths: ALLOWED_PATHS,
    workflow: descriptor(path.join(core, 'workflows/transition.md'), 'workflows/transition.md'),
    executeWorkflow: descriptor(path.join(core, 'workflows/execute-phase.md'), 'workflows/execute-phase.md'),
    planWorkflow: descriptor(path.join(core, 'workflows/plan-phase.md'), 'workflows/plan-phase.md'),
    stateHelper: descriptor(
      __filename,
      'tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs',
    ),
  };
}

function readStdin() {
  const chunks = [];
  let length = 0;
  const buffer = Buffer.alloc(64 * 1024);
  for (;;) {
    const count = fs.readSync(0, buffer, 0, buffer.length, null);
    if (count === 0) break;
    length += count;
    if (length > MAX_RECEIPT_BYTES) fail('hook envelope exceeds size limit');
    chunks.push(Buffer.from(buffer.subarray(0, count)));
  }
  return Buffer.concat(chunks).toString('utf8');
}

function normalizeHooks(raw) {
  let envelope;
  try { envelope = JSON.parse(raw); } catch (_) { fail('hook envelope is malformed'); }
  const hooks = Array.isArray(envelope.activeHooks) ? envelope.activeHooks : [];
  const normalized = hooks.flatMap((hook) => {
    if (!hook || hook.kind !== 'step' || hook.capId !== 'lockspire-phase-finalizer' ||
        !hook.ref || hook.ref.command !== 'lockspire-finalize post-transition' ||
        hook.onError !== 'halt') return [];
    return [{ capId: hook.capId, command: hook.ref.command, onError: hook.onError }];
  });
  if (normalized.length !== 1) fail('exact post-transition hook is unavailable');
  return normalized;
}

function normalizePlanPreGate(raw) {
  let envelope;
  try { envelope = JSON.parse(raw); } catch (_) { fail('hook envelope is malformed'); }
  const hooks = Array.isArray(envelope.activeHooks) ? envelope.activeHooks : [];
  const expectedPredicate = {
    kind: 'command-exit-zero',
    command: 'test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139',
    timeout: 2400,
  };
  const normalized = hooks.flatMap((hook) => {
    const predicate = hook && hook.check && hook.check.predicate;
    if (!hook || hook.kind !== 'gate' || hook.capId !== 'lockspire-phase-finalizer' ||
        !predicate || Object.keys(predicate).sort().join(',') !== 'command,kind,timeout' ||
        predicate.kind !== expectedPredicate.kind ||
        predicate.command !== expectedPredicate.command ||
        predicate.timeout !== expectedPredicate.timeout ||
        hook.blocking !== true || hook.onError !== 'halt') return [];
    return [{
      capId: hook.capId,
      predicate: expectedPredicate,
      blocking: hook.blocking,
      onError: hook.onError,
    }];
  });
  if (normalized.length !== 1) fail('exact plan-pre finalizer gate is unavailable');
  return normalized;
}

function assertPhase(value) {
  if (!/^(0|[1-9][0-9]*)$/.test(value || '')) fail('phase must be numeric');
}

function begin(root, phase) {
  if (readReceipt(root)) fail('pending receipt already exists');
  const before = observation(root);
  if (before.porcelain.length !== 0) fail('begin requires a clean worktree');
  const receipt = {
    schemaVersion: 1,
    status: 'preparing',
    phase,
    point: 'execute:complete:post',
    writer: writer(root),
    before: before.result,
  };
  writeReceipt(root, receipt);
  process.stdout.write(compact(receipt) + '\n');
}

function seal(root, phase) {
  const receipt = readReceipt(root);
  if (!receipt || receipt.status !== 'preparing' || receipt.phase !== phase) fail('preparing receipt is unavailable');
  const hooks = normalizeHooks(readStdin());
  const after = observation(root);
  if (after.result.head !== receipt.before.head) fail('HEAD changed during transition sealing');
  const changed = after.porcelain.toString('utf8').split('\0').filter(Boolean).map((record) => record.slice(3)).sort();
  if (compact(changed) !== compact(['.planning/PROJECT.md', '.planning/STATE.md'])) {
    fail('transition changed an unauthorized path set');
  }
  const evidence = {
    protocol: 'gsd-transition-v1',
    writer: receipt.writer,
    before: receipt.before,
    after: after.result,
  };
  const sealed = {
    ...receipt,
    status: 'pending',
    hooks,
    hooksSha256: sha256(compact(hooks)),
    after: after.result,
    transformation: {
      protocol: 'gsd-transition-v1',
      allowedPaths: ALLOWED_PATHS,
      sha256: sha256(compact(evidence)),
    },
  };
  writeReceipt(root, sealed);
  process.stdout.write(compact(sealed) + '\n');
}

function prepare(root, phase) {
  const existing = readReceipt(root);
  if (existing) {
    if (existing.status !== 'pending' || existing.phase !== phase || existing.point !== 'plan:pre') {
      fail('incompatible pending receipt already exists');
    }
    process.stdout.write(compact(existing) + '\n');
    return;
  }
  if (phase !== '139') fail('prepare is only available for Phase 139');
  const hooks = normalizePlanPreGate(readStdin());
  const after = observation(root);
  const changed = after.porcelain.toString('utf8').split('\0').filter(Boolean)
    .map((record) => record.slice(3)).sort();
  if (compact(changed) !== compact(['.planning/PROJECT.md', '.planning/STATE.md'])) {
    fail('plan-pre preparation requires the exact transition path set');
  }
  const before = committedObservation(root, after.result.head);
  const receiptWriter = writer(root);
  const evidence = {
    protocol: 'gsd-transition-v1',
    writer: receiptWriter,
    before,
    after: after.result,
  };
  const receipt = {
    schemaVersion: 1,
    status: 'pending',
    phase,
    point: 'plan:pre',
    writer: receiptWriter,
    before,
    hooks,
    hooksSha256: sha256(compact(hooks)),
    after: after.result,
    transformation: {
      protocol: 'gsd-transition-v1',
      allowedPaths: ALLOWED_PATHS,
      sha256: sha256(compact(evidence)),
    },
  };
  writeReceipt(root, receipt);
  process.stdout.write(compact(receipt) + '\n');
}

function verifyHooks(root, phase) {
  const receipt = readReceipt(root);
  if (!receipt || receipt.status !== 'pending' || receipt.phase !== phase) fail('pending receipt is unavailable');
  const hooks = receipt.point === 'plan:pre'
    ? normalizePlanPreGate(readStdin())
    : normalizeHooks(readStdin());
  if (compact(hooks) !== compact(receipt.hooks) || sha256(compact(hooks)) !== receipt.hooksSha256) {
    fail('hook identity changed');
  }
  process.stdout.write(compact({ valid: true, hooksSha256: receipt.hooksSha256 }) + '\n');
}

function complete(root, phase) {
  const receipt = readReceipt(root);
  if (!receipt || receipt.status !== 'pending' || receipt.phase !== phase) fail('pending receipt is unavailable');
  fs.unlinkSync(receiptPath(root));
  process.stdout.write(compact({ completed: true, phase }) + '\n');
}

const [command, phase] = process.argv.slice(2);
const root = projectRoot();
switch (command) {
  case 'status': {
    const receipt = readReceipt(root);
    process.stdout.write(compact(receipt || { exists: false }) + '\n');
    break;
  }
  case 'begin':
    assertPhase(phase);
    begin(root, phase);
    break;
  case 'seal':
    assertPhase(phase);
    seal(root, phase);
    break;
  case 'prepare':
    assertPhase(phase);
    prepare(root, phase);
    break;
  case 'verify-hooks':
    assertPhase(phase);
    verifyHooks(root, phase);
    break;
  case 'complete':
    assertPhase(phase);
    complete(root, phase);
    break;
  default:
    fail('expected begin, seal, prepare, verify-hooks, status, or complete');
}

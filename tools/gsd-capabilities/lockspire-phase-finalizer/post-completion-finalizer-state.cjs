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

function writeReceiptBytes(root, bytes) {
  const target = receiptPath(root);
  const directory = path.dirname(target);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const temporary = path.join(directory, `.post-completion-finalizer.${process.pid}.${crypto.randomBytes(8).toString('hex')}`);
  if (bytes.length <= 0 || bytes.length > MAX_RECEIPT_BYTES) fail('receipt exceeds size limit');
  let descriptor;
  try {
    descriptor = fs.openSync(temporary, 'wx', 0o600);
    fs.writeFileSync(descriptor, bytes);
    fs.fchmodSync(descriptor, 0o600);
    fs.fsyncSync(descriptor);
    fs.closeSync(descriptor);
    descriptor = undefined;
    fs.renameSync(temporary, target);
    fsyncDirectory(directory);
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    try { fs.unlinkSync(temporary); } catch (_) { /* already published */ }
  }
}

function writeReceipt(root, receipt) {
  writeReceiptBytes(root, Buffer.from(`${compact(receipt)}\n`));
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

function preservedPlanningWorktree(root, porcelain) {
  const entries = [];
  let totalBytes = 0;
  const records = porcelain.toString('utf8').split('\0').filter(Boolean);
  for (const record of records) {
    if (record.length < 4 || record[2] !== ' ') fail('malformed preserved worktree status');
    const status = record.slice(0, 2);
    const relative = record.slice(3);
    const allowedPath = /^\.planning\/phases\/[0-9]{3}-[^/]+\/[A-Za-z0-9._-]+\.md$/.test(relative) ||
      /^docs\/[A-Za-z0-9._-]+\.(?:md|txt)$/.test(relative);
    if (!allowedPath || (status !== ' M' && status !== '??')) {
      fail('recovery permits only unstaged planning-note overlays');
    }
    const target = path.join(root, relative);
    const stat = fs.lstatSync(target);
    if (!stat.isFile()) fail('preserved planning overlay is not a regular file');
    const bytes = fs.readFileSync(target);
    totalBytes += bytes.length;
    if (entries.length >= 32 || totalBytes > 4 * 1024 * 1024) fail('preserved planning overlay exceeds limits');
    entries.push({
      path: relative,
      status,
      mode: stat.mode & 0o777,
      size: bytes.length,
      sha256: sha256(bytes),
    });
  }
  return entries.sort((left, right) => (left.path < right.path ? -1 : left.path > right.path ? 1 : 0));
}

function preservedSupersessionWorktree(root, porcelain) {
  const entries = [];
  let totalBytes = 0;
  const records = porcelain.toString('utf8').split('\0').filter(Boolean);
  for (const record of records) {
    if (record.length < 4 || record[2] !== ' ') fail('malformed supersession worktree status');
    const status = record.slice(0, 2);
    const relative = record.slice(3);
    const allowedPath = /^\.planning\/phases\/[0-9]{3}-[^/]+\/[A-Za-z0-9._-]+\.md$/.test(relative) ||
      /^\.planning\/debug\/[a-z0-9][a-z0-9-]*\.md$/.test(relative) ||
      /^docs\/[A-Za-z0-9._-]+\.(?:md|txt)$/.test(relative);
    if (!allowedPath || (status !== ' M' && status !== '??')) {
      fail('supersession permits only unstaged planning and debug notes');
    }
    const target = path.join(root, relative);
    const stat = fs.lstatSync(target);
    if (!stat.isFile()) fail('supersession overlay is not a regular file');
    const bytes = fs.readFileSync(target);
    totalBytes += bytes.length;
    if (entries.length >= 32 || totalBytes > 4 * 1024 * 1024) fail('supersession overlay exceeds limits');
    entries.push({
      path: relative,
      status,
      mode: stat.mode & 0o777,
      size: bytes.length,
      sha256: sha256(bytes),
    });
  }
  return entries.sort((left, right) => (left.path < right.path ? -1 : left.path > right.path ? 1 : 0));
}

function acquireFinalizerLock(root) {
  const lockPath = path.join(commonDir(root), 'lockspire-phase-139-acceptance.lock');
  try {
    fs.mkdirSync(lockPath, { mode: 0o700 });
  } catch (_) {
    fail('another final acceptance is active');
  }
  process.once('exit', () => {
    try { fs.rmdirSync(lockPath); } catch (_) { /* a failed cleanup remains fail-closed */ }
  });
  return lockPath;
}

function acquireReceiptMutationLock(root) {
  const directory = path.join(commonDir(root), 'gsd-lifecycle');
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const lockPath = path.join(directory, 'receipt-mutation.lock');
  try {
    fs.mkdirSync(lockPath, { mode: 0o700 });
  } catch (_) {
    fail('another receipt mutation is active');
  }
  process.once('exit', () => {
    try { fs.rmdirSync(lockPath); } catch (_) { /* a failed cleanup remains fail-closed */ }
  });
}

function fsyncDirectory(directory) {
  const descriptor = fs.openSync(directory, fs.constants.O_RDONLY);
  try { fs.fsyncSync(descriptor); } finally { fs.closeSync(descriptor); }
}

function archiveReceipt(root, bytes, digest) {
  const lifecycleDirectory = path.join(commonDir(root), 'gsd-lifecycle');
  const lifecycleStat = fs.lstatSync(lifecycleDirectory);
  if (!lifecycleStat.isDirectory()) fail('lifecycle receipt directory is unsafe');
  const directory = path.join(lifecycleDirectory, 'receipt-archive');
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const directoryStat = fs.lstatSync(directory);
  if (!directoryStat.isDirectory() || (directoryStat.mode & 0o777) !== 0o700) {
    fail('receipt archive directory is unsafe');
  }
  const target = path.join(directory, `${digest}.json`);
  if (fs.existsSync(target)) {
    const info = fs.lstatSync(target);
    if (!info.isFile() || (info.mode & 0o777) !== 0o600 || !fs.readFileSync(target).equals(bytes)) {
      fail('receipt archive conflicts with prior bytes');
    }
    fsyncDirectory(directory);
    return target;
  }
  const temporary = path.join(directory, `.receipt.${process.pid}.${crypto.randomBytes(8).toString('hex')}`);
  let descriptor;
  try {
    descriptor = fs.openSync(temporary, 'wx', 0o600);
    fs.writeFileSync(descriptor, bytes);
    fs.fsyncSync(descriptor);
    fs.closeSync(descriptor);
    descriptor = undefined;
    try {
      fs.linkSync(temporary, target);
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
      const info = fs.lstatSync(target);
      if (!info.isFile() || (info.mode & 0o777) !== 0o600 || !fs.readFileSync(target).equals(bytes)) {
        fail('receipt archive conflicts with prior bytes');
      }
    }
    fsyncDirectory(directory);
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    try { fs.unlinkSync(temporary); } catch (_) { /* already removed */ }
  }
  return target;
}

function ancestor(root, older, newer, message) {
  const result = childProcess.spawnSync('git', ['merge-base', '--is-ancestor', older, newer], {
    cwd: root,
    shell: false,
    stdio: 'ignore',
  });
  if (result.status !== 0) fail(message);
}

function trackingRemoteMain(root) {
  if (process.env.LOCKSPIRE_INVENTORY_REMOTE && process.env.LOCKSPIRE_INVENTORY_REMOTE !== 'origin') {
    fail('receipt supersession requires the finalizer origin remote');
  }
  const tracking = git(['rev-parse', 'refs/remotes/origin/main'], { cwd: root }).trim();
  const advertised = git(['ls-remote', 'origin', 'refs/heads/main'], { cwd: root }).trim().split(/\s+/)[0];
  if (!/^[0-9a-f]{40}$/.test(tracking) || tracking !== advertised) {
    fail('main tracking ref does not match advertised remote main');
  }
  return tracking;
}

function refsUnchanged(root, snapshot) {
  const result = childProcess.spawnSync('git', ['for-each-ref', '--format=%(refname) %(objectname)'], {
    cwd: root, encoding: 'utf8', shell: false, maxBuffer: MAX_RECEIPT_BYTES,
  });
  return result.status === 0 && result.stdout === snapshot;
}

function remoteMainUnchanged(root, expected) {
  const result = childProcess.spawnSync('git', ['ls-remote', 'origin', 'refs/heads/main'], {
    cwd: root, encoding: 'utf8', shell: false, maxBuffer: MAX_RECEIPT_BYTES,
  });
  return result.status === 0 && result.stdout.trim().split(/\s+/)[0] === expected;
}

function pendingDigest(target) {
  try { return sha256(fs.readFileSync(target)); } catch (_) { return 'unreadable'; }
}

function restorePriorReceipt(root, previousBytes, successorDigest, stage) {
  const target = receiptPath(root);
  const previousDigest = sha256(previousBytes);
  const observed = pendingDigest(target);
  if (observed === previousDigest) fail(`${stage}; prior pending receipt preserved`);
  if (observed !== successorDigest) {
    fail(`${stage}; pending receipt state is ${observed}; archived prior SHA-256 is ${previousDigest}`);
  }
  let restoreFailed = false;
  try { writeReceiptBytes(root, previousBytes); } catch (_) { restoreFailed = true; }
  const restored = pendingDigest(target);
  if (restored === previousDigest && !restoreFailed) fail(`${stage}; prior pending receipt restored`);
  if (restored === previousDigest) {
    fail(`${stage}; prior pending receipt is visible but directory durability is unconfirmed`);
  }
  fail(`${stage}; pending receipt state is ${restored}; archived prior SHA-256 is ${previousDigest}`);
}

function supersede(root, phase, expectedDigest) {
  if (phase !== '139') fail('supersede is only available for Phase 139');
  if (!/^[0-9a-f]{64}$/.test(expectedDigest || '')) fail('expected receipt SHA-256 is malformed');
  const gitDirectory = fs.realpathSync(git(['rev-parse', '--path-format=absolute', '--git-dir'], { cwd: root }).trim());
  if (gitDirectory !== commonDir(root)) fail('linked worktrees cannot supersede Phase 139 receipts');
  const lockPath = acquireFinalizerLock(root);
  acquireReceiptMutationLock(root);
  const refsBefore = git(['for-each-ref', '--format=%(refname) %(objectname)'], { cwd: root });
  const target = receiptPath(root);
  const info = fs.lstatSync(target);
  if (!info.isFile() || (info.mode & 0o777) !== 0o600 || info.size <= 0 || info.size > MAX_RECEIPT_BYTES) {
    fail('pending receipt is unsafe');
  }
  const previousBytes = fs.readFileSync(target);
  const previousDigest = sha256(previousBytes);
  if (previousDigest !== expectedDigest) fail('pending receipt SHA-256 does not match expected value');
  let previous;
  try { previous = JSON.parse(previousBytes.toString('utf8')); } catch (_) { fail('pending receipt is malformed'); }
  if (previous.schemaVersion !== 1 || previous.status !== 'pending' || previous.phase !== phase ||
      previous.point !== 'plan:pre' || typeof previous.after?.head !== 'string' ||
      !/^[0-9a-f]{40}$/.test(previous.after.head)) {
    fail('pending receipt cannot be superseded');
  }
  if (previous.recovery?.protocol === 'phase-140-recovery-v2') {
    fail('a v2 receipt cannot be superseded again');
  }
  if (!previous.before || previous.before.porcelainSha256 !== sha256(Buffer.alloc(0)) ||
      typeof previous.before.head !== 'string' || !/^[0-9a-f]{40}$/.test(previous.before.head) ||
      !/^[0-9a-f]{64}$/.test(previous.after.porcelainSha256 || '') ||
      previous.writer?.protocol !== 'gsd-transition-v1' ||
      compact(previous.writer.allowedPaths) !== compact(ALLOWED_PATHS) ||
      compact(previous.transformation?.allowedPaths) !== compact(ALLOWED_PATHS) ||
      previous.transformation?.protocol !== 'gsd-transition-v1' ||
      !Array.isArray(previous.hooks) || previous.hooksSha256 !== sha256(compact(previous.hooks))) {
    fail('pending receipt provenance is malformed');
  }
  const priorEvidence = {
    protocol: 'gsd-transition-v1',
    writer: previous.writer,
    before: previous.before,
    after: previous.after,
    ...(previous.recovery ? { recovery: previous.recovery } : {}),
  };
  if (previous.transformation.sha256 !== sha256(compact(priorEvidence))) {
    fail('pending receipt provenance digest is invalid');
  }
  const hooks = normalizePlanPreGate(readStdin());
  if (compact(previous.hooks) !== compact(hooks) || previous.hooksSha256 !== sha256(compact(hooks))) {
    fail('pending receipt hook identity changed');
  }
  const after = observation(root);
  const baselineSha = acceptedPhase139Base(root, true);
  const head = after.result.head;
  ancestor(root, baselineSha, head, 'current HEAD does not descend from the accepted Phase 139 SHA');
  ancestor(root, previous.after.head, head, 'current HEAD does not descend from the pending receipt candidate');
  const localMain = git(['rev-parse', 'refs/heads/main'], { cwd: root }).trim();
  ancestor(root, localMain, head, 'local main is not an ancestor of current HEAD');
  const remoteMain = trackingRemoteMain(root);
  ancestor(root, remoteMain, head, 'tracked remote main is not an ancestor of current HEAD');
  const preservedWorktree = preservedSupersessionWorktree(root, after.porcelain);
  const recovery = {
    protocol: 'phase-140-recovery-v2',
    baselineSha,
    supersedesSha256: previousDigest,
    preservedWorktree,
  };
  const before = committedObservation(root, head);
  const receiptWriter = writer(root);
  const evidence = { protocol: 'gsd-transition-v1', writer: receiptWriter, before, after: after.result, recovery };
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
    recovery,
    transformation: {
      protocol: 'gsd-transition-v1',
      allowedPaths: ALLOWED_PATHS,
      sha256: sha256(compact(evidence)),
    },
  };
  if (!refsUnchanged(root, refsBefore) || !remoteMainUnchanged(root, remoteMain)) {
    fail('refs changed before receipt supersession');
  }
  archiveReceipt(root, previousBytes, previousDigest);
  const currentBytes = fs.readFileSync(target);
  if (sha256(currentBytes) !== expectedDigest) fail('pending receipt changed before compare-and-swap');
  if (!refsUnchanged(root, refsBefore) || !remoteMainUnchanged(root, remoteMain)) {
    fail('refs changed before successor publication');
  }
  const successorDigest = sha256(Buffer.from(`${compact(receipt)}\n`));
  try {
    writeReceipt(root, receipt);
  } catch (_) {
    restorePriorReceipt(root, previousBytes, successorDigest, 'successor publication failed');
  }
  const publishedBytes = fs.readFileSync(target);
  if (sha256(publishedBytes) !== successorDigest) {
    fail(`successor receipt failed compare-and-swap verification; pending receipt state is ${pendingDigest(target)}`);
  }
  if (!refsUnchanged(root, refsBefore) || !remoteMainUnchanged(root, remoteMain)) {
    restorePriorReceipt(root, previousBytes, successorDigest, 'refs changed during receipt supersession');
  }
  fs.rmdirSync(lockPath);
  process.stdout.write(compact({ receipt, supersededSha256: previousDigest }) + '\n');
}

function acceptedPhase139Base(root, requireDurableEvidence = false) {
  const target = path.join(commonDir(root), 'lockspire-phase-139-acceptance-v1.json');
  let receipt;
  try {
    const stat = fs.lstatSync(target);
    if (!stat.isFile() || (stat.mode & 0o777) !== 0o600 || stat.size <= 0 || stat.size > MAX_RECEIPT_BYTES) {
      fail('durable Phase 139 acceptance receipt is unsafe');
    }
    receipt = JSON.parse(fs.readFileSync(target, 'utf8'));
  } catch (_) {
    fail('durable Phase 139 acceptance receipt is unavailable');
  }
  const baselineSha = receipt && receipt.baseline_sha;
  if (receipt.schema !== 'lockspire-phase-139-acceptance-v1' ||
      typeof baselineSha !== 'string' || !/^[0-9a-f]{40}$/.test(baselineSha)) {
    fail('durable Phase 139 acceptance receipt is malformed');
  }
  if (requireDurableEvidence) validateDurableAcceptanceReceipt(receipt);
  return baselineSha;
}

function validateDurableAcceptanceReceipt(receipt) {
  const object = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);
  const exactKeys = (value, keys) => object(value) &&
    compact(Object.keys(value).sort()) === compact([...keys].sort());
  const positive = (value) => Number.isSafeInteger(value) && value > 0;
  const nonnegative = (value) => Number.isSafeInteger(value) && value >= 0;
  const requiredJobs = [
    'Dialyzer', 'Release Hygiene Drift', 'Fast Checks', 'Minimum Supported Elixir/OTP',
    'Integration Checks', 'Complete Coverage Evidence', 'Adoption Demo Smoke',
  ];
  const releaseJobs = {
    'Maintain Release Please PR': 'success',
    'Validate exact main head and CI evidence': 'skipped',
    'Prove exact package before publication': 'skipped',
    'Publish verified release to Hex': 'skipped',
    'Verify public install truth': 'skipped',
  };
  const validRun = (run, expected, outcome) => {
    const keys = ['status', 'run_id', 'event', 'conclusion', 'url', 'jobs'];
    if (outcome) keys.push('outcome');
    if (!exactKeys(run, keys) || run.status !== 'pass' || run.event !== 'push' ||
        run.conclusion !== 'success' || !positive(run.run_id) ||
        typeof run.url !== 'string' || !/^https:\/\/\S+$/.test(run.url) ||
        (outcome && run.outcome !== outcome) || !Array.isArray(run.jobs) ||
        run.jobs.length !== Object.keys(expected).length) return false;
    const jobs = {};
    for (const job of run.jobs) {
      if (!exactKeys(job, ['name', 'status', 'conclusion']) ||
          typeof job.name !== 'string' || Object.hasOwn(jobs, job.name) ||
          job.status !== 'completed') return false;
      jobs[job.name] = job.conclusion;
    }
    return compact(Object.entries(jobs).sort()) === compact(Object.entries(expected).sort());
  };
  const captured = receipt.captured_at;
  const capturedDate = typeof captured === 'string' && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(captured)
    ? new Date(captured) : null;
  const validDispositions = Array.isArray(receipt.warn_dispositions) &&
    receipt.warn_dispositions.length === receipt.hygiene?.warn &&
    receipt.warn_dispositions.every((item) => exactKeys(item, ['label', 'disposition']) &&
      typeof item.label === 'string' && /^[A-Za-z0-9][A-Za-z0-9 ._/-]{0,127}$/.test(item.label) &&
      typeof item.disposition === 'string' && /^[a-z0-9][a-z0-9._-]{0,63}$/.test(item.disposition)) &&
    new Set(receipt.warn_dispositions.map((item) => item.label)).size === receipt.warn_dispositions.length;
  if (!exactKeys(receipt, [
    'schema', 'baseline_sha', 'local_gate', 'hygiene', 'required_ci', 'release_no_publish',
    'warn_dispositions', 'supplemental_oidf', 'inventory_relation', 'historical_release',
    'captured_at', 'repository',
  ]) || !exactKeys(receipt.local_gate, ['status', 'exunit_tests']) ||
      receipt.local_gate.status !== 'pass' || !positive(receipt.local_gate.exunit_tests) ||
      !exactKeys(receipt.hygiene, ['status', 'pass', 'warn', 'block']) ||
      receipt.hygiene.status !== 'pass' || !positive(receipt.hygiene.pass) ||
      !nonnegative(receipt.hygiene.warn) || receipt.hygiene.block !== 0 ||
      !validRun(receipt.required_ci, Object.fromEntries(requiredJobs.map((name) => [name, 'success']))) ||
      !validRun(receipt.release_no_publish, releaseJobs, 'no_publish') ||
      !validDispositions ||
      !exactKeys(receipt.supplemental_oidf, ['classification', 'required_gate']) ||
      receipt.supplemental_oidf.classification !== 'supplemental_non_certifying' ||
      receipt.supplemental_oidf.required_gate !== false ||
      compact(receipt.inventory_relation) !== compact({ status: 'verified' }) ||
      typeof receipt.repository !== 'string' || !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(receipt.repository) ||
      !exactKeys(receipt.historical_release, [
        'source_sha', 'ci_run_id', 'release_run_id', 'version', 'checksum', 'tag', 'status',
      ]) ||
      compact(Object.entries(receipt.historical_release).sort()) !== compact(Object.entries({
        source_sha: '5d10ce2219c2e687cf9573c8b280abfb118a47d8',
        ci_run_id: 33141161205,
        release_run_id: 33141484467,
        version: '1.5.0',
        checksum: '30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de',
        tag: 'lockspire-v1.5.0',
        status: 'verified',
      }).sort()) || !capturedDate || !Number.isFinite(capturedDate.getTime()) ||
      capturedDate.toISOString() !== captured.replace(/Z$/, '.000Z')) {
    fail('durable Phase 139 acceptance receipt evidence is malformed');
  }
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
  const legacyTransition = compact(changed) === compact(['.planning/PROJECT.md', '.planning/STATE.md']);
  let recovery = null;
  if (!legacyTransition) {
    if (phase !== '139') fail('plan-pre preparation requires the exact transition path set');
    const baselineSha = acceptedPhase139Base(root);
    const head = after.result.head;
    if (git(['rev-parse', 'refs/heads/main'], { cwd: root }).trim() !== head) {
      fail('recovery requires current main to be the candidate');
    }
    const ancestor = childProcess.spawnSync('git', ['merge-base', '--is-ancestor', baselineSha, head], {
      cwd: root,
      shell: false,
      stdio: 'ignore',
    });
    if (ancestor.status !== 0) fail('current main does not descend from the accepted Phase 139 SHA');
    recovery = {
      protocol: 'phase-140-recovery-v1',
      baselineSha,
      preservedWorktree: preservedPlanningWorktree(root, after.porcelain),
    };
  }
  const before = committedObservation(root, after.result.head);
  const receiptWriter = writer(root);
  const evidence = {
    protocol: 'gsd-transition-v1',
    writer: receiptWriter,
    before,
    after: after.result,
    ...(recovery ? { recovery } : {}),
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
    ...(recovery ? { recovery } : {}),
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
  const expectedDigest = sha256(fs.readFileSync(receiptPath(root)));
  if (sha256(fs.readFileSync(receiptPath(root))) !== expectedDigest) fail('pending receipt changed before completion');
  fs.unlinkSync(receiptPath(root));
  process.stdout.write(compact({ completed: true, phase }) + '\n');
}

const [command, phase, expectedDigest] = process.argv.slice(2);
const root = projectRoot();
switch (command) {
  case 'status': {
    const receipt = readReceipt(root);
    process.stdout.write(compact(receipt || { exists: false }) + '\n');
    break;
  }
  case 'begin':
    assertPhase(phase);
    acquireReceiptMutationLock(root);
    begin(root, phase);
    break;
  case 'seal':
    assertPhase(phase);
    acquireReceiptMutationLock(root);
    seal(root, phase);
    break;
  case 'prepare':
    assertPhase(phase);
    acquireReceiptMutationLock(root);
    prepare(root, phase);
    break;
  case 'supersede':
    assertPhase(phase);
    supersede(root, phase, expectedDigest);
    break;
  case 'verify-hooks':
    assertPhase(phase);
    verifyHooks(root, phase);
    break;
  case 'complete':
    assertPhase(phase);
    acquireReceiptMutationLock(root);
    complete(root, phase);
    break;
  default:
    fail('expected begin, seal, prepare, supersede, verify-hooks, status, or complete');
}

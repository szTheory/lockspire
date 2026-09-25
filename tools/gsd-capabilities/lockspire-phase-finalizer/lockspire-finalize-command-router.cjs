'use strict';

const childProcess = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

let spawnSync = childProcess.spawnSync;
const supervisor = path.join(__dirname, 'lockspire-finalizer-process-supervisor.cjs');
const timeoutGrace = 1000;

function reject(error, message, code = 2) {
  process.exitCode = code;
  error(`lockspire phase finalizer: ${message}`);
}

function projectRoot(cwd) {
  if (typeof cwd !== 'string' || cwd.length === 0) return null;
  let root;
  try {
    root = fs.realpathSync(cwd);
  } catch (_) {
    return null;
  }
  const files = [
    'scripts/maintainer/finalize_phase_138_inventory.sh',
    'scripts/maintainer/finalize_phase_139_acceptance.sh',
  ];
  const directories = [
    '.planning/phases/138-baseline-inventory-evidence-taxonomy',
    '.planning/phases/139-required-truth-reconciliation',
  ];
  try {
    if (!files.every((entry) => fs.lstatSync(path.join(root, entry)).isFile()) ||
        !directories.every((entry) => fs.lstatSync(path.join(root, entry)).isDirectory())) return null;
  } catch (_) {
    return null;
  }
  return root;
}

function routeLockspireFinalizeCommand({ args, cwd, raw, error }) {
  if (raw !== true) {
    reject(error, 'raw mode is required');
    return;
  }
  if (!Array.isArray(args) || args.length !== 4 || args[0] !== 'lockspire-finalize' ||
      !['pre-verify', 'post-transition'].includes(args[1]) || args[2] !== '--phase' ||
      !/^(0|[1-9][0-9]*)(?:\.[0-9]+)?$/.test(args[3])) {
    reject(error, 'expected lockspire-finalize MODE --phase NUMERIC_PHASE');
    return;
  }
  const root = projectRoot(cwd);
  if (!root) {
    reject(error, 'current directory is not a Lockspire project root');
    return;
  }

  const mode = args[1];
  const phase = args[3];
  const dispatch = {
    '138': {
      'pre-verify': ['scripts/maintainer/finalize_phase_138_inventory.sh', 900000],
      'post-transition': ['scripts/maintainer/finalize_phase_138_inventory.sh', 900000],
    },
    '139': {
      'pre-verify': ['scripts/maintainer/finalize_phase_138_inventory.sh', 900000],
      'post-transition': ['scripts/maintainer/finalize_phase_139_acceptance.sh', 2400000],
    },
  };
  const selected = dispatch[phase] && dispatch[phase][mode];
  if (!selected) {
    error(`lockspire phase finalizer: not applicable to phase ${phase}`);
    return;
  }
  const [child, timeout] = selected;
  const result = spawnSync(
    process.execPath,
    [supervisor, root, child, mode, phase, String(timeout), String(timeoutGrace)],
    {
      cwd: root,
      shell: false,
      stdio: 'inherit',
    },
  );

  if (result && (result.status === 124 || (result.error && result.error.code === 'ETIMEDOUT'))) {
    reject(error, 'child timed out', 124);
    return;
  }
  if (result && (result.status === 125 || result.signal)) {
    reject(error, 'child exited by signal', 125);
    return;
  }
  if (result && (result.status === 126 || result.error)) {
    reject(error, 'child failed to start', 126);
    return;
  }
  if (!result || !Number.isInteger(result.status)) {
    reject(error, 'child returned no exit status', 127);
    return;
  }
  if (result.status !== 0) {
    reject(error, `child exited nonzero (${result.status})`, result.status);
  }
}

function setSpawnSyncForTests(value) {
  if (typeof value !== 'function') throw new TypeError('spawn seam must be a function');
  spawnSync = value;
}

function resetSpawnSyncForTests() {
  spawnSync = childProcess.spawnSync;
}

module.exports = {
  routeLockspireFinalizeCommand,
  setSpawnSyncForTests,
  resetSpawnSyncForTests,
};

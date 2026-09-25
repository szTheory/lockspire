'use strict';

const childProcess = require('node:child_process');

const args = process.argv.slice(2);
if (args.length !== 6) process.exit(126);

const [root, child, mode, phase, timeoutValue, graceValue] = args;
const originalParentPid = process.ppid;
const timeout = Number(timeoutValue);
const grace = Number(graceValue);
if (!Number.isSafeInteger(timeout) || timeout <= 0 ||
    !Number.isSafeInteger(grace) || grace <= 0) process.exit(126);

let finalizer;
let timeoutTimer;
let escalationTimer;
let hardStopTimer;
let finishTimer;
let parentWatchTimer;
let finished = false;
let terminationStatus;

function finish(status) {
  if (finished) return;
  finished = true;
  clearTimeout(timeoutTimer);
  clearTimeout(escalationTimer);
  clearTimeout(hardStopTimer);
  clearTimeout(finishTimer);
  clearInterval(parentWatchTimer);
  process.exitCode = status;
}

function signalGroup(signal) {
  if (!finalizer || !Number.isInteger(finalizer.pid)) return;
  try {
    process.kill(-finalizer.pid, signal);
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
}

function groupMembers() {
  const listed = childProcess.spawnSync('/bin/ps', ['-A', '-o', 'pid=,pgid='], {
    encoding: 'utf8',
    shell: false,
  });
  if (listed.status !== 0 || typeof listed.stdout !== 'string') return [];
  return listed.stdout.split('\n').flatMap((line) => {
    const match = line.trim().match(/^(\d+)\s+(\d+)$/);
    return match && Number(match[2]) === finalizer.pid ? [Number(match[1])] : [];
  });
}

function killResistantDescendants() {
  for (const pid of groupMembers()) {
    if (pid === finalizer.pid) continue;
    try {
      process.kill(pid, 'SIGKILL');
    } catch (error) {
      if (error.code !== 'ESRCH') throw error;
    }
  }
}

function beginTermination(signal, status) {
  if (finished || terminationStatus !== undefined) return;
  terminationStatus = status;
  clearTimeout(timeoutTimer);
  signalGroup(signal);
  escalationTimer = setTimeout(() => {
    killResistantDescendants();
    hardStopTimer = setTimeout(() => signalGroup('SIGKILL'), grace);
  }, grace);
}

try {
  finalizer = childProcess.spawn('bash', [child, mode, '--phase', phase], {
    cwd: root,
    detached: true,
    shell: false,
    stdio: 'inherit',
  });
} catch (_) {
  finish(126);
}

if (!finalizer) return;

finalizer.once('error', () => finish(126));
finalizer.once('exit', (status, signal) => {
  if (terminationStatus !== undefined) {
    signalGroup('SIGKILL');
    finishTimer = setTimeout(() => finish(terminationStatus), 25);
  } else if (Number.isInteger(status)) {
    finish(status);
  } else if (signal) {
    finish(125);
  } else {
    finish(127);
  }
});

for (const [signal, status] of [['SIGHUP', 129], ['SIGINT', 130], ['SIGTERM', 143]]) {
  process.on(signal, () => beginTermination(signal, status));
}

timeoutTimer = setTimeout(() => beginTermination('SIGTERM', 124), timeout);
parentWatchTimer = setInterval(() => {
  try {
    process.kill(originalParentPid, 0);
  } catch (error) {
    if (error.code === 'ESRCH') beginTermination('SIGTERM', 143);
  }
}, 20);

#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const copiedFixture = path.join(__dirname, '..', 'fixtures', 'gsd-host-contract.json');
const sourceFixture = path.join(__dirname, '..', '..', 'gsd-host-contract.json');
const fixturePath = fs.existsSync(copiedFixture) ? copiedFixture : sourceFixture;
const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
const point = process.argv[2] === 'loop' && process.argv[3] === 'render-hooks' ? process.argv[4] : null;

if (!point || !Object.hasOwn(fixture.gates, point)) {
  process.stderr.write('unsupported fixture hook point\n');
  process.exit(2);
}

const expected = fixture.gates[point];
process.stdout.write(JSON.stringify({
  activeHooks: [{
    kind: 'gate',
    capId: 'lockspire-phase-finalizer',
    check: {
      predicate: {
        kind: 'command-exit-zero',
        command: expected.command,
        timeout: expected.timeout,
      },
    },
    blocking: true,
    onError: 'halt',
  }],
}));

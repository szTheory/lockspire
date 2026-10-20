# PR #122 commit override (D-08, D-18)

PR #122 ("Lockspire: release, admin UI, and documentation improvements", merged as `e67a4898db129086f871c0d62f910cfd1bda87a6`) is one squash commit holding v1.39 to v1.41 work. Release Please reads one changelog entry from it. The override below makes it read two `feat(admin)` entries instead.

## Current state of the #122 body

- `gh pr view 122 --json body --jq .body | sha256sum` is `5fc53683228d8767e8faaaa59f88b46195f494fc8869daca64a5e3db627ab0d2` (the hash includes the trailing newline that `--jq` adds).
- `gh pr view 122 --json body --jq .body | grep -c BEGIN_COMMIT_OVERRIDE` prints `0`: no override exists today.

## Block to append (keep the existing summary untouched)

Append a blank line, then exactly the block below. The marker lines stand alone on their lines, and the two entries are separated by one blank line.

BEGIN_COMMIT_OVERRIDE
feat(admin): refine the operator UI across apps, security, keys, consents and tokens (v1.40) (#122)

feat(admin): describe admin pages in task and object language and route adopters through task-grouped guides (v1.41) (#122)
END_COMMIT_OVERRIDE

Both entries are `feat`, so they render in the changelog. The block carries no major-bump marker of any kind.

## Offline proof with the vendored release-please

The script lives in a `mktemp -d` directory outside the repo. It requires the vendored `commit.js` by absolute path, builds one fake commit (sha `e67a4898db129086f871c0d62f910cfd1bda87a6`, message equal to #122's title plus ` (#122)`, `pullRequest.body` equal to the real current body plus the block), and calls `parseConventionalCommits`.

```js
const fs = require('fs');
const [,, dir] = process.argv;
const { parseConventionalCommits } = require('/Users/jon/projects/lockspire/.github/actions/release-please/runtime/node_modules/release-please/build/src/commit.js');
const body = fs.readFileSync(dir + '/body.txt', 'utf8') + fs.readFileSync(dir + '/override.txt', 'utf8');
const title = fs.readFileSync(dir + '/title.txt', 'utf8').trim();
const out = parseConventionalCommits([{ sha: 'e67a4898db129086f871c0d62f910cfd1bda87a6', message: title + ' (#122)', files: [], pullRequest: { body, number: 122, title, headBranchName: 'x', baseBranchName: 'main', labels: [], files: [] } }]);
console.log('parsed commits: ' + out.length);
for (const c of out) console.log(JSON.stringify({ sha: c.sha, type: c.type, scope: c.scope, subject: c.bareMessage, breaking: c.breaking }));
```

`body.txt` and `title.txt` come from `gh pr view 122 --json body --jq .body` and `--json title --jq .title`. `override.txt` is a blank line followed by the block above.

Output:

```
parsed commits: 2
{"sha":"e67a4898db129086f871c0d62f910cfd1bda87a6","type":"feat","scope":"admin","subject":"refine the operator UI across apps, security, keys, consents and tokens (v1.40) (#122)","breaking":false}
{"sha":"e67a4898db129086f871c0d62f910cfd1bda87a6","type":"feat","scope":"admin","subject":"describe admin pages in task and object language and route adopters through task-grouped guides (v1.41) (#122)","breaking":false}
```

Exactly two commits, both `feat`, scope `admin`, neither flagged as a major bump. No file was created inside the repo by this proof.

## Trigger order (D-18)

1. Edit PR #122's body (append the block) before squash-merging the v1.44 PR.
2. Squash-merge the v1.44 PR; Release Please then reads the #122 body when it walks the range.
3. Never re-run the Release workflow to pick the edit up.

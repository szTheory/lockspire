import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const source = readFileSync(new URL("../../lib/lockspire/web/admin_controls.ex", import.meta.url), "utf8");
const script = source.match(/@javascript ~S"""\n([\s\S]*?)\n  """/)[1];
const context = { module: { exports: {} } };
vm.runInNewContext(script, context);
const { parseValues, addValues, acknowledgePending, valueEntryPlaceholder } = context.module.exports;
const values = text => Array.from(parseValues(text));

test("pasted lists trim blanks and deduplicate without changing case or order", () => {
  assert.deepEqual(values(" openid, ,profile,openid\nEmail\r\nemail, "), ["openid", "profile", "Email", "email"]);
});

test("adding a list preserves existing values and only adds exact new values", () => {
  assert.deepEqual(Array.from(addValues(["custom:read", "openid"], "openid, profile, custom:read")), ["custom:read", "openid", "profile"]);
});

test("cleared lists remain empty and custom values are never replaced by suggestions", () => {
  assert.deepEqual(values(" ,\n "), []);
  assert.deepEqual(values("custom.scope, urn:example:scope, apps.example.test"), ["custom.scope", "urn:example:scope", "apps.example.test"]);
});

test("spaces inside tokens and markup stay literal for existing server validation", () => {
  assert.deepEqual(values('invalid scope, <img src=x onerror=alert(1)>'), ["invalid scope", "<img src=x onerror=alert(1)>"]);
});

test("request acknowledgements preserve newer edits even when values repeat", () => {
  // B → C → B has distinct edits even though the first and last values match.
  assert.deepEqual(Array.from(acknowledgePending([1, 2, 3], 1)), [2, 3]);
  assert.deepEqual(Array.from(acknowledgePending([2, 3], 2)), [3]);
  assert.deepEqual(Array.from(acknowledgePending([3], 3)), []);
  // A coalesced response can acknowledge every edit it actually contains.
  assert.deepEqual(Array.from(acknowledgePending([1, 2], 2)), []);
});

test("exhausting suggestions leaves an honest hint for open-ended values", () => {
  assert.equal(valueEntryPlaceholder([], ["openid", "profile"]), "Add a value…");
  assert.equal(valueEntryPlaceholder(["openid"], ["openid", "profile"]), "Add another…");
  assert.equal(valueEntryPlaceholder(["openid", "profile"], ["openid", "profile"]), "Add a custom value…");
  assert.equal(valueEntryPlaceholder(["custom:read"], []), "Add another…");
});

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const layoutPath = new URL("../../lib/lockspire/web/live/admin_layout_live.ex", import.meta.url);

test("theme storage failures keep the current-page choice and announce the outcome", async () => {
  const source = await readFile(layoutPath, "utf8");

  assert.ok(/let currentPageTheme = "system"/.test(source), "page theme state is independent of the saved preference");
  assert.ok(/role="status"/.test(source), "storage outcomes use a status region");
  assert.ok(/aria-live="polite"/.test(source), "the status region is announced accessibly");
  assert.ok(/Your saved theme preference could not be read\./.test(source), "read failure is explained");
  assert.ok(/Your theme is applied for this page, but the saved preference was not updated\./.test(source), "save failure is explained");
  assert.ok(/Your theme is applied for this page, but the saved preference was not cleared\./.test(source), "remove failure is explained");
  assert.ok(!/\$\{_error\.message\}/.test(source), "browser exception details are not rendered");
});

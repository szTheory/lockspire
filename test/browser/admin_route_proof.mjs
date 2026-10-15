// Local-only admin route proof harness.
//
// Drives the globally installed `agent-browser` CLI against the synthetic
// review demo, signs in as the synthetic `ops` account, observes one admin path
// at a chosen width / theme / motion setting, scans the rendered DOM for
// sensitive values, optionally saves screenshots under a git-ignored tmp/ path,
// and prints BrowserEvidence-shaped markdown rows.
//
// This script is intentionally NOT wired into CI (D-05): it needs a running
// demo container and a globally installed browser CLI. Its pure helpers are
// covered by admin_route_proof_test.mjs, which is also run locally only, because
// a CI step would test code that CI never executes.
//
// Safety rules: the only form ever submitted is the synthetic login form. No
// control is clicked, and the keyboard sweep sends Tab and Escape only.

import { execFileSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

export const DEFAULT_BASE_URL = "http://lockspire-ui-review.localhost/lockspire";
export const DEFAULT_OUT = "tmp/admin-ui-polish/v1.42/final";
export const THEME_STORAGE_KEY = "lockspire-admin-theme";

export const DEFAULT_WIDTHS = [320, 390, 640, 768, 1119, 1120, 1280];
export const DEFAULT_THEMES = ["light", "dark", "system"];

const ROUTE_TEMPLATES = [
  "/admin",
  "/admin/clients",
  "/admin/clients/:client_id",
  "/admin/clients/:client_id/edit",
  "/admin/clients/:client_id/edit?workflow=logout-propagation",
  "/admin/clients/:client_id/logout-uris",
  "/admin/clients/:client_id/par-policy",
  "/admin/clients/:client_id/redirects",
  "/admin/clients/:client_id/rotate-registration-access-token",
  "/admin/clients/:client_id/rotate-secret",
  "/admin/clients/:client_id/security-profile",
  "/admin/clients/new",
  "/admin/consents",
  "/admin/consents/:id",
  "/admin/dcr",
  "/admin/device_authorizations",
  "/admin/iats",
  "/admin/iats/new",
  "/admin/interactions",
  "/admin/keys",
  "/admin/keys/:id",
  "/admin/logouts",
  "/admin/overview",
  "/admin/policies",
  "/admin/policies/dcr",
  "/admin/policies/dpop",
  "/admin/policies/par",
  "/admin/policies/security-profile",
  "/admin/tokens",
  "/admin/tokens/:id"
];

export const CHANGED_PAGES = [
  "/admin/clients",
  "/admin/clients/new",
  "/admin/clients/:client_id",
  "/admin/clients/:client_id/edit",
  "/admin/overview",
  "/admin/interactions",
  "/admin/device_authorizations",
  "/admin/logouts",
  "/admin/policies",
  "/admin/keys",
  "/admin/consents",
  "/admin/tokens"
];

const SYNTHETIC_CLIENT = "billingo-reports-backend";
const REGISTRATION_TOKEN_CLIENT = "northstar-payables-portal";

// Mirrors Lockspire.Web.AdminProof.BrowserEvidence sensitive_patterns/0.
export const SENSITIVE_PATTERNS = [
  ["cookie", /\b(?:cookie|session|session_id)=["']?[A-Za-z0-9._~+%/=-]{12,}/i],
  ["auth code", /\b(?:authorization_code|auth_code)=["']?[A-Za-z0-9._~+%/=-]{12,}/i],
  [
    "JWT-looking token",
    /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]{8,})?\b/
  ],
  [
    "token parameter",
    /(?:^|[?&\s])(?:access_token|refresh_token|id_token)=["']?[A-Za-z0-9._~+%/=-]{8,}/i
  ],
  [
    "plaintext credential",
    /\b(?:client_secret|password|plaintext[_ -]?password)=["']?[A-Za-z0-9._~+%/=-]{8,}/i
  ],
  ["private key", /-----BEGIN [A-Z ]*PRIVATE KEY-----/],
  [
    "authorization credential",
    /\b(?:proxy-)?authorization\s*:\s*(?:bearer|basic)\s+\S{8,}/i
  ],
  ["verifier material", /\b(?:code_verifier|verifier_material)=["']?[A-Za-z0-9._~+%/=-]{8,}/i],
  ["device or user code", /\b(?:device_code|user_code)=["']?[A-Za-z0-9._~+%/=-]{4,}/i],
  [
    "copy-once secret",
    /(?:copy[- ]once\s+(?:secret|plaintext|value|credential)|(?:secret|credential).{0,24}copy[- ]once)/i
  ],
  [
    "production-looking hostname",
    /\b(?:https?:\/\/)?(?:[a-z0-9-]+\.)+(?:com|net|org|io|dev|app|cloud)(?::\d+)?(?:\/|\b)/i
  ]
];

const JOURNEYS = [
  ["/admin/overview", "Orient"],
  ["/admin/interactions", "Support"],
  ["/admin/device_authorizations", "Support"],
  ["/admin/logouts", "Support"],
  ["/admin/consents", "Operate"],
  ["/admin/tokens", "Operate"],
  ["/admin/keys", "Operate"],
  ["/admin/clients", "Configure"],
  ["/admin/policies", "Configure"],
  ["/admin/dcr", "Configure"],
  ["/admin/iats", "Configure"]
];

// ---------------------------------------------------------------- pure helpers

export function routeTemplates() {
  return [...ROUTE_TEMPLATES].sort();
}

export function concretePath(template) {
  if (template === "/admin/clients/:client_id/rotate-registration-access-token") {
    return template.replace(":client_id", REGISTRATION_TOKEN_CLIENT);
  }
  return template
    .replace(":client_id", SYNTHETIC_CLIENT)
    .replace("/admin/keys/:id", "/admin/keys/1")
    .replace("/admin/consents/:id", "/admin/consents/1")
    .replace("/admin/tokens/:id", "/admin/tokens/3");
}

export function journeyFor(template) {
  if (template === "/admin") return "Orient";
  const hit = JOURNEYS.find(([prefix]) => template === prefix || template.startsWith(`${prefix}/`));
  return hit ? hit[1] : "Configure";
}

export function buildMatrix({
  widths = DEFAULT_WIDTHS,
  themes = DEFAULT_THEMES,
  motions = ["default"],
  routes = routeTemplates()
} = {}) {
  const seen = new Set();
  const entries = [];
  for (const route of routes) {
    for (const width of widths) {
      for (const theme of themes) {
        for (const motion of motions) {
          const key = `${route}|${width}|${theme}|${motion}`;
          if (seen.has(key)) continue;
          seen.add(key);
          entries.push({ route, width, theme, motion });
        }
      }
    }
  }
  return entries;
}

export function matrixSize() {
  return routeTemplates().length * DEFAULT_WIDTHS.length * DEFAULT_THEMES.length;
}

export function collectScanText({ innerText = "", fieldValues = [], dataAttributes = [] } = {}) {
  const parts = [innerText];
  for (const field of fieldValues) {
    if (typeof field === "string") {
      parts.push(field);
    } else if (field) {
      for (const key of ["value", "attr", "optionText"]) {
        if (typeof field[key] === "string" && field[key] !== "") parts.push(field[key]);
      }
    }
  }
  for (const attribute of dataAttributes) {
    if (typeof attribute === "string") {
      parts.push(attribute);
    } else if (attribute && typeof attribute.value === "string" && attribute.value !== "") {
      parts.push(attribute.value);
    }
  }
  return parts.join("\n");
}

export function scanSensitive(text) {
  const hits = [];
  for (const [label, pattern] of SENSITIVE_PATTERNS) {
    if (pattern.test(text)) hits.push(label);
  }
  return hits;
}

function cell(value) {
  return String(value).replace(/\|/g, "/").replace(/\s+/g, " ").trim();
}

export const EVIDENCE_HEADER =
  "| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |\n" +
  "|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|";

export function formatEvidenceRow({
  route,
  journey,
  width,
  theme,
  motion = "default",
  focusPath = "page load",
  state = "synthetic default data",
  scrollWidth,
  clientWidth,
  result,
  notes = "synthetic local observation",
  sensitiveCheck = "passed denylist",
  gapNote = "none",
  outcome = "local route proof capture"
}) {
  const finalResult = result || (scrollWidth > clientWidth ? "fail" : "pass");
  const cells = [
    `\`${route}\``,
    journey,
    `${width}px`,
    theme,
    motion,
    focusPath,
    state,
    scrollWidth,
    clientWidth,
    finalResult,
    notes,
    sensitiveCheck,
    gapNote,
    outcome
  ].map(cell);
  return `| ${cells.join(" | ")} |`;
}

export function sectionPlan(pageHeight, viewportHeight, headings) {
  if (!headings || headings.length === 0) {
    const slices = [];
    for (let y = 0; y < pageHeight; y += viewportHeight) {
      slices.push({ heading: null, scrollY: y, height: viewportHeight });
    }
    return slices;
  }
  return headings.map((heading) => ({
    heading: heading.text,
    scrollY: Math.max(0, Math.round(heading.top - 16)),
    height: viewportHeight
  }));
}

export function routeSlug(template) {
  return template.replace(/^\//, "").replace(/[^A-Za-z0-9_]+/g, "-").replace(/-+$/g, "") || "admin";
}

// --------------------------------------------------------------- browser layer

const SWEEP_SCRIPT = `(() => {
  const root = document.documentElement;
  const describe = (el) => el.tagName.toLowerCase() + (el.className && typeof el.className === "string" ? "." + el.className.trim().split(/\\s+/).slice(0, 2).join(".") : "");
  const visible = (el) => {
    const r = el.getBoundingClientRect();
    const s = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && s.visibility !== "hidden" && s.display !== "none";
  };
  const scrollerAllowed = (el) => {
    for (let n = el; n && n !== document.body; n = n.parentElement) {
      if (n.matches(".lockspire-admin-secondary-nav, .lockspire-admin-table-wrap")) return true;
      const ox = getComputedStyle(n).overflowX;
      if (ox === "auto" || ox === "scroll") return true;
    }
    return false;
  };
  const clipped = [];
  for (const el of document.body.querySelectorAll("*")) {
    if (clipped.length >= 10) break;
    if (el.clientWidth === 0 || el.scrollWidth <= el.clientWidth + 1) continue;
    const ox = getComputedStyle(el).overflowX;
    if (ox !== "hidden" && ox !== "clip") continue;
    if (scrollerAllowed(el)) continue;
    clipped.push(describe(el));
  }
  const unlabeled = [];
  for (const el of document.querySelectorAll("input, select, textarea")) {
    if (el.type === "hidden" || el.type === "submit" || el.type === "button" || el.type === "reset") continue;
    if (!visible(el)) continue;
    const labelled = (el.labels && el.labels.length > 0) || el.getAttribute("aria-label") || el.getAttribute("aria-labelledby");
    if (!labelled) unlabeled.push(describe(el) + (el.name ? "[" + el.name + "]" : ""));
  }
  const small = [];
  for (const el of document.querySelectorAll("a[href], button, input, select, textarea, summary, [role=button]")) {
    if (el.type === "hidden" || !visible(el)) continue;
    const r = el.getBoundingClientRect();
    if (r.width < 24 || r.height < 24) {
      small.push(describe(el) + " " + Math.round(r.width) + "x" + Math.round(r.height));
    }
  }
  const fieldValues = [];
  for (const el of document.querySelectorAll("input, textarea, select")) {
    const entry = { value: el.value == null ? "" : String(el.value), attr: el.getAttribute("value") || "" };
    if (el.tagName === "SELECT" && el.selectedOptions && el.selectedOptions[0]) {
      entry.optionText = el.selectedOptions[0].textContent || "";
    }
    fieldValues.push(entry);
  }
  const dataAttributes = [];
  for (const el of document.querySelectorAll("*")) {
    for (const attr of el.attributes) {
      if (attr.name.startsWith("data-")) dataAttributes.push({ name: attr.name, value: attr.value });
    }
  }
  const themeEls = Array.from(document.querySelectorAll("[data-theme]")).map((el) => el.getAttribute("data-theme"));
  const select = document.querySelector("[data-lockspire-theme-select]");
  const headings = Array.from(document.querySelectorAll("main h2, h2")).map((h) => ({
    text: (h.textContent || "").trim().slice(0, 80),
    top: h.getBoundingClientRect().top + window.scrollY
  }));
  return JSON.stringify({
    pathname: location.pathname,
    scrollWidth: root.scrollWidth,
    clientWidth: root.clientWidth,
    pageHeight: root.scrollHeight,
    h1Count: document.querySelectorAll("h1").length,
    title: document.title,
    clipped,
    unlabeled,
    small,
    innerText: document.body.innerText,
    fieldValues,
    dataAttributes,
    dataThemeValues: themeEls,
    themeSelectValue: select ? select.value : null,
    headings
  });
})()`;

const FOCUS_SCRIPT = `(() => {
  const el = document.activeElement;
  if (!el || el === document.body) return JSON.stringify({ tag: "body" });
  const cs = getComputedStyle(el);
  const r = el.getBoundingClientRect();
  const name = el.getAttribute("aria-label") || (el.labels && el.labels[0] && el.labels[0].textContent) || el.textContent || el.getAttribute("title") || "";
  return JSON.stringify({
    tag: el.tagName.toLowerCase(),
    name: name.trim().replace(/\\s+/g, " ").slice(0, 60),
    outlineWidth: cs.outlineWidth,
    outlineStyle: cs.outlineStyle,
    boxShadow: cs.boxShadow,
    inViewport: r.top >= 0 && r.left >= 0 && r.bottom <= window.innerHeight && r.right <= window.innerWidth
  });
})()`;

const DISCLOSURE_SCRIPT = `JSON.stringify({ open: document.querySelectorAll("details[open], [aria-expanded='true']").length })`;

function baseUrl() {
  return (process.env.LOCKSPIRE_PROOF_BASE_URL || DEFAULT_BASE_URL).replace(/\/+$/, "");
}

function browser(session, ...args) {
  return execFileSync("agent-browser", ["--session", session, ...args], {
    cwd: repoRoot,
    encoding: "utf8",
    timeout: 60_000,
    maxBuffer: 16 * 1024 * 1024
  }).trim();
}

function browserJson(session, script) {
  const first = JSON.parse(browser(session, "eval", script));
  return typeof first === "string" ? JSON.parse(first) : first;
}

function ensureOpsSession(session, url) {
  browser(session, "open", url);
  let current = new URL(browser(session, "get", "url"));
  if (current.pathname.endsWith("/login")) {
    // The synthetic login form is the only form this script ever submits.
    browser(
      session,
      "eval",
      'document.querySelector("#login").value = "ops"; document.querySelector("form").requestSubmit(); "submitted"'
    );
    browser(session, "wait", "2000");
    browser(session, "open", url);
    current = new URL(browser(session, "get", "url"));
    if (current.pathname.endsWith("/login")) {
      throw new Error("synthetic ops sign-in did not leave the login page");
    }
  }
}

function mediaScheme(theme, mediaOption) {
  return theme === "dark" ? "dark" : theme === "light" ? "light" : mediaOption || "light";
}

function applyEnvironment(session, { width, height, theme, motion, media }) {
  browser(session, "set", "viewport", String(width), String(height));
  const scheme = mediaScheme(theme, media);
  if (motion === "reduced-motion") {
    browser(session, "set", "media", scheme, "reduced-motion");
  } else {
    browser(session, "set", "media", scheme);
  }
}

function applyTheme(session, theme) {
  const script =
    theme === "system"
      ? `localStorage.removeItem(${JSON.stringify(THEME_STORAGE_KEY)}); "system"`
      : `localStorage.setItem(${JSON.stringify(THEME_STORAGE_KEY)}, ${JSON.stringify(theme)}); ${JSON.stringify(theme)}`;
  browser(session, "eval", script);
  browser(session, "reload");
  browser(session, "wait", "500");
}

function pad(value) {
  return String(value);
}

function fileStem(template, entry) {
  return `${routeSlug(template)}-${pad(entry.width)}-${entry.theme}-${entry.motion}`;
}

function keyboardSweep(session) {
  const stops = [];
  for (let i = 0; i < 40; i += 1) {
    browser(session, "press", "Tab");
    const stop = browserJson(session, FOCUS_SCRIPT);
    if (stop.tag === "body") break;
    stops.push(stop);
  }
  const before = browserJson(session, DISCLOSURE_SCRIPT).open;
  browser(session, "press", "Escape");
  const after = browserJson(session, DISCLOSURE_SCRIPT).open;
  const indicated = stops.filter(
    (s) => (s.outlineStyle !== "none" && parseFloat(s.outlineWidth) > 0) || (s.boxShadow && s.boxShadow !== "none")
  ).length;
  const offscreen = stops.filter((s) => !s.inViewport).length;
  return { stops, indicated, offscreen, disclosuresBefore: before, disclosuresAfter: after };
}

function observe(session, template, entry, options) {
  const concrete = concretePath(template);
  const url = `${baseUrl()}${concrete}`;
  browser(session, "open", url);
  const sweep = browserJson(session, SWEEP_SCRIPT);

  const scanText = collectScanText(sweep);
  const hits = scanSensitive(scanText);
  if (hits.length > 0) {
    const error = new Error(`sensitive evidence ${hits.join(", ")} detected on ${template}; screenshot skipped`);
    error.sensitive = true;
    throw error;
  }

  const expectedPath = new URL(url).pathname;
  const loaded = sweep.pathname === expectedPath;
  const notes = [`h1=${sweep.h1Count}`, `clipped=${sweep.clipped.length}`, `unlabeled=${sweep.unlabeled.length}`, `small-targets=${sweep.small.length}`];

  let focusPath = "page load";
  let keyboard = null;
  if (options.keyboard) {
    keyboard = keyboardSweep(session);
    focusPath = `tab x${keyboard.stops.length}; indicator ${keyboard.indicated}/${keyboard.stops.length}; offscreen ${keyboard.offscreen}`;
  }

  const gaps = [];
  if (!loaded) gaps.push(`landed on ${sweep.pathname}`);
  if (sweep.scrollWidth > sweep.clientWidth) gaps.push("document overflow");
  if (sweep.clipped.length) gaps.push(`clipped: ${sweep.clipped.slice(0, 3).join(", ")}`);
  if (sweep.unlabeled.length) gaps.push(`unlabeled: ${sweep.unlabeled.slice(0, 3).join(", ")}`);
  if (sweep.h1Count !== 1) gaps.push(`h1 count ${sweep.h1Count}`);

  let result = "pass";
  if (!loaded) result = "blocked";
  else if (sweep.scrollWidth > sweep.clientWidth || sweep.clipped.length || sweep.unlabeled.length) result = "fail";

  const shots = [];
  if (options.screenshot) {
    const dir = path.join(options.out, "screenshots");
    mkdirSync(dir, { recursive: true });
    const stem = fileStem(template, entry);
    const full = path.join(dir, `${stem}.png`);
    browser(session, "screenshot", "--full", full);
    shots.push(full);
    if (options.sections || sweep.pageHeight > 4000) {
      const slices = sectionPlan(sweep.pageHeight, options.height, sweep.headings);
      slices.forEach((slice, index) => {
        browser(session, "eval", `window.scrollTo(0, ${slice.scrollY}); "scrolled"`);
        const file = path.join(dir, `${stem}-section-${index + 1}.png`);
        browser(session, "screenshot", file);
        shots.push(file);
      });
      browser(session, "eval", 'window.scrollTo(0, 0); "top"');
    }
  }

  const row = formatEvidenceRow({
    route: template,
    journey: journeyFor(template),
    width: entry.width,
    theme: entry.theme,
    motion: entry.motion,
    focusPath,
    scrollWidth: sweep.scrollWidth,
    clientWidth: sweep.clientWidth,
    result,
    notes: notes.join("; "),
    gapNote: gaps.length ? gaps.join("; ") : "none"
  });

  return {
    row,
    observation: {
      route: template,
      concretePath: concrete,
      entry,
      title: sweep.title,
      pathname: sweep.pathname,
      scrollWidth: sweep.scrollWidth,
      clientWidth: sweep.clientWidth,
      pageHeight: sweep.pageHeight,
      h1Count: sweep.h1Count,
      clipped: sweep.clipped,
      unlabeled: sweep.unlabeled,
      small: sweep.small,
      dataThemeValues: sweep.dataThemeValues,
      themeSelectValue: sweep.themeSelectValue,
      keyboard,
      screenshots: shots,
      result
    }
  };
}

// ------------------------------------------------------------------------- CLI

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;
    const key = token.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith("--")) {
      args[key] = true;
    } else {
      args[key] = next;
      i += 1;
    }
  }
  return args;
}

function csv(value, fallback) {
  return value && value !== true ? String(value).split(",").map((v) => v.trim()).filter(Boolean) : fallback;
}

function main(argv) {
  const args = parseArgs(argv);

  if (args["list-templates"]) {
    console.log(routeTemplates().join("\n"));
    return 0;
  }
  if (args["list-changed"]) {
    console.log(CHANGED_PAGES.join("\n"));
    return 0;
  }
  if (args["matrix-size"]) {
    console.log(String(matrixSize()));
    return 0;
  }

  const out = path.resolve(repoRoot, args.out && args.out !== true ? args.out : DEFAULT_OUT);
  const height = Number(args.height || 900);
  const media = args.media && args.media !== true ? args.media : "light";
  const motionArg = args.motion && args.motion !== true ? args.motion : "default";
  const options = {
    out,
    height,
    media,
    screenshot: Boolean(args.screenshot),
    sections: Boolean(args.sections),
    keyboard: Boolean(args.keyboard)
  };
  mkdirSync(out, { recursive: true });

  let entries;
  if (args.matrix) {
    const motions = motionArg === "all" ? ["default", "reduced-motion"] : [motionArg];
    entries = buildMatrix({
      widths: csv(args.width, DEFAULT_WIDTHS).map(Number),
      themes: csv(args.theme, DEFAULT_THEMES),
      motions,
      routes: args.changed ? CHANGED_PAGES : args.route && args.route !== true ? csv(args.route, []) : routeTemplates()
    });
  } else {
    const route = args.route && args.route !== true ? args.route : null;
    if (!route) {
      console.error("usage: admin_route_proof.mjs --route <template-or-path> [--width N] [--theme light|dark|system] [--motion default|reduced-motion] [--keyboard] [--screenshot] [--sections] [--out DIR]");
      return 2;
    }
    entries = [
      {
        route,
        width: Number(args.width || 390),
        theme: args.theme && args.theme !== true ? args.theme : "light",
        motion: motionArg
      }
    ];
  }

  // One fresh session per theme so storage state never leaks between themes.
  const byTheme = new Map();
  for (const entry of entries) {
    if (!byTheme.has(entry.theme)) byTheme.set(entry.theme, []);
    byTheme.get(entry.theme).push(entry);
  }

  const rows = [];
  const observations = [];
  let exitCode = 0;

  for (const [theme, themeEntries] of byTheme) {
    const session = `lockspire-route-proof-${process.pid}-${theme}`;
    try {
      const first = themeEntries[0];
      applyEnvironment(session, { ...first, height, media });
      ensureOpsSession(session, `${baseUrl()}/admin/overview`);
      applyTheme(session, theme);
      let lastEnv = null;
      for (const entry of themeEntries) {
        const envKey = `${entry.width}|${entry.motion}`;
        if (envKey !== lastEnv) {
          applyEnvironment(session, { ...entry, height, media });
          lastEnv = envKey;
        }
        try {
          const { row, observation } = observe(session, entry.route, entry, options);
          rows.push(row);
          observations.push(observation);
          console.log(row);
        } catch (error) {
          console.error(`FAILED ${entry.route} ${entry.width}px ${entry.theme}: ${error.message}`);
          exitCode = 1;
          if (error.sensitive) continue;
        }
      }
    } catch (error) {
      console.error(`FAILED session ${theme}: ${error.message}`);
      exitCode = 1;
    } finally {
      try {
        // Restore system preference so no stored override survives the run.
        if (theme !== "system") browser(session, "eval", `localStorage.removeItem(${JSON.stringify(THEME_STORAGE_KEY)}); "restored"`);
      } catch {
        // best effort
      }
      try {
        browser(session, "close");
      } catch {
        // best effort
      }
    }
  }

  if (args.matrix && rows.length > 0) {
    writeFileSync(path.join(out, "matrix-rows.md"), `${EVIDENCE_HEADER}\n${rows.join("\n")}\n`);
    writeFileSync(path.join(out, "matrix-observations.json"), `${JSON.stringify(observations, null, 2)}\n`);
  } else if (observations.length > 0) {
    mkdirSync(path.join(out, "observations"), { recursive: true });
    for (const observation of observations) {
      writeFileSync(
        path.join(out, "observations", `${fileStem(observation.route, observation.entry)}.json`),
        `${JSON.stringify(observation, null, 2)}\n`
      );
    }
  }

  return exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  process.exit(main(process.argv.slice(2)));
}

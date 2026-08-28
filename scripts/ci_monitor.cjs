#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const pollSeconds = 15;
const maxBuffer = 64 * 1024 * 1024;

function usage() {
  return `GitHub Actions monitor

Usage:
  node scripts/ci_monitor.cjs auth-status
  node scripts/ci_monitor.cjs runs [--workflow <file-or-name>] [--branch <branch>] [--event <event>]
  node scripts/ci_monitor.cjs dispatch <workflow> [--ref <branch>] [--field <key=value> ...]
  node scripts/ci_monitor.cjs watch <run-id> [--interval <seconds>]
  node scripts/ci_monitor.cjs fail-fast <run-id> [--interval <seconds>]
  node scripts/ci_monitor.cjs log-failed <run-id> [--lines <count>]
  node scripts/ci_monitor.cjs job-log <run-id> <job-name> [--lines <count>]
  node scripts/ci_monitor.cjs test-summary <run-id>
  node scripts/ci_monitor.cjs grep <run-id> --pattern <regex> [--context <lines>]
  node scripts/ci_monitor.cjs wait-for <run-id> <job> --keyword <text> [--timeout <seconds>]
  node scripts/ci_monitor.cjs download <run-id> --name <artifact> --dir <directory>
  node scripts/ci_monitor.cjs check-actions [workflow-file]
  node scripts/ci_monitor.cjs dependency-graph <status|enable>
  node scripts/ci_monitor.cjs pr-create --head <branch> --title <title> --body <body> [--base <branch>]
  node scripts/ci_monitor.cjs pr-view [number]
  node scripts/ci_monitor.cjs pr-checks <number>
  node scripts/ci_monitor.cjs pr-merge <number> [--method <merge|squash|rebase>]

Common options:
  --repo <owner/repo>  Override the repository inferred by gh.
  --help               Show this help.
`;
}

function parseArgs(argv) {
  const parsed = { command: argv[0], positional: [], options: {}, fields: [] };

  for (let index = 1; index < argv.length; index += 1) {
    const argument = argv[index];
    if (!argument.startsWith("--")) {
      parsed.positional.push(argument);
      continue;
    }

    const key = argument.slice(2);
    if (key === "help") {
      parsed.options.help = true;
      continue;
    }

    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`Missing value for ${argument}`);
    }
    index += 1;

    if (key === "field") parsed.fields.push(value);
    else parsed.options[key] = value;
  }

  return parsed;
}

function runGh(args, { allowFailure = false, json = false } = {}) {
  const result = spawnSync(process.env.CI_MONITOR_GH_BIN || "gh", args, {
    encoding: "utf8",
    maxBuffer,
  });

  if (result.error) throw new Error(`Unable to execute gh: ${result.error.message}`);
  if (result.status !== 0 && !allowFailure) {
    throw new Error((result.stderr || result.stdout || `gh exited ${result.status}`).trim());
  }

  if (!json) return { status: result.status, stdout: result.stdout, stderr: result.stderr };

  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new Error(`gh returned invalid JSON: ${error.message}`);
  }
}

function repoArgs(options) {
  return options.repo ? ["--repo", options.repo] : [];
}

function runView(runId, options) {
  return runGh(
    [
      "run",
      "view",
      String(runId),
      ...repoArgs(options),
      "--json",
      "databaseId,workflowName,headSha,headBranch,event,status,conclusion,url,jobs,createdAt,updatedAt",
    ],
    { json: true },
  );
}

function statusMark(status, conclusion) {
  if (status !== "completed") return "RUN";
  if (conclusion === "success") return "PASS";
  if (conclusion === "skipped") return "SKIP";
  return "FAIL";
}

function printRun(run) {
  console.log(
    `${statusMark(run.status, run.conclusion)} ${run.databaseId} ${run.workflowName} ` +
      `${run.headBranch || "-"} ${run.event || "-"} ${run.status}/${run.conclusion || "-"} ${run.url || ""}`,
  );
}

function listRuns(options) {
  const args = [
    "run",
    "list",
    ...repoArgs(options),
    "--limit",
    options.limit || "20",
    "--json",
    "databaseId,workflowName,headSha,headBranch,event,status,conclusion,url,createdAt",
  ];
  if (options.workflow) args.push("--workflow", options.workflow);
  if (options.branch) args.push("--branch", options.branch);
  if (options.event) args.push("--event", options.event);

  runGh(args, { json: true }).forEach(printRun);
}

function dispatch(workflow, fields, options) {
  if (!workflow) throw new Error("dispatch requires a workflow file or name");
  const args = ["workflow", "run", workflow, ...repoArgs(options), "--ref", options.ref || "main"];
  fields.forEach((field) => args.push("--field", field));
  runGh(args);
  console.log(`DISPATCHED ${workflow} ref=${options.ref || "main"}`);
}

async function watch(runId, options, failFast) {
  if (!runId) throw new Error("watch requires a run id");
  const interval = Number(options.interval || pollSeconds) * 1000;
  const previous = new Map();

  for (;;) {
    const run = runView(runId, options);
    const runState = `${run.status}/${run.conclusion || "-"}`;
    if (previous.get("run") !== runState) {
      printRun(run);
      previous.set("run", runState);
    }

    for (const job of run.jobs || []) {
      const state = `${job.status}/${job.conclusion || "-"}`;
      if (previous.get(job.databaseId) !== state) {
        console.log(`${statusMark(job.status, job.conclusion)} ${job.name} ${state}`);
        previous.set(job.databaseId, state);
      }
      if (failFast && job.conclusion === "failure") process.exitCode = 1;
    }

    if (process.exitCode === 1 || run.status === "completed") {
      if (run.conclusion !== "success") process.exitCode = 1;
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, interval));
  }
}

function failedLogs(runId, options) {
  const result = runGh([
    "run",
    "view",
    String(runId),
    ...repoArgs(options),
    "--log-failed",
  ]);
  const lines = result.stdout.split(/\r?\n/);
  console.log(lines.slice(-Number(options.lines || 250)).join("\n"));
}

function jobLog(runId, jobName, options) {
  if (!runId || !jobName) throw new Error("job-log requires a run id and job name");
  const run = runView(runId, options);
  const job = (run.jobs || []).find((candidate) => candidate.name === jobName);
  if (!job) throw new Error(`Job not found: ${jobName}`);
  const result = runGh([
    "run",
    "view",
    String(runId),
    ...repoArgs(options),
    "--log",
    "--job",
    String(job.databaseId),
  ]);
  const lines = result.stdout.split(/\r?\n/);
  console.log(lines.slice(-Number(options.lines || 250)).join("\n"));
}

function fullLogs(runId, options) {
  return runGh([
    "run",
    "view",
    String(runId),
    ...repoArgs(options),
    "--log",
  ]).stdout;
}

function testSummary(runId, options) {
  const matches = fullLogs(runId, options).match(/\b\d+ tests?, \d+ failures?(?:, \d+ skipped)?/g) || [];
  if (matches.length === 0) console.log("No ExUnit summaries found.");
  [...new Set(matches)].forEach((match) => console.log(match));
}

function grepLogs(runId, options) {
  if (!options.pattern) throw new Error("grep requires --pattern");
  const expression = new RegExp(options.pattern, "i");
  const context = Number(options.context || 2);
  const lines = fullLogs(runId, options).split(/\r?\n/);
  const indexes = lines.flatMap((line, index) => (expression.test(line) ? [index] : []));

  indexes.slice(0, 50).forEach((index) => {
    console.log(lines.slice(Math.max(0, index - context), index + context + 1).join("\n"));
    console.log("---");
  });
  console.log(`MATCHES ${indexes.length}`);
}

async function waitFor(runId, jobName, options) {
  if (!jobName || !options.keyword) throw new Error("wait-for requires a job and --keyword");
  const deadline = Date.now() + Number(options.timeout || 3600) * 1000;

  while (Date.now() < deadline) {
    const run = runView(runId, options);
    const job = (run.jobs || []).find((candidate) => candidate.name === jobName);
    if (job && job.status === "completed") {
      if (fullLogs(runId, options).includes(options.keyword)) {
        console.log(`FOUND ${options.keyword}`);
        return;
      }
      throw new Error(`Job completed without keyword: ${options.keyword}`);
    }
    await new Promise((resolve) => setTimeout(resolve, pollSeconds * 1000));
  }
  throw new Error(`Timed out waiting for ${options.keyword}`);
}

function download(runId, options) {
  if (!options.name || !options.dir) throw new Error("download requires --name and --dir");
  const target = path.resolve(options.dir);
  if (fs.existsSync(target)) throw new Error(`Refusing pre-existing download directory: ${target}`);
  runGh([
    "run",
    "download",
    String(runId),
    ...repoArgs(options),
    "--name",
    options.name,
    "--dir",
    target,
  ]);
  console.log(`DOWNLOADED ${options.name} ${target}`);
}

function checkActions(workflowFile) {
  const file = workflowFile || ".github/workflows/ci.yml";
  const content = fs.readFileSync(file, "utf8");
  const unpinned = content
    .split(/\r?\n/)
    .map((line, index) => ({ line: index + 1, value: line.match(/uses:\s*([^\s#]+)/)?.[1] }))
    .filter(({ value }) => value && !value.startsWith("./") && !value.startsWith("docker://"))
    .filter(({ value }) => !/@[0-9a-f]{40}$/.test(value));
  if (unpinned.length > 0) {
    unpinned.forEach(({ line, value }) => console.error(`UNPINNED ${file}:${line} ${value}`));
    process.exitCode = 1;
    return;
  }
  console.log(`PASS action pins ${file}`);
}

function repositoryName(options) {
  if (options.repo) return options.repo;
  return runGh(["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]).stdout.trim();
}

function dependencyGraph(operation, options) {
  if (!["status", "enable"].includes(operation)) {
    throw new Error("dependency-graph requires status or enable");
  }

  const repository = repositoryName(options);
  if (operation === "enable") {
    runGh([
      "api",
      "--method",
      "PUT",
      `repos/${repository}/vulnerability-alerts`,
    ]);
  }

  const probe = runGh(["api", `repos/${repository}/vulnerability-alerts`], {
    allowFailure: true,
  });
  console.log(`DEPENDENCY_GRAPH ${probe.status === 0 ? "enabled" : "unavailable"} ${repository}`);
}

function createPullRequest(options) {
  if (!options.head || !options.title || !options.body) {
    throw new Error("pr-create requires --head, --title, and --body");
  }
  const result = runGh([
    "pr",
    "create",
    ...repoArgs(options),
    "--base",
    options.base || "main",
    "--head",
    options.head,
    "--title",
    options.title,
    "--body",
    options.body,
  ]);
  process.stdout.write(result.stdout);
}

function viewPullRequest(number, options) {
  const args = [
    "pr",
    "view",
    ...repoArgs(options),
    "--json",
    "number,title,url,state,isDraft,mergeable,mergeStateStatus,headRefName,baseRefName,statusCheckRollup",
  ];
  if (number) args.splice(2, 0, String(number));
  console.log(JSON.stringify(runGh(args, { json: true }), null, 2));
}

function pullRequestChecks(number, options) {
  if (!number) throw new Error("pr-checks requires a pull request number");
  const result = runGh(["pr", "checks", String(number), ...repoArgs(options)], {
    allowFailure: true,
  });
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
  process.exitCode = result.status;
}

function mergePullRequest(number, options) {
  if (!number) throw new Error("pr-merge requires a pull request number");
  const method = options.method || "merge";
  if (!["merge", "squash", "rebase"].includes(method)) {
    throw new Error(`Unsupported merge method: ${method}`);
  }
  const result = runGh([
    "pr",
    "merge",
    String(number),
    ...repoArgs(options),
    `--${method}`,
    "--auto",
  ]);
  process.stdout.write(result.stdout);
}

async function main() {
  try {
    const argv = process.argv.slice(2);
    if (argv.length === 0 || argv[0] === "--help") {
      console.log(usage());
      return;
    }

    const parsed = parseArgs(argv);
    if (!parsed.command || parsed.options.help) {
      console.log(usage());
      return;
    }

    const { command, positional, options, fields } = parsed;
    if (command === "auth-status") {
      const result = runGh(["auth", "status"], { allowFailure: true });
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exitCode = result.status;
    } else if (command === "runs") listRuns(options);
    else if (command === "dispatch") dispatch(positional[0], fields, options);
    else if (command === "watch") await watch(positional[0], options, false);
    else if (command === "fail-fast") await watch(positional[0], options, true);
    else if (command === "log-failed") failedLogs(positional[0], options);
    else if (command === "job-log") jobLog(positional[0], positional[1], options);
    else if (command === "test-summary") testSummary(positional[0], options);
    else if (command === "grep") grepLogs(positional[0], options);
    else if (command === "wait-for") await waitFor(positional[0], positional[1], options);
    else if (command === "download") download(positional[0], options);
    else if (command === "check-actions") checkActions(positional[0]);
    else if (command === "dependency-graph") dependencyGraph(positional[0], options);
    else if (command === "pr-create") createPullRequest(options);
    else if (command === "pr-view") viewPullRequest(positional[0], options);
    else if (command === "pr-checks") pullRequestChecks(positional[0], options);
    else if (command === "pr-merge") mergePullRequest(positional[0], options);
    else throw new Error(`Unknown command: ${command}`);
  } catch (error) {
    console.error(`ERROR ${error.message}`);
    process.exitCode = 2;
  }
}

main();

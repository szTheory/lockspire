"use strict";

const core = require("@actions/core");
const {GitHub, Manifest, VERSION} = require("release-please");

const DEFAULT_GITHUB_API_URL = "https://api.github.com";
const DEFAULT_GITHUB_GRAPHQL_URL = "https://api.github.com";
const DEFAULT_GITHUB_SERVER_URL = "https://github.com";

function normalizeBoolean(value) {
  if (value === undefined || value === null || value === "") {
    return undefined;
  }

  return value === "true";
}

function optional(value) {
  return value === undefined || value === null || value === "" ? undefined : value;
}

function setPathOutput(path, key, value) {
  if (value === undefined || value === null) {
    return;
  }

  if (path === ".") {
    core.setOutput(key, value);
  } else {
    core.setOutput(`${path}--${key}`, value);
  }
}

function outputReleases(releases) {
  const createdReleases = releases.filter(Boolean);
  const pathsReleased = [];

  core.setOutput("releases_created", createdReleases.length > 0);
  core.setOutput("release_created", false);
  core.setOutput("paths_released", JSON.stringify(pathsReleased));

  for (const release of createdReleases) {
    const path = release.path || ".";
    pathsReleased.push(path);
    setPathOutput(path, "release_created", true);

    for (const [rawKey, value] of Object.entries(release)) {
      let key = rawKey;
      if (key === "tagName") key = "tag_name";
      if (key === "uploadUrl") key = "upload_url";
      if (key === "notes") key = "body";
      if (key === "url") key = "html_url";
      setPathOutput(path, key, value);
    }
  }

  core.setOutput("paths_released", JSON.stringify(pathsReleased));
}

function outputPRs(prs) {
  const createdPrs = prs.filter(Boolean);
  core.setOutput("prs_created", createdPrs.length > 0);
  if (createdPrs.length > 0) {
    core.setOutput("pr", JSON.stringify(createdPrs[0]));
    core.setOutput("prs", JSON.stringify(createdPrs));
  }
}

async function loadOrBuildManifest(github, inputs) {
  if (inputs.releaseType) {
    return Manifest.fromConfig(
      github,
      github.repository.defaultBranch,
      {
        releaseType: inputs.releaseType,
        includeComponentInTag: inputs.includeComponentInTag,
        changelogHost: inputs.changelogHost,
        versioning: inputs.versioningStrategy,
        releaseAs: inputs.releaseAs
      },
      {
        fork: inputs.fork,
        skipLabeling: inputs.skipLabeling
      },
      inputs.path
    );
  }

  const manifestOverrides =
    inputs.fork || inputs.skipLabeling
      ? {
          fork: inputs.fork,
          skipLabeling: inputs.skipLabeling
        }
      : {};

  const manifest = await Manifest.fromManifest(
    github,
    github.repository.defaultBranch,
    inputs.configFile,
    inputs.manifestFile,
    manifestOverrides
  );

  if (inputs.changelogHost && inputs.changelogHost !== DEFAULT_GITHUB_SERVER_URL) {
    for (const path of Object.keys(manifest.repositoryConfig)) {
      manifest.repositoryConfig[path].changelogHost = inputs.changelogHost;
    }
  }

  return manifest;
}

async function main() {
  const inputs = {
    token: process.env.RP_TOKEN,
    repoUrl: process.env.RP_REPO_URL || process.env.GITHUB_REPOSITORY,
    releaseType: optional(process.env.RP_RELEASE_TYPE),
    path: optional(process.env.RP_PATH),
    targetBranch: optional(process.env.RP_TARGET_BRANCH),
    configFile: process.env.RP_CONFIG_FILE || "release-please-config.json",
    manifestFile: process.env.RP_MANIFEST_FILE || ".release-please-manifest.json",
    githubApiUrl: process.env.RP_GITHUB_API_URL || DEFAULT_GITHUB_API_URL,
    githubGraphqlUrl:
      optional(process.env.RP_GITHUB_GRAPHQL_URL)?.replace(/\/graphql$/, "") ||
      DEFAULT_GITHUB_GRAPHQL_URL,
    fork: normalizeBoolean(process.env.RP_FORK),
    includeComponentInTag: normalizeBoolean(process.env.RP_INCLUDE_COMPONENT_IN_TAG),
    skipGitHubRelease: normalizeBoolean(process.env.RP_SKIP_GITHUB_RELEASE),
    skipGitHubPullRequest: normalizeBoolean(process.env.RP_SKIP_GITHUB_PULL_REQUEST),
    skipLabeling: normalizeBoolean(process.env.RP_SKIP_LABELING),
    changelogHost: process.env.RP_CHANGELOG_HOST || DEFAULT_GITHUB_SERVER_URL,
    versioningStrategy: optional(process.env.RP_VERSIONING_STRATEGY),
    releaseAs: optional(process.env.RP_RELEASE_AS)
  };

  const [owner, repo] = inputs.repoUrl.split("/");
  const github = await GitHub.create({
    owner,
    repo,
    apiUrl: inputs.githubApiUrl,
    graphqlUrl: inputs.githubGraphqlUrl,
    token: inputs.token,
    defaultBranch: inputs.targetBranch
  });

  core.info(`Running release-please version: ${VERSION}`);

  if (!inputs.skipGitHubRelease) {
    const manifest = await loadOrBuildManifest(github, inputs);
    outputReleases(await manifest.createReleases());
  } else {
    core.setOutput("releases_created", false);
    core.setOutput("release_created", false);
    core.setOutput("paths_released", "[]");
  }

  if (!inputs.skipGitHubPullRequest) {
    const manifest = await loadOrBuildManifest(github, inputs);
    outputPRs(await manifest.createPullRequests());
  } else {
    core.setOutput("prs_created", false);
  }
}

main().catch(error => {
  core.setFailed(`release-please failed: ${error.message}`);
});

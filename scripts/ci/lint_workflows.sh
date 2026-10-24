#!/usr/bin/env bash
set -euo pipefail

ACTIONLINT_VERSION="1.7.12"
ACTIONLINT_SHA256="8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8"
SHELLCHECK_VERSION="0.11.0"
SHELLCHECK_SHA256="8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"
TOOLS_DIR="$(mktemp -d -t lockspire-ci-lint.XXXXXX)"
trap 'rm -rf "$TOOLS_DIR"' EXIT

have_version() {
  "$1" --version 2>/dev/null | grep -Eq "$2"
}

bootstrap_linux_tools() {
  local actionlint_archive="$TOOLS_DIR/actionlint.tar.gz"
  local shellcheck_archive="$TOOLS_DIR/shellcheck.tar.xz"
  curl --fail --silent --show-error --location \
    "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" \
    -o "$actionlint_archive"
  printf '%s  %s\n' "$ACTIONLINT_SHA256" "$actionlint_archive" | sha256sum --check --status
  tar -xzf "$actionlint_archive" -C "$TOOLS_DIR"
  curl --fail --silent --show-error --location \
    "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
    -o "$shellcheck_archive"
  printf '%s  %s\n' "$SHELLCHECK_SHA256" "$shellcheck_archive" | sha256sum --check --status
  tar -xJf "$shellcheck_archive" -C "$TOOLS_DIR"
  PATH="$TOOLS_DIR:$TOOLS_DIR/shellcheck-v${SHELLCHECK_VERSION}:$PATH"
}

if ! have_version actionlint "${ACTIONLINT_VERSION}" || ! have_version shellcheck "${SHELLCHECK_VERSION}"; then
  test "$(uname -s)" = "Linux"
  test "$(uname -m)" = "x86_64"
  bootstrap_linux_tools
fi

have_version actionlint "${ACTIONLINT_VERSION}"
have_version shellcheck "${SHELLCHECK_VERSION}"

workflows=()
scripts=()
shell_shebang_re='^#!.*(ba)?sh'
while IFS= read -r -d '' tracked_path; do
  # `git ls-files -z` excludes generated/untracked dependencies and keeps paths
  # with spaces intact. Match find's old `-type f` behavior by excluding symlinks.
  [[ -f "$tracked_path" && ! -L "$tracked_path" ]] || continue

  if [[ "$tracked_path" == .github/workflows/*.yml ]]; then
    workflows+=("./$tracked_path")
  fi

  if [[ "$tracked_path" == *.sh || -x "$tracked_path" ]]; then
    first_line=''
    IFS= read -r first_line < "$tracked_path" || true
    if [[ "$first_line" =~ $shell_shebang_re ]]; then
      scripts+=("./$tracked_path")
    fi
  fi
done < <(git ls-files -z)

test "${#workflows[@]}" -gt 0
test "${#scripts[@]}" -gt 0
actionlint -no-color "${workflows[@]}"
shellcheck --severity=warning "${scripts[@]}"

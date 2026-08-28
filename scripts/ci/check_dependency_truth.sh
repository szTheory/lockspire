#!/usr/bin/env bash

set -euo pipefail

mix deps.unlock --check-unused
bash scripts/ci/check_architecture_topology.sh

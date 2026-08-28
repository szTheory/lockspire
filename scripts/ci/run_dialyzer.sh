#!/usr/bin/env bash
set -euo pipefail

mix deps.get --check-locked
mix compile --warnings-as-errors
mix qa.dialyzer

#!/usr/bin/env bash

set -euo pipefail

MIX_ENV=dev mix sobelow --config --router lib/lockspire/web/router.ex --private --threshold low --exit
MIX_ENV=dev mix sobelow --config --router lib/lockspire/web/admin_router.ex --private --threshold low --exit

#!/usr/bin/env bash
set -euxo pipefail

export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=safe.directory 
export GIT_CONFIG_VALUE_0=/opt/app-root/src

pre-commit run --color=never --from-ref main --to-ref HEAD

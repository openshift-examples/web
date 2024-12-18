#!/usr/bin/env bash
set -euxo pipefail

git config --global --add safe.directory /opt/app-root/src

pre-commit run --color=never --from-ref main --to-ref HEAD

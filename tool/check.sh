#!/usr/bin/env bash
# Runs all static checks and tests of the app and the local packages.
set -euo pipefail

cd "$(dirname "$0")/.."
make check

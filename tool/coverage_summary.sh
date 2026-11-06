#!/usr/bin/env bash
# Prints the line coverage of lcov files as a Markdown table, e.g. for the job summary in CI:
#   tool/coverage_summary.sh App=coverage/lcov.info erg_protocol=packages/erg_protocol/coverage/lcov.info
set -euo pipefail

echo "| Paket | Zeilen | Abgedeckt | Coverage |"
echo "|---|---:|---:|---:|"
for entry in "$@"; do
  name="${entry%%=*}"
  file="${entry#*=}"
  awk -F: -v name="$name" '
    /^LF:/ { found += $2 }
    /^LH:/ { hit += $2 }
    END {
      pct = found ? sprintf("%.1f %%", 100 * hit / found) : "–"
      printf "| %s | %d | %d | %s |\n", name, found, hit, pct
    }' "$file"
done

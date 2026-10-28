#!/bin/bash
# Purpose: Spark accounts. Side effects: READ-ONLY; account access required.
# Usage: spark_accounts.sh [--json]
# Example: spark_accounts.sh --help
set -e
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec spark accounts --help
fi
command -v spark >/dev/null || { echo 'spark CLI not found' >&2; exit 1; }
spark accounts "$@" || exit 1

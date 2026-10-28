#!/bin/bash
# Purpose: Spark search. Side effects: READ-ONLY; account access required.
# Usage: spark_search.sh [TOPIC] [--filter QUERY] [--in FOLDER] [--json]
# Example: spark_search.sh --help
set -e
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec spark search --help
fi
command -v spark >/dev/null || { echo 'spark CLI not found' >&2; exit 1; }
spark search "$@" || exit 1

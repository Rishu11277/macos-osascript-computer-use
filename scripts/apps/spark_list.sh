#!/bin/bash
# Purpose: Spark emails. Side effects: READ-ONLY; account access required.
# Usage: spark_list.sh [FOLDER] [--filter QUERY] [--page-size N] [--json]
# Example: spark_list.sh --help
set -e
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec spark emails --help
fi
command -v spark >/dev/null || { echo 'spark CLI not found' >&2; exit 1; }
spark emails "$@" || exit 1

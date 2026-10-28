#!/bin/bash
# Purpose: Spark thread. Side effects: READ-ONLY; account access required.
# Usage: spark_read.sh ID [--json]
# Example: spark_read.sh --help
set -e
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec spark thread --help
fi
command -v spark >/dev/null || { echo 'spark CLI not found' >&2; exit 1; }
spark thread "$@" || exit 1

#!/bin/bash
# Purpose: Spark events. Side effects: READ-ONLY; account access required.
# Usage: spark_events.sh [--today|--tomorrow] [--json]
# Example: spark_events.sh --help
set -e
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec spark events --help
fi
command -v spark >/dev/null || { echo 'spark CLI not found' >&2; exit 1; }
spark events "$@" || exit 1

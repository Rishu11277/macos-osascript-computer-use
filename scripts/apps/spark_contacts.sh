#!/bin/bash
# Purpose: Spark contacts. Side effects: READ-ONLY; account access required.
# Usage: spark_contacts.sh [QUERY] [--json]
# Example: spark_contacts.sh --help
set -e
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec spark contacts --help
fi
command -v spark >/dev/null || { echo 'spark CLI not found' >&2; exit 1; }
spark contacts "$@" || exit 1

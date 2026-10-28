#!/bin/bash
# Purpose: Send exactly one reviewed draft. Side effects: SENDS EMAIL.
# Usage: spark_send.sh --confirm-send DRAFT_ID
# Example: spark_send.sh --help
# Use only after explicit user authorization for this exact draft.
set -e
if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then sed -n '2,5p' "$0"; exit 0; fi
[[ $# -eq 2 && "$1" == '--confirm-send' && "$2" =~ ^[0-9]+$ ]] || { echo 'Requires --confirm-send DRAFT_ID; review and authorize first' >&2; exit 2; }
spark action send "$2" || exit 1

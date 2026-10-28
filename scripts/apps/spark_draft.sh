#!/bin/bash
# Purpose: Create a personal unsent Spark draft. Side effects: WRITES draft.
# Usage: spark_draft.sh ACCOUNT TO SUBJECT BODY_FILE [--json]
# Example: spark_draft.sh me@example.com you@example.com Hello /tmp/body.md
# Spark adds the signature. Does not share, send, or edit existing drafts.
# Body arguments may be visible to local process inspection.
set -e
if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then sed -n '2,5p' "$0"; exit 0; fi
[[ $# -ge 4 && $# -le 5 ]] || { echo 'Expected ACCOUNT TO SUBJECT BODY_FILE [--json]' >&2; exit 2; }
[[ $# -eq 4 || "$5" == '--json' ]] || exit 2
[[ -f "$4" && -r "$4" ]] || { echo 'Body file unreadable' >&2; exit 2; }
body=$(cat -- "$4")
extra=(); [[ $# -eq 4 ]] || extra=(--json)
spark draft --account "$1" --to "$2" --subject "$3" --body "$body" "${extra[@]}" || exit 1

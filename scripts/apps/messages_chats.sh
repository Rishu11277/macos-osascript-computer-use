#!/bin/bash
# Purpose: Read messages metadata. Side effects: READ-ONLY, may request Automation access.
# Usage: messages_chats.sh [LIMIT] [--json]
# Example: messages_chats.sh --help
# JSON output always. Apps must already be running; no content is sent or modified.
set -e
if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then sed -n '2,6p' "$0"; exit 0; fi
args=(); for a in "$@"; do [[ "$a" == '--json' ]] || args+=("$a"); done
[[ ${#args[@]} -le 1 ]] || { echo 'Too many arguments' >&2; exit 2; }
if [[ ${#args[@]} -gt 0 ]]; then
 [[ "${args[0]}" =~ ^[1-9][0-9]?$|^100$ ]] || { echo 'Limit must be 1..100' >&2; exit 2; }
fi
here=$(cd -- "$(dirname -- "$0")" && pwd)
/usr/bin/osascript -l JavaScript "$here/native_read.js" 'messages' "${args[@]}" || exit 1

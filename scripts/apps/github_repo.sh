#!/bin/bash
# Inspect a local Git repository or open it in GitHub Desktop.
# Usage: github_repo.sh status|open PATH. Example: github_repo.sh status .
# Side effects: status read-only; open changes UI.
set -u
usage(){ echo 'Usage: github_repo.sh status|open PATH'; }
[[ ${1:-} == -h ]] && { usage; exit 0; }
[[ $# == 2 && -d $2 ]] || { usage >&2; exit 2; }
root=$(git -C "$2" rev-parse --show-toplevel 2>/dev/null) || { echo 'Not a Git repository' >&2; exit 1; }
case "$1" in
 status) exec git -C "$root" -c core.fsmonitor=false status --short --branch ;;
 open) exec open -a 'GitHub Desktop' "$root" ;;
 *) usage >&2; exit 2;;
esac

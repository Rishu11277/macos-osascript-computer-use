#!/bin/bash
# Inspect Microsoft Teams without launching, activating, or changing content.
# Usage: teams_inspect.sh state | find ROLE [LABEL_CONTAINS]
# state prints JSON; find searches window 1 (depth 40, max 3000 nodes, max 50 matches).
# Side effects: READ-ONLY. find needs the app running and Accessibility permission.
set -e
usage() { sed -n '2,5p' "$0"; }
if [ "${1:-}" = -h ] && [ "$#" -eq 1 ]; then usage; exit 0; fi
case "${1:-}" in
  state) [ "$#" -eq 1 ] || { usage >&2; exit 2; };;
  find) [ "$#" -ge 2 ] && [ "$#" -le 3 ] && [ -n "$2" ] || { usage >&2; exit 2; };;
  *) usage >&2; exit 2;;
esac
core="$(cd "$(dirname "$0")/../core" && pwd)"
. "$core/_resolve_app.sh"
if ! (resolve_app "com.microsoft.teams2") >/dev/null 2>&1; then
  resolve_app "com.microsoft.teams"
else
  resolve_app "com.microsoft.teams2"
fi
if [ "$1" = state ]; then exec bash "$core/app_state.sh" "$APP_PATH" --json; fi
proc=$(osascript - "$APP_BID" <<'OSA'
on run argv
    tell application "System Events"
        set matches to every process whose bundle identifier is (item 1 of argv)
        if (count of matches) is not 1 then error "App must have exactly one running process; launch it intentionally first" number -1728
        return name of item 1 of matches
    end tell
end run
OSA
)
exec bash "$core/ui_find.sh" "$proc" --role "$2" --name "${3:-}" --contains --depth 40 --max-nodes 3000 --max 50

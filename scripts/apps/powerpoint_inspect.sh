#!/bin/bash
# Inspect Microsoft PowerPoint without launching, focusing, editing, or saving documents.
# Usage: powerpoint_inspect.sh [state|dictionary|ui]
# state: app metadata; dictionary: installed scripting terms; ui: first 100 UI matches.
# Exit: 0 success, 1 unavailable/error, 2 usage. App workflows are untested here.
set -u
usage() { sed -n '2,5p' "$0"; }
if [ "$#" -eq 1 ] && { [ "$1" = -h ] || [ "$1" = --help ]; }; then usage; exit 0; fi
[ "$#" -le 1 ] || { usage >&2; exit 2; }
mode="${1:-state}"
case "$mode" in state|dictionary|ui) ;; *) usage >&2; exit 2;; esac
core="$(cd "$(dirname "$0")/../core" && pwd)" || exit 1
. "$core/_resolve_app.sh"
resolve_app "Microsoft PowerPoint"
case "$mode" in
  state) exec bash "$core/app_state.sh" "$APP_PATH";;
  dictionary) exec bash "$core/app_dictionary.sh" "$APP_PATH" --all;;
  ui)
    # Check by resolved bundle ID; no app-specific terms compile or launch here.
    running=$(osascript - "$APP_BID" <<'OSA'
on run argv
    return running of application id (item 1 of argv)
end run
OSA
) || exit 1
    [ "$running" = true ] || { echo "Microsoft PowerPoint is not running; launch intentionally before UI inspection" >&2; exit 1; }
    exec bash "$core/ui_find.sh" "Microsoft PowerPoint" --depth 20 --max-nodes 1500 --max 100
    ;;
esac

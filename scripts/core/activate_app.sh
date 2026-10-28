#!/bin/bash
# Bring an app to the front (launching it only with --launch) and wait until it is frontmost.
# Usage: activate_app.sh "<App name>" [--launch] [--timeout S]
# Side effects: CHANGES UI (focus). Without --launch, refuses if the app is not running.
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
app="$1"; shift || true
[ -z "$app" ] || [ "$app" = "-h" ] && { sed -n '2,4p' "$0"; [ -z "$app" ] && exit 2 || exit 0; }
launch=0; t=10
while [ $# -gt 0 ]; do case "$1" in --launch) launch=1; shift;; --timeout) need "$@"; t="$2"; shift 2;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
posint --timeout "$t" 300
. "$(cd "$(dirname "$0")" && pwd)/_resolve_app.sh"
resolve_app "$app"
osascript - "$app" "$launch" "$t" "$APP_BID" <<'OSA'
on run argv
    set {appName, doLaunch, maxS, bid} to {item 1 of argv, item 2 of argv, (item 3 of argv) as integer, item 4 of argv}
    if not (running of application id bid) and doLaunch is not "1" then error appName & " is not running (pass --launch to start it)" number -600
    tell application id bid to activate
    tell application "System Events"
        repeat (maxS * 5) times
            set fp to first process whose frontmost is true
            if bundle identifier of fp is bid then return "frontmost: " & name of fp
            delay 0.2
        end repeat
    end tell
    error appName & " did not become frontmost within " & maxS & "s" number -1712
end run
OSA

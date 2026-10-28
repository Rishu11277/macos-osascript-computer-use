#!/bin/bash
# Read-only probe of desktop-automation access. Never launches apps.
# Usage: scripts/probe.sh ["<app name to test Automation for>"]
# Accessibility (UI scripting/keystrokes) and Automation (app dictionaries) are separate
# permissions: a failure in one does not mean the other is blocked.
app="$1"
[ "$app" = "-h" ] && { sed -n "2,5p" "$0"; exit 0; }
echo "macOS: $(sw_vers -productVersion)"
echo "frontmost: $(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>&1)"
echo "visible apps: $(osascript -e 'tell application "System Events" to get name of every process whose background only is false' 2>&1)"
# Accessibility: reading another app's menu bar requires it (-1719/-25211 when missing).
if out=$(osascript -e 'tell application "System Events" to get name of every menu of menu bar 1 of process "Finder"' 2>&1); then
  echo "accessibility (UI scripting, keystrokes): OK"
else
  echo "accessibility (UI scripting, keystrokes): UNAVAILABLE -> $out"
  echo "  note: app-dictionary scripting may still work; test it with: $0 \"<app>\""
fi
if [ -n "$app" ]; then
  ( . "$(cd "$(dirname "$0")" && pwd)/_resolve_app.sh"; resolve_app "$app" ) >/dev/null || { echo "automation for $app: NOT TESTED (app not found on disk)"; exit 0; }
  . "$(cd "$(dirname "$0")" && pwd)/_resolve_app.sh"; resolve_app "$app"
  running=$(osascript - "$APP_BID" <<'OSA' 2>&1
on run argv
    return running of application id (item 1 of argv)
end run
OSA
)
  if [ "$running" != "true" ]; then
    echo "automation for $app: NOT TESTED (app not running: $running; probe never launches apps)"
  elif out=$(osascript - "$APP_BID" <<'OSA' 2>&1
on run argv
    tell application id (item 1 of argv) to return name
end run
OSA
); then
    echo "automation for $app: OK"
  else
    echo "automation for $app: DENIED or failed -> $out  (-1743 = user must allow in Privacy & Security > Automation)"
  fi
fi

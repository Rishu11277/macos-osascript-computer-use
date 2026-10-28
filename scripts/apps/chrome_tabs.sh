#!/bin/bash
# List or activate a Chrome tab by its window and tab IDs (Chrome returns them as text; valid for the current session).
# Usage: chrome_tabs.sh list | activate WINDOW_ID TAB_ID
# Example: chrome_tabs.sh list. Side effects: activate changes UI focus.
set -u
usage(){ echo 'Usage: chrome_tabs.sh list | activate WINDOW_ID TAB_ID'; }
[[ ${1:-} == -h ]] && { usage; exit 0; }
case "${1:-}" in
 list) [[ $# == 1 ]] || { usage >&2; exit 2; } ;;
 activate) [[ $# == 3 && $2 =~ ^[0-9]+$ && $3 =~ ^[0-9]+$ ]] || { usage >&2; exit 2; } ;;
 *) usage >&2; exit 2;;
esac
osascript - "$@" <<'OSA'
on run argv
 if not application "Google Chrome" is running then error "Chrome is not running" number -600
 tell application "Google Chrome"
  if item 1 of argv is "list" then
   set rows to {}
   repeat with w in windows
    repeat with t in tabs of w
     set end of rows to ((id of w as text) & (character id 9) & (id of t as text) & (character id 9) & (title of t))
    end repeat
   end repeat
   set AppleScript's text item delimiters to linefeed
   return rows as text
  else
   set wid to item 2 of argv
   set tid to item 3 of argv
   repeat with w in windows
    if (id of w as text) is wid then
     repeat with i from 1 to count of tabs of w
      if (id of tab i of w as text) is tid then
       set active tab index of w to i
       set index of w to 1
       activate
       return "Activated"
      end if
     end repeat
    end if
   end repeat
   error "Tab or window not found" number -1728
  end if
 end tell
end run
OSA

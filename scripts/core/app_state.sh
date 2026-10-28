#!/bin/bash
# Report an app's state WITHOUT launching it: running, frontmost, version, bundle id, process name, windows.
# Usage: app_state.sh "<App name>" [--json]
# Side effects: READ-ONLY (never launches or activates).  Window names need Accessibility.
app="$1"; json="$2"
[ -z "$app" ] || [ "$app" = "-h" ] && { sed -n '2,4p' "$0"; [ -z "$app" ] && exit 2 || exit 0; }
. "$(cd "$(dirname "$0")" && pwd)/_resolve_app.sh"
resolve_app "$app"
osascript - "$app" "$json" "$APP_BID" <<'OSA'
on run argv
    set appName to item 1 of argv
    set asJson to item 2 of argv is "--json"
    set bid to item 3 of argv
    set ver to ""
    set isRunning to running of application id bid
    set procName to ""
    set isFront to false
    set winNames to {}
    if isRunning then
        try
            set ver to version of application id bid
        end try
        tell application "System Events"
            set procs to (every process whose bundle identifier is bid)
            if (count of procs) > 0 then
                set p to item 1 of procs
                set procName to name of p
                set isFront to frontmost of p
                try
                    set winNames to name of every window of p
                end try
            end if
        end tell
    end if
    set winText to my joinList(winNames, " | ")
    if asJson then
        return "{\"app\":" & my q(appName) & ",\"running\":" & isRunning & ",\"frontmost\":" & isFront & ",\"bundle_id\":" & my q(bid) & ",\"version\":" & my q(ver) & ",\"process\":" & my q(procName) & ",\"window_count\":" & (count of winNames) & "}"
    end if
    return "app: " & appName & linefeed & "running: " & isRunning & linefeed & "frontmost: " & isFront & linefeed & "bundle id: " & bid & linefeed & "version: " & ver & linefeed & "process name: " & procName & linefeed & "windows (" & (count of winNames) & "): " & winText
end run
on joinList(L, d)
    set {o, AppleScript's text item delimiters} to {AppleScript's text item delimiters, d}
    set r to L as text
    set AppleScript's text item delimiters to o
    return r
end joinList
on q(s)
    set s to s as text
    set {o, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "\\"}
    set parts to text items of s
    set AppleScript's text item delimiters to "\\\\"
    set s to parts as text
    set AppleScript's text item delimiters to "\""
    set parts to text items of s
    set AppleScript's text item delimiters to "\\\""
    set s to parts as text
    set AppleScript's text item delimiters to o
    return "\"" & s & "\""
end q
OSA

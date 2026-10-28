#!/bin/bash
# Paste text into the frontmost field of a process via the clipboard, protecting the user's clipboard.
# - Refuses if the clipboard holds anything other than plain text (UTF-8/16 types and legacy utxt/TEXT flavors only; "styl" styling or unknown dynamic types count as rich and are refused,
#   which includes text set by AppleScript "set the clipboard". Use --force only when losing that styling is acceptable) (rich text, images, files would be lost) unless --force.
# - Re-checks that the target is frontmost immediately before Cmd+V.
# - Restores the previous plain-text clipboard (or empties it if it was empty) only if the pasteboard
#   changeCount shows nobody else changed it since this script set it; restores on errors too.
# Usage: paste_text.sh "<process>" "<text>" [--activate] [--force] [--any-focus]
#   Refuses unless a text field has keyboard focus (override: --any-focus).
#   Text may also come from stdin: paste_text.sh "<process>" - < file.txt
# Side effects: CHANGES UI (pastes) and temporarily CHANGES CLIPBOARD (plain text only is preserved).
proc="$1"; txt="$2"; shift $(( $# < 2 ? $# : 2 ))
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,9p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
act=""; force=""; anyfocus=0
while [ $# -gt 0 ]; do case "$1" in --activate) act=1; shift;; --force) force=1; shift;; --any-focus) anyfocus=1; shift;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
[ "$txt" = "-" ] && txt="$(cat)"
[ -z "$txt" ] && { echo "text required" >&2; exit 2; }
# Refuse unless a text field has keyboard focus (prevents stray keystrokes into the wrong control/app).
focus_guard() {
  [ "$anyfocus" = 1 ] && return 0
  . "$(dirname "$0")/_pid.sh"; proc_pid "$proc"
  local f; f=$(python3 -I "$(dirname "$0")/_ax_focus.py" "$PROC_PID") || exit 1
  case "$f" in *$'\t'1) return 0;; esac
  echo "no text field has keyboard focus in $proc (focused: ${f%%$'\t'*}); refusing. Click/focus a field first, or pass --any-focus." >&2
  exit 1
}
[ "$act" = 1 ] && { osascript - "$proc" <<<'on run argv
tell application "System Events" to set frontmost of process (item 1 of argv) to true
end run' >/dev/null; sleep 0.3; }
focus_guard
osascript - "$proc" "$txt" "$act" "$force" <<'OSA'
use AppleScript version "2.4"
use framework "AppKit"
use scripting additions
on run argv
    set {procName, theText, act, force} to {item 1 of argv, item 2 of argv, item 3 of argv, item 4 of argv}
    set pb to current application's NSPasteboard's generalPasteboard()
    set plainTypes to {"public.utf8-plain-text", "public.utf16-plain-text", "public.utf16-external-plain-text", "NSStringPboardType", "com.apple.traditional-mac-plain-text", "CorePasteboardFlavorType 0x75747874", "CorePasteboardFlavorType 0x54455854"}
    set typeList to (pb's types()) as list
    set hasOther to false
    repeat with t in typeList
        if (t as text) is not in plainTypes then set hasOther to true
    end repeat
    if hasOther and force is not "1" then error "clipboard holds non-plain-text data (" & (count of typeList) & " types, e.g. rich text/images/files); refusing so it isn't lost. Use --force or set_field.sh." number -1719
    set wasEmpty to (count of typeList) is 0
    set saved to missing value
    if not wasEmpty then set saved to (pb's stringForType:(current application's NSPasteboardTypeString))
    tell application "System Events"
        if not (exists process procName) then error "no process named " & procName number -1728
        if act is "1" then
            set frontmost of process procName to true
            repeat 25 times
                if frontmost of process procName then exit repeat
                delay 0.2
            end repeat
        end if
        if not (frontmost of process procName) then error procName & " is not frontmost; refusing to paste (use --activate)" number -1719
    end tell
    pb's clearContents()
    pb's setString:theText forType:(current application's NSPasteboardTypeString)
    set myCount to (pb's changeCount()) as integer
    set pasteErr to ""
    try
        tell application "System Events"
            if not (frontmost of process procName) then error procName & " lost focus before paste; nothing pasted" number -1719
            keystroke "v" using {command down}
        end tell
        delay 0.4
    on error m number n
        set pasteErr to m & " (" & n & ")"
    end try
    set restored to "NOT restored: clipboard changed by someone else during paste"
    if ((pb's changeCount()) as integer) is myCount then
        pb's clearContents()
        if wasEmpty or saved is missing value then
            set restored to "clipboard emptied again (was empty)"
        else
            pb's setString:saved forType:(current application's NSPasteboardTypeString)
            set restored to "previous plain-text clipboard restored"
        end if
    end if
    if pasteErr is not "" then error "paste failed: " & pasteErr & "; " & restored number -1719
    return "pasted " & (length of theText) & " chars; " & restored
end run
OSA

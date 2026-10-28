#!/bin/bash
# Run JavaScript in the ONE Chrome tab whose URL contains a substring; supports async (Promise) results.
# Fails (exit 1, listing URLs) if no tab or more than one tab matches, so it never targets the wrong tab.
# Needs Chrome: View > Developer > Allow JavaScript from Apple Events. Does not change focus or tabs.
# Usage: scripts/chrome_js.sh "<url substring>" "<JS expression; may return a Promise>" [timeout_s=15, 1-120]
# Example (read a Google Doc as text, read-only):
#   scripts/chrome_js.sh "/document/d/DOC_ID/" "fetch('/document/d/DOC_ID/export?format=txt').then(r=>r.text())"
match="$1"; js="$2"; timeout="${3:-15}"
[ -z "$match" ] || [ -z "$js" ] && { echo "usage: $0 \"<url substring>\" \"<js>\" [timeout_s]" >&2; exit 2; }
case "$timeout" in ""|*[!0-9]*) echo "timeout must be an integer 1-120" >&2; exit 2;; esac
[ "$timeout" -ge 1 ] && [ "$timeout" -le 120 ] || { echo "timeout must be an integer 1-120" >&2; exit 2; }
key="__agent_$$_$RANDOM"
# JS is passed as an argument (never spliced into AppleScript source); JSON-encoded for safe embedding in the page.
wrapped=$(python3 -I -c 'import json,sys; k,js=sys.argv[1],sys.argv[2]; print("window[%s]=undefined;Promise.resolve().then(()=>(%s)).then(v=>window[%s]={ok:String(v)}).catch(e=>window[%s]={err:String(e)});\"started\"" % (json.dumps(k),js,json.dumps(k),json.dumps(k)))' "$key" "$js")
run_js() {
osascript - "$match" "$1" <<'OSA'
on run argv
    set m to item 1 of argv
    set code to item 2 of argv
    set hits to {}
    set urls to {}
    tell application "Google Chrome"
        repeat with w in windows
            repeat with t in tabs of w
                if URL of t contains m then
                    set end of hits to contents of t
                    set u to URL of t
                    if (length of u) > 90 then set u to (text 1 thru 90 of u) & "…"
                    if (count of urls) < 10 then set end of urls to u
                end if
            end repeat
        end repeat
        if (count of hits) is 0 then error "No Chrome tab URL contains: " & m number -1728
        if (count of hits) > 1 then
            set AppleScript's text item delimiters to linefeed & "  "
            error ((count of hits) as text) & " tabs match '" & m & "'; use a more specific substring:" & linefeed & "  " & (urls as text) number -1719
        end if
        return (execute (item 1 of hits) javascript code)
    end tell
end run
OSA
}
run_js "$wrapped" >/dev/null || exit 1
for ((i=0; i<timeout*5; i++)); do
  res=$(run_js "(()=>{const r=window['$key']; if(!r) return '__PENDING__'; delete window['$key']; return r.err!==undefined ? '__ERR__'+r.err : r.ok;})()") || exit 1
  [ "$res" != "__PENDING__" ] && { case "$res" in __ERR__*) echo "${res#__ERR__}" >&2; exit 1;; *) printf '%s\n' "$res"; exit 0;; esac; }
  sleep 0.2
done
echo "timed out after ${timeout}s" >&2; exit 1

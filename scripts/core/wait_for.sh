#!/bin/bash
# Wait (bounded) for a condition; exit 0 when met, 1 on timeout.
# Usage:
#   wait_for.sh window   "<process>" [--title-contains T] [--timeout S]
#   wait_for.sh element  "<process>" [--role R] [--name L] [--contains] [--timeout S]
#   wait_for.sh frontmost "<process>" [--timeout S]
#   wait_for.sh gone     "<process>" --title-contains T [--timeout S]   (window with that title disappears)
# Side effects: READ-ONLY. Default timeout 10 s, max 300. Exit 0 met, 1 timeout, 2 usage or real error
#   ("not there yet" errors -1728/-1719 keep waiting; other errors stop with exit 2).
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
DIR="$(cd "$(dirname "$0")" && pwd)"
kind="$1"; proc="$2"; shift $(( $# < 2 ? $# : 2 ))
[ -z "$kind" ] || [ "$kind" = "-h" ] && { sed -n '2,8p' "$0"; [ -z "$kind" ] && exit 2 || exit 0; }
[ -z "$proc" ] && { echo "process required" >&2; exit 2; }
title=""; role=""; name=""; contains=""; t=10
while [ $# -gt 0 ]; do case "$1" in
  --title-contains) need "$@"; title="$2"; shift 2;; --role) need "$@"; role="$2"; shift 2;; --name) need "$@"; name="$2"; shift 2;;
  --contains) contains="--contains"; shift;; --timeout) need "$@"; t="$2"; shift 2;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
posint --timeout "$t" 300
check() {
  case "$kind" in
    window|gone) bounded osascript - "$proc" "$title" <<'OSA' 2>"$errf" || { rc=$?; [ $rc -eq 142 ] && { echo pending; return 0; }; cat "$errf" >&2; return 2; }
on run argv
    set {p, t} to {item 1 of argv, item 2 of argv}
    tell application "System Events"
        if not (exists process p) then return "no"
        repeat with w in (windows of process p)
            set n to ""
            try
                set n to name of w as text
            end try
            if t is "" or n contains t then return "yes"
        end repeat
    end tell
    return "no"
end run
OSA
    ;;
    frontmost) bounded osascript - "$proc" <<'OSA' 2>"$errf" || { rc=$?; [ $rc -eq 142 ] && { echo pending; return 0; }; cat "$errf" >&2; return 2; }
on run argv
    tell application "System Events"
        if not (exists process (item 1 of argv)) then return "no"
        if frontmost of process (item 1 of argv) then return "yes"
    end tell
    return "no"
end run
OSA
    ;;
    element) out=$(bounded "$DIR/ui_find.sh" "$proc" ${role:+--role "$role"} ${name:+--name "$name"} $contains --max 1 2>"$errf"); rc=$?
      if [ $rc -eq 142 ]; then echo pending   # this check hit the remaining-time bound
      elif [ $rc -ne 0 ]; then
        # "not there yet" errors mean keep waiting; anything else is a real failure
        if grep -qE '\((-1728|-1719)\)' "$errf"; then echo no; else cat "$errf" >&2; return 2; fi
      else
        case "$(printf '%s\n' "$out" | sed -n 1p)" in "matches: 0") echo no;; matches:*) echo yes;; *) echo "unexpected ui_find output" >&2; return 2;; esac
      fi;;
    *) echo "unknown kind: $kind" >&2; exit 2;;
  esac
}
errf=$(mktemp); trap 'rm -f "$errf"' EXIT
end=$(( $(date +%s) + t ))
# each check is itself bounded by the remaining time (an Apple Event can otherwise outlast the deadline)
bounded() { local rem=$(( end - $(date +%s) )); [ $rem -lt 1 ] && rem=1; perl -e 'alarm shift; exec @ARGV' "$rem" "$@"; }
while [ "$(date +%s)" -lt "$end" ]; do
  r=$(check) || { echo "wait_for: check failed" >&2; exit 2; }
  # "pending" (a check that ran out of time) is never treated as success for any kind
  if [ "$kind" = "gone" ]; then [ "$r" = "no" ] && { echo "gone"; exit 0; }
  else [ "$r" = "yes" ] && { echo "ready: $kind"; exit 0; }; fi
  sleep 0.25
done
echo "timed out after ${t}s waiting for $kind on $proc" >&2; exit 1

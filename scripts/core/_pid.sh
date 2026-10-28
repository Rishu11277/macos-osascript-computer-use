# Sourced by helpers. proc_pid "<process name>" -> sets PROC_PID (via System Events, so names like "SPIKE" resolve).
proc_pid() {
  PROC_PID=$(osascript - "$1" <<'OSA' 2>/dev/null
on run argv
    tell application "System Events"
        if not (exists process (item 1 of argv)) then return ""
        return unix id of process (item 1 of argv)
    end tell
end run
OSA
)
  [ -n "$PROC_PID" ] || { echo "no process named $1 (-1728)" >&2; exit 1; }
}

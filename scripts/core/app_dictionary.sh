#!/bin/bash
# Show an app's AppleScript dictionary WITHOUT Xcode (`sdef` needs Xcode on many Macs).
# Reads Info.plist (NSAppleScriptEnabled, OSAScriptingDefinition) and the bundled .sdef XML; falls back to the
# OpenScripting API (_osa_sdef.py) for legacy apps without a .sdef file (e.g. TextEdit).
# Usage: app_dictionary.sh "<App name|bundle id|/path/App.app>" [--commands|--classes|--all|--raw] [--allow-launch]
#   --allow-launch: permit the OpenScripting fallback, which LAUNCHES a non-running legacy app (e.g. TextEdit).
#   default --commands: suite, command name, description.  --classes: classes + properties.
# Side effects: READ-ONLY (never launches unless --allow-launch).  Exit 1 = app not found or not scriptable (use UI scripting instead).
# Example: app_dictionary.sh "Google Chrome" --commands
app="$1"; mode="--commands"; allow_launch=0
shift; for x in "$@"; do case "$x" in --allow-launch) allow_launch=1;; *) mode="$x";; esac; done
[ -z "$app" ] || [ "$app" = "-h" ] && { sed -n '2,8p' "$0"; [ -z "$app" ] && exit 2 || exit 0; }
case "$mode" in --commands|--classes|--all|--raw) ;; *) echo "bad mode: $mode" >&2; exit 2;; esac
. "$(cd "$(dirname "$0")" && pwd)/_resolve_app.sh"
resolve_app "$app"; path="$APP_PATH"
path="${path%/}"
[ -d "$path" ] || { echo "app not found: $app" >&2; exit 1; }
plist="$path/Contents/Info.plist"
enabled=$(/usr/libexec/PlistBuddy -c 'Print :NSAppleScriptEnabled' "$plist" 2>/dev/null)
sdefname=$(/usr/libexec/PlistBuddy -c 'Print :OSAScriptingDefinition' "$plist" 2>/dev/null)
sdeffile=""
[ -n "$sdefname" ] && sdeffile="$path/Contents/Resources/$sdefname"
[ -f "$sdeffile" ] || sdeffile=$(ls "$path"/Contents/Resources/*.sdef 2>/dev/null | head -1)
echo "app: $path"
echo "NSAppleScriptEnabled: ${enabled:-not set}  OSAScriptingDefinition: ${sdefname:-none}"
if [ -z "$sdeffile" ] || [ ! -f "$sdeffile" ]; then
  # legacy Cocoa scripting (scriptSuite/scriptTerminology) has no .sdef file: ask the OS for the definition
  # NOTE: this API LAUNCHES the app if it isn't running, so it's only used when the app is already
  # running or --allow-launch is given.
  running=$(osascript -e "running of application id \"$APP_BID\"" 2>/dev/null)
  if [ "$running" != "true" ] && [ "$allow_launch" != 1 ]; then
    echo "no bundled .sdef. This app may use legacy Cocoa scripting; reading it would launch the app." >&2
    echo "Re-run with --allow-launch (or start the app first) to read it via the OpenScripting API." >&2
    exit 1
  fi
  tmp=$(mktemp -t sdef); trap 'rm -f "$tmp"' EXIT
  if python3 -I "$(cd "$(dirname "$0")" && pwd)/_osa_sdef.py" "$path" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    sdeffile="$tmp"; echo "dictionary source: OpenScripting API (no bundled .sdef)"
  fi
fi
if [ -z "$sdeffile" ] || [ ! -f "$sdeffile" ]; then
  echo "no scripting dictionary found. This is not proof the app is unscriptable: try a simple tell application command, else use System Events UI scripting (ui_find.sh, click_menu.sh) or the app's CLI" >&2
  exit 1
fi
[ "$mode" = "--raw" ] && { cat "$sdeffile"; exit 0; }
python3 -I - "$sdeffile" "$mode" <<'PY'
import sys, xml.etree.ElementTree as ET
f, mode = sys.argv[1], sys.argv[2]
try:
    root = ET.parse(f).getroot()
except ET.ParseError:
    # some sdefs use XInclude/DOCTYPE entities; fall back to a tolerant read
    import re
    txt = open(f, encoding="utf-8", errors="ignore").read()
    txt = re.sub(r"<!DOCTYPE[^>]*>", "", txt)
    root = ET.fromstring(txt)
for suite in root.iter("suite"):
    print(f"\n## suite: {suite.get('name')}")
    if mode in ("--commands", "--all"):
        for c in suite.findall("command"):
            params = [p.get("name") for p in c.findall("parameter")]
            dp = c.find("direct-parameter")
            sig = c.get("name") + (" <direct>" if dp is not None else "") + "".join(f" {p} …" for p in params)
            print(f"  command: {sig} — {c.get('description','')}")
    if mode in ("--classes", "--all"):
        for k in suite.findall("class") + suite.findall("class-extension"):
            name = k.get("name") or ("extends " + str(k.get("extends")))
            props = [p.get("name") for p in k.findall("property")]
            elems = [e.get("type") for e in k.findall("element")]
            print(f"  class: {name} — {k.get('description','')}")
            if props: print(f"    properties: {', '.join(props)}")
            if elems: print(f"    elements: {', '.join(elems)}")
        for e in suite.findall("enumeration"):
            print(f"  enum: {e.get('name')} = {', '.join(x.get('name') for x in e.findall('enumerator'))}")
PY

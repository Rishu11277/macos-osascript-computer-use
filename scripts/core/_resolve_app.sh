# Sourced by helpers. resolve_app "<name|bundle id|/path/App.app>" -> sets APP_PATH and APP_BID, or exits 1.
# Looks the app up ON DISK first, so AppleScript never shows a "Where is <app>?" chooser for unknown names.
resolve_app() {
  local q="$1" p=""
  [ -z "$q" ] && { echo "app name required" >&2; exit 2; }
  case "$q" in -*) echo "invalid app name: $q" >&2; exit 2;; esac
  if [ -d "$q" ] && [ "${q%.app}" != "$q" -o "${q%.app/}" != "$q" ]; then p="${q%/}"
  else
    for d in /Applications /System/Applications /System/Applications/Utilities /System/Library/CoreServices /Applications/Utilities "$HOME/Applications"; do
      [ -d "$d/$q.app" ] && { p="$d/$q.app"; break; }
    done
    if [ -z "$p" ]; then
      # bundle id or display name via Spotlight (no UI)
      p=$(mdfind "kMDItemCFBundleIdentifier == '${q//\'/}'" 2>/dev/null | grep '\.app$' | head -1)
      [ -z "$p" ] && p=$(mdfind "kMDItemContentType == 'com.apple.application-bundle' && kMDItemDisplayName == '${q//\'/}'" 2>/dev/null | head -1)
    fi
  fi
  [ -n "$p" ] && [ -d "$p" ] || { echo "app not found on disk: $q" >&2; exit 1; }
  APP_PATH="$p"
  APP_BID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$p/Contents/Info.plist" 2>/dev/null)
  [ -n "$APP_BID" ] || { echo "no bundle identifier for $p" >&2; exit 1; }
}

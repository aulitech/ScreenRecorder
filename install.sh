#!/bin/sh
# Puts Screen Recorder where it lives, from this folder:
#   ~/Library/Application Support/Recording/   start.sh, stop.sh — what the app runs
#   ~/Applications/Screen Recorder.app         the app, with its camera icon
#   ~/Library/Services/                        the two hotkey Quick Actions
# and sets the hotkeys and the Dock icon. Safe to run again.
set -eu
cd "$(dirname "$0")"

# Change these to move the hotkeys: @ Command, ~ Option, ^ Control, $ Shift.
START_KEY='@~^r'
STOP_KEY='@~^s'

support="$HOME/Library/Application Support/Recording"
rebuilt=0
app="$HOME/Applications/Screen Recorder.app"

# 1. The commands the app runs. Changing these never needs permission again.
mkdir -p "$support"
install -m 755 scripts/start.sh scripts/stop.sh "$support/"
echo "Installed start.sh and stop.sh"

# 2. The app — rebuilt only when its source has changed: macOS ties the
#    screen-recording permission to the exact app, so a rebuilt one has to be
#    turned on again in System Settings.
if [ -d "$app" ] && osadecompile "$app/Contents/Resources/Scripts/main.scpt" | diff -wBq - app/recorder.applescript >/dev/null; then
  echo "Screen Recorder.app is up to date"
else
  tmp=$(mktemp -d)
  iconset="$tmp/camera.iconset"
  mkdir "$iconset"
  for s in 16 32 128 256 512; do
    sips -z "$s" "$s" icon/camera.png --out "$iconset/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z "$d" "$d" icon/camera.png --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns -o "$tmp/camera.icns" "$iconset"
  mkdir -p "$HOME/Applications"
  rm -rf "$app"
  osacompile -s -o "$app" app/recorder.applescript
  cp "$tmp/camera.icns" "$app/Contents/Resources/applet.icns"
  # osacompile also puts the AppleScript scroll in an asset catalogue and names
  # it, and macOS — the Dock's icon cache most stubbornly — takes that over
  # applet.icns. So the name goes, and the catalogue with it.
  plutil -remove CFBundleIconName "$app/Contents/Info.plist"
  rm -f "$app/Contents/Resources/Assets.car"
  codesign --force -s - "$app" 2>/dev/null
  touch "$app"
  rebuilt=1
  rm -rf "$tmp"
  echo "Built Screen Recorder.app. Turn it on (off and on again, if it is listed) under"
  echo "System Settings › Privacy & Security › Screen & System Audio Recording."
  open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
fi

# 3. The hotkeys: two Quick Actions that go through the app, so they use its permission.
mkdir -p "$HOME/Library/Services"
# Replaced only when changed: an app already running keeps the copy it read at
# launch, and a hotkey whose Quick Action was swapped under it stops working in
# that app until it is restarted.
for w in services/*.workflow; do
  dest="$HOME/Library/Services/$(basename "$w")"
  if ! diff -rq "$w" "$dest" >/dev/null 2>&1; then
    rm -rf "$dest"
    cp -R "$w" "$HOME/Library/Services/"
  fi
done
status() {
  printf '{ "key_equivalent" = "%s"; "enabled_context_menu" = 1; "enabled_services_menu" = 1; "presentation_modes" = { ContextMenu = 1; ServicesMenu = 1; }; }' "$1"
}
defaults write pbs NSServicesStatus -dict-add '"(null) - Start Screen Recording - runWorkflowAsService"' "$(status "$START_KEY")"
defaults write pbs NSServicesStatus -dict-add '"(null) - Stop Screen Recording - runWorkflowAsService"' "$(status "$STOP_KEY")"
/System/Library/CoreServices/pbs -flush
/System/Library/CoreServices/pbs -update
echo "Installed the hotkeys"

# 4. The Dock icon, added once — and, after a rebuild, its tile renewed: the
#    Dock keeps details of the app in the tile, and goes on drawing the icon it
#    found there however the app has changed.
if [ "$rebuilt" = 1 ] && defaults read com.apple.dock persistent-apps | grep -q 'Screen%20Recorder.app'; then
  tmp=$(mktemp -d)
  defaults export com.apple.dock "$tmp/dock.plist"
  python3 - "$tmp/dock.plist" <<'PY'
import plistlib, sys
p = sys.argv[1]
d = plistlib.load(open(p, 'rb'))
for t in d['persistent-apps']:
    f = t.get('tile-data', {}).get('file-data', {})
    if f.get('_CFURLString', '').rstrip('/').endswith('Screen%20Recorder.app'):
        t['tile-data'] = {'file-data': f}
plistlib.dump(d, open(p, 'wb'))
PY
  defaults import com.apple.dock "$tmp/dock.plist"
  rm -rf "$tmp"
  killall Dock
fi

if ! defaults read com.apple.dock persistent-apps | grep -q 'Screen%20Recorder.app'; then
  url="file://$(printf '%s' "$app" | sed 's/ /%20/g')/"
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$url</string><key>_CFURLStringType</key><integer>15</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
  killall Dock
  echo "Added Screen Recorder to the Dock"
fi

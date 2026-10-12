# Screen Recorder

Records the Mac's screen and the sound it plays, for somebody who works the Mac by dwell click. The Screenshot toolbar does not answer Dwell Control's clicks; this needs no toolbar at all.

- **Dwell on the camera in the Dock** to start. For as long as it records, the camera in its icon fades to a dull red over three seconds and back to white over three, without moving.
- **Dwell on it again** to stop. The video is saved to Desktop › screenshots as `Screen Recording <date> at <time>.mov`.
- **Hotkeys:** ⌃⌥⌘R starts, ⌃⌥⌘S stops.

It records whichever display macOS calls the main one.

## Install

```sh
./install.sh
```

Run it again after changing anything here. The first time — and whenever `app/recorder.applescript` has changed — it builds the app, and the app then has to be turned on under System Settings › Privacy & Security › Screen & System Audio Recording (the script opens that page). Changes to anything else need no permission.

## What is where

| Here | Installed to | What it is |
|---|---|---|
| `app/recorder.applescript` | `~/Applications/Screen Recorder.app` | The Dock app: a stay-open AppleScript applet. It starts, glows while it records (`setApplicationIconImage`, a frame every tenth of a second, chosen by the clock) and stops |
| `scripts/start.sh`, `scripts/stop.sh` | `~/Library/Application Support/Recording/` | What the app runs: `screencapture -v -A`, and `SIGINT` to stop it — which is what makes it finish the file rather than abandon it |
| `icon/icon.js` | `~/Library/Application Support/Recording/frames/` | The glow: 60 frames of the camera fading from white to dull red and back (`osascript -l JavaScript icon/icon.js frames/ 60`). The app plays whatever frames are there, over six seconds |
| `icon/icon.js`, `icon/camera.png` | inside the app | The camera icon, and the script that drew it (`osascript -l JavaScript icon/icon.js out.png`) |
| `services/*.workflow` | `~/Library/Services/` | The two hotkeys, as Quick Actions. They go through the app, so they use its permission |

**Why the commands and the glow are outside the app:** macOS gives screen-recording permission to the exact app it was granted to. Rebuilt, the app is a different app and has to be turned on again; a script it runs, or a picture it shows, can change freely.

**The hotkeys** are set in `install.sh` (`START_KEY`, `STOP_KEY`). They can also be changed under System Settings › Keyboard › Keyboard Shortcuts › Services.

They are Quick Actions, so the app in front is what hears them. That has two consequences:
- **Not every app hears them.** An app that does not take part in the Services menu does not. Finder and most Apple apps do.
- **An app already running keeps the copy it read at launch.** If a Quick Action is replaced while an app is open, the hotkey stops working in that app until it is restarted. `install.sh` replaces one only when it has changed.

## License

MIT — see [LICENSE](LICENSE).

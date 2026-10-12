#!/bin/sh
# Run by ~/Applications/Start Recording.app. Records the main display and the
# sound the Mac itself plays (-A), until Stop Recording sends it SIGINT, which
# saves the file. Kept here rather than inside the app, so changing what it
# does never changes the app macOS has given screen-recording permission to.
pgrep -x screencapture >/dev/null && exit 0
dir="$HOME/Desktop/screenshots"
mkdir -p "$dir"
f="$dir/Screen Recording $(date '+%Y-%m-%d at %H.%M.%S').mov"
screencapture -x -v -A "$f" >/dev/null 2>&1 &

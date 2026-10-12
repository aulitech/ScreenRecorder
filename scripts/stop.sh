#!/bin/sh
# Run by ~/Applications/Screen Recorder.app. SIGINT is what makes screencapture
# finish the file rather than abandon it; waits until it has.
pkill -INT -x screencapture || exit 0
for i in $(seq 1 50); do pgrep -x screencapture >/dev/null || exit 0; sleep 0.2; done

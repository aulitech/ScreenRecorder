-- Screen Recorder: one Dock icon, for somebody who works the Mac by dwell.
-- Dwell on it to start recording the screen and the Mac's own sound; it keeps
-- bouncing in the Dock for as long as it records; dwell on it again to stop,
-- which saves the video to Desktop › screenshots. What it runs is in
-- ~/Library/Application Support/Recording (start.sh, stop.sh), so changing what
-- it does never changes this app and macOS never asks for permission again.
use AppleScript version "2.4"
use framework "AppKit"
use scripting additions

property recording : false

on scriptPath(name)
	return quoted form of (POSIX path of (path to application support folder from user domain) & "Recording/" & name)
end scriptPath

on isRecording()
	try
		do shell script "pgrep -x screencapture"
		return true
	on error
		return false
	end try
end isRecording

-- One bounce, asked for every second while it records — see `idle`. A
-- frontmost app cannot ask for attention, so one in front steps back first.
-- It was one critical request, meant to bounce until the app was brought
-- forward; asked for while the app was still in front, it was ignored, and
-- nothing asked again.
on bounce()
	set app_ to current application's NSApplication's sharedApplication()
	if (app_'s isActive()) as boolean then app_'s hide:(missing value)
	app_'s requestUserAttention:(current application's NSInformationalRequest)
end bounce

on startRecording()
	do shell script scriptPath("start.sh")
	delay 1
	if not isRecording() then
		display notification "It could not start. Check that Screen Recorder is on under Privacy & Security › Screen & System Audio Recording." with title "Screen Recorder"
		tell me to quit
		return
	end if
	set recording to true
	bounce()
end startRecording

on stopRecording()
	set recording to false
	do shell script scriptPath("stop.sh")
	display notification "Saved to Desktop › screenshots." with title "Recording stopped"
	tell me to quit
end stopRecording

on run
	startRecording()
end run

-- A dwell on the icon while it is running.
on reopen
	if recording then
		stopRecording()
	else
		startRecording()
	end if
end reopen

-- Every second: a bounce while it records, and a recording that ended by
-- itself ends the bouncing too.
on idle
	if recording then
		if not isRecording() then
			set recording to false
			display notification "The recording stopped by itself. Anything recorded is in Desktop › screenshots." with title "Screen Recorder"
			tell me to quit
		else
			bounce()
		end if
	end if
	return 1
end idle

on quit
	if recording then do shell script scriptPath("stop.sh")
	continue quit
end quit

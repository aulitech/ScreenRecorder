-- Screen Recorder: one Dock icon, for somebody who works the Mac by dwell.
-- Dwell on it to start recording the screen and the Mac's own sound; its
-- camera glows, fading to a dull red and back, for as long as it records; dwell
-- on it again to stop, which saves the video to Desktop › screenshots. What it
-- runs and the glow it plays are in ~/Library/Application Support/Recording
-- (start.sh, stop.sh, frames/), so changing either never changes this app and
-- macOS never asks for permission again.
use AppleScript version "2.4"
use framework "AppKit"
use scripting additions

property recording : false
-- The glow: frames spread over one cycle — white to dull red in three
-- seconds, and back in three — chosen by the clock rather than counted, so the
-- cycle stays six seconds however late a tick comes.
property frames : {}
property cycle : 6
property startedAt : 0
-- When the recording was last checked on.
property checkedAt : 0

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

-- Whatever frames are in Recording/frames, in name order. It bounced, which
-- was distracting; it glows in place now, and the frames are outside the app
-- so the glow can change without the app changing.
on loadFrames()
	set dir to POSIX path of (path to application support folder from user domain) & "Recording/frames/"
	set frames to {}
	try
		set names to paragraphs of (do shell script "ls " & quoted form of dir & " | grep '[.]png$'")
	on error
		return
	end try
	repeat with n in names
		set img to (current application's NSImage's alloc()'s initWithContentsOfFile:(dir & n))
		if img is not missing value then set end of frames to img
	end repeat
end loadFrames

on now()
	return (current application's NSDate's timeIntervalSinceReferenceDate()) as real
end now

-- The frame for this moment of the cycle, on the Dock icon.
on glow()
	set c to count of frames
	if c is 0 then return
	set elapsed to (now() - startedAt) mod cycle
	set i to ((elapsed / cycle * c) div 1) + 1
	if i > c then set i to c
	current application's NSApplication's sharedApplication()'s setApplicationIconImage:(item i of frames)
end glow

on startRecording()
	do shell script scriptPath("start.sh")
	delay 1
	if not isRecording() then
		display notification "It could not start. Check that Screen Recorder is on under Privacy & Security › Screen & System Audio Recording." with title "Screen Recorder"
		tell me to quit
		return
	end if
	set recording to true
	loadFrames()
	set startedAt to now()
	set checkedAt to startedAt
	glow()
end startRecording

on stopRecording()
	set recording to false
	set frames to {}
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

-- Every tenth of a second, the next frame of the glow while it records; and
-- every second a check that it still is, so a recording that ended by itself
-- ends the glow too.
on idle
	if not recording then return 1
	if now() - checkedAt ≥ 1 then
		set checkedAt to now()
		if not isRecording() then
			set recording to false
			set frames to {}
			display notification "The recording stopped by itself. Anything recorded is in Desktop › screenshots." with title "Screen Recorder"
			tell me to quit
			return 1
		end if
	end if
	glow()
	return 0.1
end idle

on quit
	if recording then do shell script scriptPath("stop.sh")
	-- Pictures are not something an applet can keep between runs.
	set frames to {}
	continue quit
end quit

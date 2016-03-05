#Quick Silver scripts to move poker tables around

# Introduction #

Another feature that one typically needs when multitabling  is the possibility to stack all tables in one position (say the upper left corner) and then hit a (combination of) keys when something interesting is happening on one of the tables to move it somewhere away from the other 45 tables you have opened... ;-)

This is something easily done with apple scripts. We need however a way to associate an hot key with an apple script. QuickSilver (a "must have" open source application) allows one to do exactly that (http://quicksilver.en.softonic.com/mac)

# Details #

Create and edit to your tastes the following 5 apple scripts:

**Move ALL to UP LEFT.scpt**
```
-- Get the front-most application in System Events (Is there a better way?)
tell application "System Events"
	set _everyProcess to every process
	repeat with n from 1 to count of _everyProcess
		set _frontMost to frontmost of item n of _everyProcess
		if _frontMost is true then set _frontMostApp to process n
	end repeat
	
	
	set _everyWindow to every window of _frontMostApp
	repeat with _windowOne in _everyWindow
		set position of _windowOne to {48, 22}
	end repeat
	return
	
end tell
```

**Move to UP RIGHT.scpt**
```
-- Get the front-most application in System Events (Is there a better way?)
tell application "System Events"
	set _everyProcess to every process
	repeat with n from 1 to count of _everyProcess
		set _frontMost to frontmost of item n of _everyProcess
		if _frontMost is true then set _frontMostApp to process n
	end repeat
	
	set _windowOne to window 1 of _frontMostApp
	set _position to position of _windowOne
	(* set _size to size of _windowOne *)
	
	set position of _windowOne to {647, 22}
	
	return
	
end tell
```

**Move to LOW LEFT.scpt**
```
-- Get the front-most application in System Events (Is there a better way?)
tell application "System Events"
	set _everyProcess to every process
	repeat with n from 1 to count of _everyProcess
		set _frontMost to frontmost of item n of _everyProcess
		if _frontMost is true then set _frontMostApp to process n
	end repeat
	
	set _windowOne to window 1 of _frontMostApp
	set _position to position of _windowOne
	(* set _size to size of _windowOne *)
	
	set position of _windowOne to {647, 22}
	
	return
	
end tell
```

**Move to LOW RIGHT.scpt**
```
-- Get the front-most application in System Events (Is there a better way?)
tell application "System Events"
	set _everyProcess to every process
	repeat with n from 1 to count of _everyProcess
		set _frontMost to frontmost of item n of _everyProcess
		if _frontMost is true then set _frontMostApp to process n
	end repeat
	
	set _windowOne to window 1 of _frontMostApp
	set _position to position of _windowOne
	set _size to size of _windowOne
	
	set position of _windowOne to {647, 333}
	return
	
end tell
```

**Move to UP LEFT.scpt**
```
-- Get the front-most application in System Events (Is there a better way?)
tell application "System Events"
	set _everyProcess to every process
	repeat with n from 1 to count of _everyProcess
		set _frontMost to frontmost of item n of _everyProcess
		if _frontMost is true then set _frontMostApp to process n
	end repeat
	
	set _windowOne to window 1 of _frontMostApp
	set _position to position of _windowOne
	set _size to size of _windowOne
	
	set position of _windowOne to {48, 22}
	--set size of _windowOne to {700, 455}
	return
	
end tell
```

Save them in a handy location. I used ~/Library/Scripts. Then configure QuickSilver custom triggers as in the picture below (picking your favorite hot keys). This should get you going.

![http://people.sissa.it/~heltai/shot.png](http://people.sissa.it/~heltai/shot.png)
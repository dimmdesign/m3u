(*
	David Miller
	http://readmeansrun.com/code/m3u
*)

set LINEBREAK to "
"
set VERSION_NUMBER to "0.1"

tell application "iTunes"
	
	try
		set p to current playlist
	on error e
		display dialog "No active playlist. Begin playing the list you wish to copy." buttons {"OK"} default button "OK" with icon 0
		return
	end try
	
	if (((special kind of p) as string) is equal to "Music") then
		display dialog "Please select a playlist other than your music library." buttons {"OK"} default button "OK" with icon 0
		return
	end if
	
	set t to none
	
	set f to {"/", "Users", (do shell script "echo $USER"), "Desktop", my sanitize(name of p)}
	set dest to my unixpath(f)
	
	set s to "mkdir " & dest
	
	try
		do shell script s
	on error e
		display dialog "Folder \"" & my sanitize(name of p) & "\" already exists on your desktop." buttons {"OK"} default button "OK" with icon 0
		return
	end try
	
	
	set loc to ""
	
	set m3u to my unixpath(f & (my sanitize(name of p) & ".m3u"))
	
	do shell script "echo '#EXTM3U' > " & m3u
	do shell script "echo '' >> " & m3u
	
	set maxindex to file tracks of p
	set maxindex to my digits(length of maxindex)
	
	set i to 1
	set buf to ""
	repeat with t in file tracks of p
		set loc to location of t
		
		set ext to "." & last item of (my split(loc, "."))
		
		if (ext is equal to ".mp3" or ext is equal to ".m4a") then
			
			set loc to quoted form of POSIX path of loc
			
			set newname to my lpad(i, "0", maxindex) & " - " & my sanitize(name of t) & ext
			set dest to my unixpath(f & newname)
			
			set cp to "cp " & loc & " " & dest
			
			do shell script "echo " & (quoted form of ("#EXTINF:" & my int(duration of t) & "," & artist of t & " - " & name of t)) & " >> " & m3u
			do shell script "echo " & (quoted form of newname) & " >> " & m3u
			do shell script "echo '' >> " & m3u
			
			set the clipboard to cp
			
			
			do shell script cp
			
			set i to i + 1
			
		end if
		
	end repeat
	
end tell



do shell script ("echo " & (quoted form of "# created by http://readmeansrun.com/code/m3u v" & VERSION_NUMBER) & " >> " & m3u)


do shell script "open " & my unixpath(f)


------------------------------

on sanitize(str)
	set buf to ""
	repeat with i in str
		if (i is not in "\\/") then
			set buf to buf & i
		end if
	end repeat
	return buf
end sanitize


on truncate(str, len)
	
	if (length of str is less than len) then
		return str
	end if
	
	
	set buf to ""
	set i to 1
	repeat while i ≤ len
		
		set buf to buf & item i of str
		
		set i to i + 1
	end repeat
	
	return buf
	
end truncate

on unixpath(paths)
	set p to ""
	set x to 0
	repeat with i in paths
		if (x is greater than 0) then
			--			set p to p & "/"
		end if
		set buf to ""
		repeat with j in i
			if (j is in {"\"", " ", "(", ")", "'", "&"}) then
				set buf to buf & "\\" & j
			else
				set buf to buf & j
			end if
		end repeat
		
		if (x is greater than 0) then
			set p to p & buf & "/"
		else
			set p to buf
		end if
		
		set x to x + 1
	end repeat
	
	set p to my truncate(p, (length of p) - 1)
	return p
	
end unixpath


(*

*)
on implode(arr, glue)
	set buf to ""
	set len to (length of arr)
	set i to 1
	
	repeat with x in arr
		set buf to buf & x
		if (i < len) then
			set buf to buf & glue
		end if
		set i to i + 1
	end repeat
	
	return buf
	
end implode

(*

*)
on indexOf(arr, needle)
	repeat with i from 1 to length of arr
		set x to item i of arr
		if (x is equal to needle) then
			return i - 1
		end if
	end repeat
	return -1
end indexOf

(*

*)
on split(str, delimiter)
	
	set str to str as string
	
	set old to AppleScript's text item delimiters
	-- set delimiters to delimiter to be used
	set AppleScript's text item delimiters to delimiter
	-- create the array
	set arr to every text item of str
	-- restore the old setting
	set AppleScript's text item delimiters to old
	-- return the result
	return arr
end split

(*
	
*)
on lpad(str, char, len)
	set buf to "" & str
	repeat while length of buf < len
		set buf to char & buf
	end repeat
	
	return buf
	
end lpad

(*

*)
on enquote(str)
	set buf to ""
	repeat with i in str
		if (i is in "\"\\") then
			set buf to buf & "\\" & i
		else
			set buf to buf & i
		end if
	end repeat
	return "\"" & buf & "\""
end enquote

(*
	x - 
	y - 
*)
on max(x, y)
	if (x is greater than or equal to y) then
		return x
	end if
	return y
end max

(*
	x - 
	y - 
*)
on min(x, y)
	if (x is less than or equal to y) then
		return x
	end if
	return y
end min

(*
	@param x - int
	@return int - the number of digits required to represent x
*)
on digits(x)
	
	if (x is less than 0) then
		set x to 0 - x
	end if
	
	set buf to "" & x
	set buf to every item of buf
	
	return my max((length of buf), 1)
	
end digits

(*
	@param d - number to be converted to integer
*)
on int(d)
	
	set r to my roundOff(d, 0)
	set r to first item of my split(r, ".")
	return r as integer
	
end int

(*
	@param n - number to be rounded
	@param d - precision (# of decimals)
*)
on roundOff(n, d) -- .5 away from zero
	set p to 10 ^ d
	set nShift to n * ((10 ^ 0.5) ^ 2) * p
	return (nShift div 5 - nShift div 10) / p
end roundOff
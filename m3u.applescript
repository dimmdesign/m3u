(*
  David Miller
  http://readmeansrun.com/code/m3u
*)

set LINEBREAK to "
"
set VERSION_NUMBER to "0.1"


-- the number of songs for which the user should be prompted to confirm they want to export
set MAX_LENGTH_CHECK to 100

-- the file types to export
set FILE_EXTENSIONS to {".mp3", ".m4a"}

tell application "iTunes"
	
	-- choose a folder
	set targetFolder to choose folder with prompt "Choose of destination for the exported playlist items"
	
	try
		set p to (get view of front window) -- gets the selected playlist rather than the current playlist
	on error e
		display dialog "No active playlist. Begin playing the list you wish to copy." buttons {"OK"} default button "OK" with icon 0
		return
	end try
	
	if (((special kind of p) as string) is equal to "Music") then
		display dialog "Please select a playlist other than your music library." buttons {"OK"} default button "OK" with icon 0
		return
	end if
	
	set t to none
	
	set maxindex to file tracks of p
	
	if (length of maxindex is greater than or equal to MAX_LENGTH_CHECK) then
		activate
		set r to display dialog "Your playlist " & (quoted form of ((name of p) as string)) & " contains " & (length of maxindex) & " tracks. Are you sure you wish to export it?" with icon caution buttons {"Cancel", "Export to M3U"} default button 2 giving up after 10
		if (button returned of r is equal to "Cancel") then
			return
		end if
		
	end if
	
	set maxindex to my digits(length of maxindex)
	
	
	set f to {get POSIX path of targetFolder, my sanitize(name of p)}
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
	
	set i to 1
	set buf to ""
	repeat with t in file tracks of p
		set loc to location of t
		
		set ext to "." & last item of (my split(loc, "."))
		
		if (FILE_EXTENSIONS contains ext) then
			
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
(* generic subroutines follow *)


(*
  #todo

  @param str
  @return str
*)
on sanitize(str)
	set buf to ""
	repeat with i in str
		if (i is not in "\\/") then
			set buf to buf & i
		end if
	end repeat
	return buf
end sanitize


(*
  

  @param str (string) - the string to be truncated
  @param len (int) - the maximum length of the string
  @return string
*)
on truncate(str, len)
	
	if (length of str is less than len) then
		return str
	end if
	
	set buf to ""
	set i to 1
	repeat while i � len
		set buf to buf & item i of str
		set i to i + 1
	end repeat
	
	return buf
	
end truncate

(*
  
  @param paths ()
  @return string
*)
on unixpath(paths)
	set p to ""
	set x to 0
	repeat with i in paths
		if (x is greater than 0) then
			--      set p to p & "/"
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
  Create a string representation of a list 
  
  @param arr (list) - the list to be serialized to a string
  @param glue (string) - the string to be inserted between each item of the list
  @return string
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
  Calculate the index of an item in a list

  @param array (list)
  @param needle (mixed)
  @return int - the index of the needle, or -1 if it's not found
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
  Convert a string into a list given a string/character that should be used as the separator

  @param str (string)
  @param delimiter (string) - 
  @return list
*)
on split(str, delimiter)
	
	set str to str as string
	set old to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set arr to every text item of str
	set AppleScript's text item delimiters to old
	return arr
end split

(*
  #todo

  @param str (string)
  @param char (char) - the character to be inserted 
  @param len (int) - the number of characters that should be contained in the string after being padded
  @return string
*)
on lpad(str, char, len)
	set buf to "" & str
	repeat while length of buf < len
		set buf to char & buf
	end repeat
	
	return buf
	
end lpad

(*
  #todo

  @param str (string) - 
  @return string
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
  Return the maximum of two numbers

  @param x (num) - 
  @param y (num) - 
  @return num
*)
on max(x, y)
	if (x is greater than or equal to y) then
		return x
	end if
	return y
end max

(*
  Return the minimum of two numbers

  @param x (num) - 
  @param y (num) - 
  @return num
*)
on min(x, y)
	if (x is less than or equal to y) then
		return x
	end if
	return y
end min

(*
  Calculate the number of characters required to represent an integer in string format

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
  Convert a number to an integer

  @param d - number to be converted to integer
  @return int
*)
on int(d)
	
	set r to my roundOff(d, 0)
	set r to first item of my split(r, ".")
	return r as integer
	
end int

(*
  #todo

  @param n - number to be rounded
  @param d - precision (# of decimals)
  @return float
*)
on roundOff(n, d) -- .5 away from zero
	set p to 10 ^ d
	set nShift to n * ((10 ^ 0.5) ^ 2) * p
	return (nShift div 5 - nShift div 10) / p
end roundOff
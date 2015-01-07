# This is based on the Export With HandBrake Script found at:
#     http://www.niedling.info/ralf/projekte/verschiedenes/eyetv-applescript/eyetv-handbrake_en.html
#
# CK: This exporter provides  finer control of the encoder. Most importantly, I can preserve AC3 audio tracks. 
#
# Also, I have enhanced it so that it maintains as much of the metadata as possible. I use AtomicParsley to encode
# metadata into the exported .mp4 file
#
# Dependencies:
# - HandBrakeCLI (unless using Turbo.264)
# - Turbo.264 (optional, alternative to HandbrakeCLI)
# - AtomicParsley (optional)
#

# If this property is set to true, the program is deleted once exporting is complete.
property ENABLE_PROGRAM_DELETION : false

# If this property is set to true, Turbo.264 will be used instead of HandBrakeCLI
property ENABLE_TURBO_264 : false

# To use Turbo.264, you must define a custom preset in the Turbo.264 application. Specify the name of your preset here
property TURBO_264_PRESET : "Export To Plex"

# If using Turbo.264, the script will make this many attempts to encode the file before giving up. This 
# property is necessary because Turbo.264 can only be launched as a single process, so multiple recordings may
# contend for encoding.
property TURBO_264_MAX_ATTEMPTS : 20

# only necessary if using Handbrake for encoding
property HANDBRAKE_CLI : "nice -n 10 /usr/local/bin/HandBrakeCLI"

# the encoding paramters to send to HandBrakeCLI
# from https://trac.handbrake.fr/wiki/BuiltInPresets
property HANDBRAKE_PARAMETERS : " -O -e x264  -q 20.0 -a 1,1 -E faac,copy:ac3 -B 160,160 -6 dpl2,none -R Auto,Auto -D 0.0,0.0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 -4 --decomb --loose-anamorphic --modulus 2 -m --x264-preset medium --h264-profile high --h264-level 4.1"

# enables AtomicParsley, which can write metadata to .mp4 files. Use this option if you have TV shows whose metadata cannot
# be found by Plex. This feature will only work if the target format is .mp4 or .m4v
property ENABLE_ATOMIC_PARSLEY : false

# needed to set MP4 metadata
property ATOMIC_PARSLEY_CLI : "/usr/local/bin/atomicparsley"

# if this URL is present, it will update plex. The section that needs to be updated will vary depending on your Plex Media Server configuration
property PLEX_UPDATE_URL : "http://127.0.0.1:32400/library/sections/2/refresh?turbo=1"

# all exports will be written to this path, then moved to the TARGET_PATH after export is complete
property TEMP_PATH : "/path/to/temp/files"

# all exports will be moved to this path when complete
property TARGET_PATH : "/path/to/plex/tv/library"

# if you change this setting, Turbo.264 may still output .mp4, so don't change it if using Turbo.264
property TARGET_TYPE : "mkv"
property SOURCE_TYPE : "mpg"

# log statements will be written to this file
property LOG_FILENAME : "/tmp/eyetv-export-custom.log"

# the shell scripts executed by this script will write logs as follows
property SHELL_SCRIPT_SUFFIX : " >> " & LOG_FILENAME & " 2>&1"

# this enables testing mode
property TEST_MODE : false

# this will trigger the script when a recording is finished. To do so, place this script in the path: /Library/Application Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt
on RecordingDone(recordingID)
	LoadProperties()
	
	tell application "EyeTV"
		set new_recording_id to (recordingID as integer)
		set new_recording to recording id new_recording_id
		if TEST_MODE then
			my test(new_recording)
		else
			my export_recording(new_recording)
		end if
	end tell
end RecordingDone


# this will be triggered when manually selected from the EyeTV script menu. To do so, place this script in the path: /Library/Application Support/EyeTV/Scripts/ 
on run
	LoadProperties()
	
	tell application "EyeTV"
		set selected_recordings to selection of programs window
		repeat with selected_recording in selected_recordings
			if TEST_MODE then
				my test(selected_recording)
			else
				my export_recording(selected_recording)
			end if
		end repeat
	end tell
end run

# for testing purposes only
on test(the_recording)
	write_log("Test begins")
	
	write_log("Test ends")
end test

on LoadProperties()
	set thePListPath to MyParentPath() & "Export To Plex.plist"
	
	if my file_exists(thePListPath) then
		tell application "System Events"
			tell property list file thePListPath
				tell contents
					if value of property list item "ENABLE_PROGRAM_DELETION" exists then
						set ENABLE_PROGRAM_DELETION to value of property list item "ENABLE_PROGRAM_DELETION"
					end if
					if value of property list item "ENABLE_TURBO_264" exists then
						set ENABLE_TURBO_264 to value of property list item "ENABLE_TURBO_264"
					end if
					if value of property list item "TURBO_264_PRESET" exists then
						set TURBO_264_PRESET to value of property list item "TURBO_264_PRESET"
					end if
					if value of property list item "TURBO_264_MAX_ATTEMPTS" exists then
						set TURBO_264_MAX_ATTEMPTS to value of property list item "TURBO_264_MAX_ATTEMPTS"
					end if
					if value of property list item "HANDBRAKE_CLI" exists then
						set HANDBRAKE_CLI to value of property list item "HANDBRAKE_CLI"
					end if
					if value of property list item "HANDBRAKE_PARAMETERS" exists then
						set HANDBRAKE_PARAMETERS to value of property list item "HANDBRAKE_PARAMETERS"
					end if
					if value of property list item "ENABLE_ATOMIC_PARSLEY" exists then
						set ENABLE_ATOMIC_PARSLEY to value of property list item "ENABLE_ATOMIC_PARSLEY"
					end if
					if value of property list item "ATOMIC_PARSLEY_CLI" exists then
						set ATOMIC_PARSLEY_CLI to value of property list item "ATOMIC_PARSLEY_CLI"
					end if
					if value of property list item "PLEX_UPDATE_URL" exists then
						set PLEX_UPDATE_URL to value of property list item "PLEX_UPDATE_URL"
					end if
					if value of property list item "TEMP_PATH" exists then
						set TEMP_PATH to value of property list item "TEMP_PATH"
					end if
					if value of property list item "TARGET_PATH" exists then
						set TARGET_PATH to value of property list item "TARGET_PATH"
					end if
					if value of property list item "TARGET_TYPE" exists then
						set TARGET_TYPE to value of property list item "TARGET_TYPE"
					end if
					if value of property list item "SOURCE_TYPE" exists then
						set SOURCE_TYPE to value of property list item "SOURCE_TYPE"
					end if
					if value of property list item "LOG_FILENAME" exists then
						set LOG_FILENAME to value of property list item "LOG_FILENAME"
						set SHELL_SCRIPT_SUFFIX to " >> " & LOG_FILENAME & " 2>&1"
					end if
					if value of property list item "TEST_MODE" exists then
						set TEST_MODE to value of property list item "TEST_MODE"
					end if
				end tell
			end tell
		end tell
	end if
end LoadProperties


on export_recording(the_recording)
	tell application "EyeTV"
		set recording_location to URL of the_recording as text
	end tell
	
	write_log("Exporting the recording " & recording_location)
	
	set AppleScript's text item delimiters to "."
	set recording_path to text items 1 through -2 of recording_location as string
	set AppleScript's text item delimiters to ""
	set recording_path to POSIX path of recording_path
	set input_file to recording_path & "." & SOURCE_TYPE as string
	
	set output_file to my TEMP_PATH & "/" & build_recording_name(the_recording) & "." & TARGET_TYPE as string
	write_log("Temp file location is " & output_file)
	
	if ENABLE_TURBO_264 then
		export_with_turbo_264(input_file, output_file)
	else
		export_with_handbrake(input_file, output_file)
	end if
	
	if file_exists(output_file) then
		write_log("Export complete. Post-processing the file " & output_file)
		
		tag_metadata(the_recording, output_file)
		
		set output_directory to TARGET_PATH & "/" & my build_recording_path(the_recording)
		try
			do shell script "mkdir -p " & escape_path(output_directory)
			try
				set cmd to "mv -f " & escape_path(output_file) & " " & escape_path(output_directory) & "/"
				write_log(cmd)
				do shell script cmd
				
				delete_recording(the_recording)
				
			on error
				write_log("ERROR: Could not move the file " & output_file)
			end try
		on error
			write_log("ERROR: Could not create the directory " & output_directory)
		end try
		update_plex()
		write_log("Finished post-processing file " & output_file)
	else
		write_log("ERROR: The exported file was not created! " & output_file)
	end if
	
end export_recording


#CK: Exports a recording using Turbo.264
on export_with_turbo_264(input_file, output_file)
	write_log("Exporting with Turbo.264...")
	try
		tell application "Turbo.264 HD"
			set add_success to false
			set attempt_count to 0
			repeat while (add_success is not true and attempt_count < TURBO_264_MAX_ATTEMPTS)
				if isEncoding then
					my write_log("Waiting for previous encoding job to complete...")
					repeat while isEncoding
						delay 30
					end repeat
					my write_log("Previous encoding job has completed.")
				end if
				try
					set attempt_count to attempt_count + 1
					my write_log("Initiating encoding job for " & input_file & " (Attempt #" & attempt_count & " of " & TURBO_264_MAX_ATTEMPTS & ")")
					add file POSIX path of input_file exporting as custom with custom setting TURBO_264_PRESET with destination POSIX path of output_file with replacing
					set add_success to true
				on error
					my write_log("Attempt #" & attempt_count & " to add file to turbo.264 queue failed.")
					my write_log("Error code: " & lastErrorCode)
					delay 30
				end try
			end repeat
			
			if (add_success is true) then
				encode with no error dialogs
				my write_log("Waiting for export to complete...")
				
				repeat while (isEncoding or my file_exists(output_file) is false)
					delay 1
				end repeat
			else
				my write_log("Failed to queue job for " & input_file & " after " & attempt_count & " attempts.")
			end if
		end tell
		write_log("Export complete.")
	on error
		write_log("ERROR: failed to export with Turbo.264!")
		tell application "Turbo.264 HD"
			my write_log("Error code: " & lastErrorCode)
		end tell
	end try
end export_with_turbo_264


#CK: Exports a recording using HandBrakeCLI
on export_with_handbrake(input_file, output_file)
	write_log("Exporting with HandBrake...")
	set cmd to HANDBRAKE_CLI & " -i " & escape_path(input_file) & " -o  " & escape_path(output_file) & HANDBRAKE_PARAMETERS & SHELL_SCRIPT_SUFFIX
	write_log(cmd)
	try
		do shell script cmd
		write_log("Exporting with Handbrake completed.")
	on error
		write_log("ERROR: failed to export with Handbrake!")
	end try
end export_with_handbrake


#CK: reads the XML metadata and returns only the epg info
on read_epg_info(the_recording)
	write_log("Reading XML metadata...")
	
	#find a dictionary in the same directory of the recording, with a ".eyetvp" extension
	tell application "EyeTV"
		set recording_location to URL of the_recording as text
		set AppleScript's text item delimiters to "."
		set build_recording_path to text items 1 through -3 of recording_location as string
		set AppleScript's text item delimiters to ""
		set build_recording_path to POSIX path of build_recording_path & ".eyetv"
	end tell
	
	set program_files to list folder build_recording_path without invisibles
	repeat with the_file in program_files
		if the_file ends with ".eyetvp" then
			write_log("Found XML metadata in " & the_file)
			set the_plist to POSIX path of build_recording_path & "/" & the_file
			
			tell application "System Events"
				tell property list file the_plist
					tell contents
						return value of property list item "epg info"
					end tell
				end tell
			end tell
		end if
	end repeat
end read_epg_info


#CK: uses Atomic Parsley to tag the exported file
on tag_metadata(the_recording, the_output_file)
	if ENABLE_ATOMIC_PARSLEY then
		write_log("Tagging recording with metadata")
		
		set epg_info to read_epg_info(the_recording)
		set recording_season_num to SEASONID of epg_info
		set recording_episode_num to EPISODENUM of epg_info
		
		tell application "EyeTV"
			set program_title to title of the_recording
			set the_program to program program_title
			set recording_episode to episode of the_recording
			set recording_description to description of the_recording
			set recording_station_name to station name of the_recording
		end tell
		
		set cmd to ATOMIC_PARSLEY_CLI & " " & escape_path(the_output_file) ¬
			& ¬
			" --overWrite --artist \"" & program_title & ¬
			"\" --title \"" & recording_episode & ¬
			"\" --description \"" & recording_description & ¬
			"\" --longdesc \"" & recording_description & ¬
			"\" --comment \"" & recording_description & ¬
			"\" --TVNetwork \"" & recording_station_name & ¬
			"\" --TVShowName \"" & program_title & ¬
			"\" --genre \"" & "TV Shows" & ¬
			"\""
		
		if recording_season_num is not equal to "" and recording_season_num is greater than 0 then
			set cmd to cmd & " --TVSeasonNum \"" & recording_season_num & "\""
		end if
		if recording_episode is not equal to "" then
			set cmd to cmd & " --TVEpisode \"" & recording_episode & "\""
		end if
		if recording_season_num is not equal to "" and recording_season_num is greater than 0 then
			set cmd to cmd & " --TVEpisodeNum \"" & recording_episode_num & "\""
		end if
		
		
		write_log(cmd)
		try
			do shell script cmd
			write_log("Successfully tagged metadata on " & the_output_file)
		on error
			write_log("ERROR: failed to run atomic parsley to set metadata on " & the_output_file)
		end try
		
		write_log("Finished tagging metadata.")
	end if
end tag_metadata


#CK: Tells EyeTV to delete a recording, but only if enabled by the ENABLE_PROGRAM_DELETION flag
on delete_recording(the_recording)
	if ENABLE_PROGRAM_DELETION then
		write_log("Deleting recording...")
		tell application "EyeTV"
			delete the_recording
		end tell
		write_log("Recording deleted.")
	end if
end delete_recording


#CK: sets a subdirectory for each program title
on build_recording_path(the_recording)
	set epg_info to read_epg_info(the_recording)
	set recording_season_num to SEASONID of epg_info
	
	tell application "EyeTV"
		set program_title to my CleanName(title of the_recording as text)
		set recording_year to year of (start time of the_recording as date)
	end tell
	
	if recording_season_num is not equal to "" and recording_season_num is greater than 0 then
		set directory to program_title & "/Season " & recording_season_num
	else
		set directory to program_title & "/" & recording_year
	end if
	
	return directory
end build_recording_path


#CK: modified to include recording date
on build_recording_name(the_recording)
	set epg_info to read_epg_info(the_recording)
	set recording_season_num to SEASONID of epg_info
	set recording_episode_num to EPISODENUM of epg_info
	
	tell application "EyeTV"
		set program_title to my CleanName(title of the_recording as text)
		set recording_date to (start time of the_recording) as date
		set recording_episode to my CleanName(episode of the_recording as text)
	end tell
	
	set filename to program_title & " - "
	
	if recording_season_num is not equal to "" and recording_episode_num is not equal to "" and recording_season_num is greater than 0 then
		set filename to filename & "S" & left_pad_number(recording_season_num, 2) & "E" & left_pad_number(recording_episode_num, 2)
	else
		set filename to filename & format_date(recording_date)
	end if
	
	if (recording_episode is not equal to "") then
		set filename to filename & " - " & recording_episode
	end if
	
	return filename
end build_recording_name


#CK: invoke's Plex Media Server's update URL
on update_plex()
	if PLEX_UPDATE_URL is not equal to "" then
		write_log("Updating plex ...")
		set cmd to "curl \"" & PLEX_UPDATE_URL & "\""
		write_log(cmd)
		do shell script cmd
	end if
end update_plex


#CK: Writes a message to the log file
on write_log(the_log_message)
	if LOG_FILENAME is not equal to "" then
		tell (current date) to set timestamp to short date string & space & time string & ": "
		try
			set the open_target_file to open for access POSIX path of LOG_FILENAME with write permission
			write timestamp & the_log_message & character id 10 to the open_target_file starting at eof as «class utf8» # 10 = linefeed
			close access the open_target_file
			return true
		on error
			try
				close access file target_file
			end try
			return false
		end try
	end if
end write_log


#CK determines if a file exists
on file_exists(the_filename)
	tell application "System Events" to set fileExists to exists disk item (the_filename)
end file_exists

#CK formats the date to YYYY-mm-dd
on format_date(the_date)
	set y to year of the_date
	set m to left_pad_number(month of the_date as integer, 2)
	set d to left_pad_number(day of the_date, 2)
	return y & "-" & m & "-" & d
end format_date


#CK left-pads a number with zeros
on left_pad_number(the_number, the_length)
	return text -the_length thru -1 of ("00000000000" & the_number)
end left_pad_number


on escape_path(the_path)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "/"
	set path_components to every text item of the_path
	set AppleScript's text item delimiters to oldDelimiters
	repeat with counter from 1 to count path_components
		set path_component to item counter of path_components
		set item counter of path_components to my escape_string(path_component)
	end repeat
	set AppleScript's text item delimiters to "/"
	set the_path to path_components as string
	set AppleScript's text item delimiters to oldDelimiters
	return the_path
end escape_path

property escapedChars : "!$&\"'*()/{[|;<>?` \\" & ":@#%+" # the second set was added by CK
on escape_string(the_string)
	set chars to every character of the_string
	repeat with i from 1 to length of chars
		if escapedChars contains (item i of chars as text) then
			set item i of chars to "\\" & (item i of chars as text)
		end if
	end repeat
	return every item of chars as string
end escape_string


# with thanks to http://techierambles.blogspot.com/2009/04/applescript-to-automatically-replace.html
# function for cleaning the characters from the file name

--anything in disallowedChars will be removed altogether
--this takes the precedence over replacedChars
property disallowedChars : ""

--set the list of characters you want to replace
--replacedChars will be replaced with the replacementChar
--in this case, an underscore
property replacedChars : "^
"

--set the character you'd like to use to replace the invalid 
--characters specified in replacedChars
property replacementCharacter : "_"


on CleanName(theName)
	set newName to ""
	repeat with i from 1 to length of theName
		
		--check if the character is in disallowedChars
		--remove it completely if it is
		if ((character i of theName) is in disallowedChars) then
			set newName to newName & ""
			
			--check if the character is in replacedChars
			--replace it with the replacementCharacter if it is
		else if ((character i of theName) is in replacedChars) then
			set newName to newName & replacementCharacter
			
			--if the character is not in either replacedChars or
			--disallowedChars, keep it in the file name
		else
			set newName to newName & character i of theName
			
		end if
	end repeat
	
	return newName
end CleanName

# get the parent path of the script
on MyParentPath()
	tell application "Finder"
		POSIX path of (container of (path to me) as text)
	end tell
end MyParentPath


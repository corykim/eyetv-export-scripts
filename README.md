eyetv-export-scripts
====================

Currently there is only one script available: Export To Plex.applescript. The purpose of this script is to allow EyeTV 
to export its recordings to Plex, while preserving as much metadata as possible. To install this script:

1. Open the script with the AppleScript Editor

2. Configure the properties and dependencies as described in the following sections.

3. Save the script to the location: 
  ...
	   /Library/Application Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt
  ...

  Alternatively, you can save the script to the location:
  ...
    /Library/Application Support/EyeTV/Scripts/Export To Plex.scpt
  ...    
  then create a *hard* link to:
  ...
    /Library/Application Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt
  ...
  using the command:
  ...
    ln /Library/Application\ Support/EyeTV/Scripts/Export\ To\ Plex.scpt  \
     /Library/Application\ Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt
  ...

  If you go this route, you need to create a _hard_ link (ln) rather than a symbolic link (ln -s), or the script will
  not be recognized as a triggered script.

4. You should now have a compiled version of this script that is ready to handle any newly completed recordings.

5. Restart EyeTV so that it discovers the change.


Dependencies
-------------
This script has some dependencies in order to run.

* In order to transcode the MPEG2 recording files to MP4 format, you will need either HandbrakeCLI or a Turbo.264.

  - HandBrakeCLI is a command-line utility that incorporates most of the functions of the Handbrake application.
    It is available at: http://handbrake.fr/downloads2.php

  - This script assumes the CLI to be installed at the location "/usr/local/bin/HandBrakeCLI". You can change this
    setting by modifying the property "HANDBRAKE_CLI"

  - If you have a Turbo.264, you can enable support for this program by changing the property "ENABLE_TURBO_264" to 
  	"true". You will also need to create a custom preset in the Turbo.264 application that will be used by this script
  	to export the recordings. The default name of the custom preset is "Export To Plex", but you can create any custom
  	preset and supply its name in the property "TURBO_264_PRESET".

* The script uses Atomic Parsley (http://atomicparsley.sourceforge.net) to set metadata on the exported file. The
  script expects this program to be installed at the location "/usr/local/bin/atomicparsley". You can specify a 
  different location by setting the property "ATOMIC_PARSLEY_CLI".

* The script uses ASObjC Runner (http://www.macosxautomation.com/applescript/apps/runner_vanilla.html) to read EyeTV's
  metadata. 


Properties
----------
* ENABLE_PROGRAM_DELETION: if set to true, the script will delete the recording from EyeTV once it is successfully
  exported. IF a recording is not successfully exported, the recording will remain in EyeTV.

* PLEX_UPDATE_URL: if given a value, the script will cause Plex to update a library. The thing you are mostly going to
  need to change is the section number:

  	http://127.0.0.1:32400/library/sections/2/refresh?turbo=1

  To determine the section number on your Plex server, launch the management UI, view the TV library that you are going
  to import these recordings into, and take note of the number after "/section/" in your browser's location bar.	

* TEMP_PATH: In order to avoid having Plex index an incompletely tagged recording, we use a temporary directory for 
  writing the export and applying the metadata. This directory should be writable by the user account running EyeTV,
  and should not be monitored by Plex at all.

* TARGET_PATH: The directory that Plex will be looking for your recordings. This directory must be writable by the 
  account running EyeTV.

* TARGET_TYPE: For HandbrakeCLI, you can change the container type to .mkv or something else. It doesn't appear that
  Turbo.264 will allow you to use a container other than .mp4.

* SOURCE_TYPE: The source type that is being recorded by EyeTV. You should not need to change this.

* LOG_FILENAME: The file to which all log information will be written. This file should be writable by the account that
  runs EyeTV.

* SHELL_SCRIPT_SUFFIX: This script runs a number of shell commands, such as HandbrakeCLI and AtomicParsley. The default
  suffix causes any commands to write their STDOUT and STDERR to the LOG_FILENAME.  

* TEST_MODE: If set to "true", the script will execute the test() function rather than the export_recording() function.
  Use this if you need to debug a particular part of the script without modifying the main code.


Configuring Handbrake
---------------------
* Install HandbrakeCLI as described in "Dependencies".

* You must define a preset for HandbrakeCLI using the property "HANDBRAKE_PARAMETERS". The default properties will
  output high quality video and preserve AC3 streams.

* Note that the property "HANDBRAKE_CLI" includes the "nice" command. If you don't have nice installed, or don't want
  to use nice, then remove the portion of the command "nice -n -10".


Configuring Turbo.264
---------------------
* Make sure Turbo.264 is installed and working on your machine.

* Create a custom preset in the Turbo.264 application. In my case, I prefer to export recordings using 1080p and
  preserving the AC3 tracks. You can create any preset that you like by manually specifying a file to export, then
  choosing "Edit" in the "Format" drop-down.

* Configure the following properties as needed:
  - ENABLE_TURBO_264: 		Set this to "true"
  - TURBO_264_PRESET:		Set this to the name of the preset that you created in the previous step.
  - TURBO_264_MAX_ATTEMPTS	Turbo.264 has an unusual trait that it gets confused when recordings are added at the same
  							time, and also the app does not allow additional files to be added to the queue while a
  							transcode is in progress. As a result, the script must make multiple attempts to transcode
  							a recording. The maximum number of attempts before the script exits is defined with this
  							property.


Acknowledgements
----------------
This script was based initially on a Handbrake export script written by Ralf Niedling.
The original script is available at: 

	http://www.niedling.info/ralf/projekte/verschiedenes/eyetv-applescript/eyetv-handbrake_en.html

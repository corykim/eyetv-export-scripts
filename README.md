eyetv-export-scripts
====================

Currently there is only one script available: Export To Plex.applescript. The purpose of this script is to allow EyeTV 
to export its recordings to Plex, while preserving as much metadata as possible. To install this script:

1. Open the script with the AppleScript Editor.

2. Configure the properties and dependencies as described in the following sections.

3. Save the script to the location: 

        /Library/Application Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt

  Alternatively, you can save the script to the location:


        /Library/Application Support/EyeTV/Scripts/Export To Plex.scpt

  then create a *hard* link to:

        /Library/Application Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt

  using the command:

        ln /Library/Application\ Support/EyeTV/Scripts/Export\ To\ Plex.scpt  \
           /Library/Application\ Support/EyeTV/Scripts/TriggeredScripts/RecordingDone.scpt

  If you go this route, you need to create a _hard_ link (ln) rather than a symbolic link (ln -s), or the script will
  not be recognized as a triggered script.

4. You should now have a compiled version of this script that is ready to handle any newly completed recordings.

5. Restart EyeTV so that it discovers the change.


Dependencies
-------------
This script has some dependencies in order to run.

* If you want to transcode the MPEG2 recording files to MP4 format, you will need either HandbrakeCLI or a Turbo.264.

  - HandBrakeCLI is a command-line utility that incorporates most of the functions of the Handbrake application.
    It is available at: http://handbrake.fr/downloads2.php

  - This script assumes the CLI to be installed at the location "/usr/local/bin/HandBrakeCLI". You can change this
    setting by modifying the property "HANDBRAKE_CLI"

  - If you have a Turbo.264, you can enable support for this program by changing the property "ENABLE_TURBO_264" to 
  	"true". *You will also need to uncomment the code inside the function "export_with_turbo_264".* Then you need to create
    a custom preset in the Turbo.264 application that will be used by this script
  	to export the recordings. The default name of the custom preset is "Export To Plex", but you can create any custom
  	preset and supply its name in the property "TURBO_264_PRESET".


* Optionally, the script uses Atomic Parsley (http://atomicparsley.sourceforge.net) to set metadata on the exported file. This is useful if Plex is unable to lookup the metadata of the file based on the filename. This feature only works with .mp4 and .m4v files.

  - To enable Atomic Parsley, set the property “ENABLE_ATOMIC_PARSLEY” to true.

  - The script expects this program to be installed at the location "/usr/local/bin/atomicparsley". You can specify a 
  different location by setting the property "ATOMIC_PARSLEY_CLI".


Properties
----------
(see also Externalizing Properties below)

* ENABLE_TRANSCODE: if set to true, the script will transcode using either HandBrakeCLI or Turbo.264, as specified in the respective properties. If set to false, the script will copy and rename the existing EyeTV recording, moving the script to the expected Plex location and renaming according to Plex naming conventions.

* TARGET_PATH: The directory that Plex will be looking for your recordings. This directory must be writable by the 
  account running EyeTV. 

Note: This must be an absolute path. Do not begin this path with “~”.

* ENABLE_PROGRAM_DELETION: if set to true, the script will delete the recording from EyeTV once it is successfully
  exported. IF a recording is not successfully exported, the recording will remain in EyeTV.

* PLEX_UPDATE_URL: if given a value, the script will cause Plex to update a library. The thing you are mostly going to
  need to change is the section number:

  	http://127.0.0.1:32400/library/sections/2/refresh?turbo=1

  To determine the section number on your Plex server, launch the management UI, view the TV library that you are going
  to import these recordings into, and take note of the number after "/section/" in your browser's location bar.	

* TEMP_PATH: In order to avoid having Plex index an incompletely transcoded and tagged recording, we use a temporary directory for writing the export and applying the metadata. This directory should be writable by the user account running EyeTV, and should not be monitored by Plex at all. 

Note: This must be an absolute path. Do not begin this path with “~”.

* TARGET_TYPE: For HandbrakeCLI, you can change the container type to .mkv or something else. It doesn't appear that
  Turbo.264 will allow you to use a container other than .mp4.

* SOURCE_TYPE: The source type that is being recorded by EyeTV. You should not need to change this.

* LOG_FILENAME: The file to which all log information will be written. This file should be writable by the account that
  runs EyeTV. 

Note: This must be an absolute path. Do not begin this path with “~”.

* SHELL_SCRIPT_SUFFIX: This script runs a number of shell commands, such as HandbrakeCLI and AtomicParsley. The default
  suffix causes any commands to write their STDOUT and STDERR to the LOG_FILENAME.  

* TEST_MODE: If set to "true", the script will execute the test() function rather than the export_recording() function.
  Use this if you need to debug a particular part of the script without modifying the main code.


Externalizing Properties
---------------------
You can externalize all of the properties in a .plist file, so that you don’t have to edit the script to customize your settings.

To do this, copy the “Export To Plex.plist.example” file to “Export To Plex.plist”, make your changes, then save the file to the location: "/Applications/EyeTV.app/Contents/Resources/Export To Plex.plist"
* If you intend to run this script manually via the AppleScript Editor, you will also need to place the .plist file in the same location as the .scpt file.

* You can also create a hard link (ln), but a symbolic link will not work. (ln -s)


You can delete any entry in this file to allow the script to use the default values. We recommend that you only include the values that you need to customize, so that any changes to the defaults are automatically inherited.


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

Support
-------
This software is provided as-is, but you may request support from the volunteers at the Plex Support Forum. The thread for this
script is accessible here: <https://forums.plex.tv/index.php/topic/105404-new-script-to-integrate-eyetv-and-plex/>


Acknowledgements
----------------
This script was based initially on a Handbrake export script written by Ralf Niedling.
The original script is available at http://www.niedling.info/ralf/projekte/verschiedenes/eyetv-applescript/eyetv-handbrake_en.html.

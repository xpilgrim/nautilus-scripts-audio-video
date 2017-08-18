#!/bin/bash

## Dieses Skript validiert mp3-Dateien 
## mp3val muss installiert sein: sudo apt-get install mp3val
#
# This script validates mp3-files.
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp mp3_validate.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/mp3_validate.sh
# sudo ln -s /usr/share/nautilus-scripts/mp3_validate.sh ~/.gnome2/nautilus-scripts/mp3_validate
#
# dependent on: mp3val
# if not alraedy on your system, type for example:
# sudo apt-get install mp3val
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge@gmail.com
# 2011-09-01

function f_choose_msg_lang () {
	local_locale=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
	if [ $local_locale == "de" ]; then
		msg[1]="installiert"
		msg[2]="mp3 Validierung..."
		msg[3]="replayGain berechnen..."
		msg[4]="Validierung: Bearbeite Dateien..."
		msg[5]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine mp3 Datei:"
		err[3]="Fehler beim enkodieren"
		err[4]="Fehler beim Validieren"
	else
		msg[1]="installed"
		msg[2]="Validate mp3..."
		msg[3]="Calculate replayGain..."
		msg[4]="Validate: work on files..."
		msg[5]="Canceled..."

		err[1]=" not installed, work not possible."
		err[2]="It's not a mp3 file:"
		err[3]="Error by encoding to mp3 "
		err[4]="Error by validating"
	fi
}


function f_check_package () {
	package_install=$1
	if dpkg-query -s $1 2>/dev/null|grep -q installed; then
		echo "$package_install ${msg[1]}"
	else
		zenity --error --text="$package_install ${err[1]}"
		exit
	fi
}

# switch lang
f_choose_msg_lang
# check for packages
f_check_package "mp3val"

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "mp3validator"
(
	filename=$(basename "$file")
	extension="${filename##*.}"
	# echo and progress will pulsate
	echo "10"
	echo "# ${msg[2]}\n$filename"

	if [ "$extension" != "mp3" ] && [ "$extension" != "MP3" ]; then
		zenity --error --text="${err[2]}\n$filename" 
		exit
	fi

	message=$(mp3val -f "${file%%.*}.mp3" 2>&1 && echo "Success")
	# alle zeichen von rechts nach dem 'S' fuer fehleranalyse extrahieren
	error=${message##*S}
	if [ "$error" != "uccess" ]
		then
		echo "$message" | zenity --title="${err[4]}" --text-info --width=500 --height=200
	fi
	
	# if all OK, its processing is very short, so wait a little bit to tell the user we are working..
	sleep 1

) | zenity --progress \
           --title="${msg[4]}" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="${msg[5]}"
fi
done
exit

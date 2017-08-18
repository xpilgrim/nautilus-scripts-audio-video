#!/bin/bash

## Dieses Skript ueberprueft das mp3-gain-tag in mp3-Dateien.
## Wenn es nicht vorhanden ist, wird die Lautheit der Datei 
## analysiert und das Tag geschrieben.
## http://wiki.ubuntuusers.de/MP3Gain
## Das Skript ist abhaengig von: mp3gain (sudo apt-get install mp3gain)
# 
# This script examines the mp3-gain-tag in mp3-files.
# Is it not available, it would be write.
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# To install as nautilus-script, type:
# sudo cp mp3_gain_89.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/mp3_gain_89.sh
# sudo ln -s /usr/share/nautilus-scripts/mp3_gain_89.sh ~/.gnome2/nautilus-scripts/mp3_gain_89
#
# dependent on: mp3gain
# if not alraedy on your system, type:
# sudo apt-get install mp3gain
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge at gmail com
# 2011-09-01

function f_choose_msg_lang () {
	local_locale=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
	if [ $local_locale == "de" ]; then
		msg[1]="installiert"
		msg[2]="replayGain anpassen auf 89 dB SPL..."
		msg[3]="replayGain berechnen..."
		msg[4]="replayGain: Bearbeite Dateien..."
		msg[5]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine wav Datei:"
		err[3]="Fehler beim enkodieren"
		err[4]="Fehler bei mp3gain"
	else
		msg[1]="installed"
		msg[2]="Calculate replayGain..."
		msg[3]="Calculate replayGain..."
		msg[4]="replayGain: work on files..."
		msg[5]="Canceled..."

		err[1]=" not installed, work not possible."
		err[2]="It's not a wav file:"
		err[3]="Error by replayGain to mp3 "
		err[4]="Error by mp3gain"
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
f_check_package "mp3gain"

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "mp3gain"
(
	# echo and progress will pulsate
	echo "10"
	filename=$(basename "$file")
	extension="${filename##*.}"
	echo "# ${msg[2]}\n$filename"

	if [ "$extension" != "mp3" ] && [ "$extension" != "MP3" ]; then
		zenity --error --text="${err[2]}\n$filename" 
		exit
	fi	

	# run mp3gain
	# write result with $(commands) in message
	# use option -r to "hardcode" repalygain
	message=$(mp3gain -r "$file" 2>&1 && echo "Success")
	#message=$(mp3gain "$file" 2>&1 && echo "Success")
	
	# remove all characters right from 'S'
	error=${message##*S}
	if [ "$error" != "uccess" ]
		then
		echo "$message" | zenity --title="${err[4]}" --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="${msg[4]}" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="${msg[5]}"
fi
done
exit

#!/bin/bash

## Dieses Skript konvertiert wav-Dateien in mp3
## lame muss installiert sein: sudo apt-get install lame
#
# This script encodes wav-files to mp3-files
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp wav_to_mp3_m_128.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/wav_to_mp3_m_128.sh
# sudo ln -s /usr/share/nautilus-scripts/wav_to_mp3_m_128.sh ~/.gnome2/nautilus-scripts/wav_to_mp3_m_128
#
# dependents on: lame
# if not alraedy on your system, type for example:
# sudo apt-get install lame
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge@gmail.com
# 2011-09-01

function f_choose_msg_lang () {
	local_locale=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
	if [ $local_locale == "de" ]; then
		msg[1]="installiert"
		msg[2]="Enkodieren zu mp3..."
		msg[3]="replayGain berechnen..."
		msg[4]="wav zu mp3: Bearbeite Dateien..."
		msg[5]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine mp3 Datei:"
		err[3]="Fehler beim enkodieren"
		err[4]="Fehler bei mp3gain"
	else
		msg[1]="installed"
		msg[2]="Encode to mp3..."
		msg[3]="Calculate replayGain..."
		msg[4]="wav to mp3: work on files..."
		msg[5]="Canceled..."

		err[1]=" not installed, work not possible."
		err[2]="It's not a wav file:"
		err[3]="Error by encoding to mp3 "
		err[4]="Error by mp3gain"
	fi
}


function f_check_package () {
	package_install=$1
	if dpkg-query -s $1 2>/dev/null|grep -q installed; then
		echo "$package_install installiert"
	else
		zenity --error --text="$package_install ${err[1]}" 
		exit
	fi
}


# switch lang
f_choose_msg_lang
# check for packages
f_check_package "lame"

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "wavtomp3"
(
	filename=$(basename "$file")
	extension="${filename##*.}"
	# echo and progress will pulsate
	echo "10"
	echo "# ${msg[2]}\n$filename"
	
	if [ "$extension" != "wav" ] && [ "$extension" != "WAV" ]; then
		zenity --error --text="${err[2]}\n$filename" 
		exit
	fi

	# set --noreplaygain to prevent lame writing the replaygain tag
	message=$(lame -b 128 -m m -o -S --noreplaygain "$file" "${file%%.*}.mp3" 2>&1 && echo "Success")
	# remove all characters right from 'S'
	error=${message##*S}
	if [ "$error" != "uccess" ]
		then
		echo "$message" | zenity --title="${err[3]}" --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="${msg[4]}" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="${msg[5]}"
fi
done
exit

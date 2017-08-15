#!/bin/bash

## Dieses Skript konvertiert wav-Dateien in mp3 und passt die Lautheit mit mp3gain an
## lame und mp3gain muss installiert sein: sudo apt-get install lame/ sudo apt-get install mp3gain
#
# This script encode wav-files to mp3-files, analyses the mp3-gain and writes the replaygain-tag.
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp wav_to_mp3_st_192_gain_89.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/wav_to_mp3_st_192_gain_89.sh
# sudo ln -s /usr/share/nautilus-scripts/wav_to_mp3_st_192_gain_89.sh ~/.gnome2/nautilus-scripts/wav_to_mp3_st_192_gain_89
#
# dependent on: lame, mp3gain
# if not alraedy on your system, type for example:
# sudo apt-get install lame mp3gain
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge@gmail.com
# 2011-09-01

function f_choose_msg_lang () {
	local_locale=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
	if [ $local_locale == "en" ]; then
		msg[1]="installed"
		msg[2]="Encode to mp3..."
		msg[3]="Calculate replayGain..."
		msg[4]="wav to mp3: Work on files..."
		msg[5]="Canceled..."

		err[1]=" not installed, work not possible."
		err[2]="It's not a wav file:"
		err[3]="Error by encoding to mp3 "
		err[4]="Error by mp3gain"
	else
		msg[1]="installiert"
		msg[2]="Enkodieren zu mp3..."
		msg[3]="replayGain berechnen..."
		msg[4]="wav to mp3: Bearbeite Dateien..."
		msg[5]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine mp3 Datei:"
		err[3]="Fehler beim enkodieren"
		err[4]="Fehler bei mp3gain"
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


echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "wavtomp3gain"
(
	# switch lang
	f_choose_msg_lang
	# check for packages
	f_check_package "mp3gain"
	f_check_package "lame"
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
	message=$(lame -b 192 -m s -o -S --noreplaygain "$file" "${file%%.*}.mp3" 2>&1 && echo "Success")
	#message=$(lame -b 192 -m s -o -S "$file" "${file%%.*}.mp3" 2>&1 && echo "Success")

	# remove all characters right from 'S'
	error=${message##*S}
	if [ "$error" != "uccess" ]
		then
		echo "$message" | zenity --title="${err[3]}" --text-info --width=500 --height=200
	fi

	echo "# ${msg[3]}\n${filename%%.*}.mp3"
	#message=$(mp3gain -r "${file%%.*}.mp3" 2>&1 && echo "Success")
	message=$(mp3gain "${file%%.*}.mp3" 2>&1 && echo "Success")

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

#!/bin/bash

## Dieses Skript konvertiert audio-Dateien (Formate mit denen die libav-Libs umgehen koennen) in mp3 und passt die Lautheit mit mp3gain an
## libav-tools lame und mp3gain muss installiert sein z.B.: sudo apt-get install lame/ sudo apt-get install mp3gain
#
# This script convert audio-files to mp3-files, analyses the mp3-gain and write the mp3gain-tag.
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp convert_to_mp3_st_192_gain_89.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/convert_to_mp3_st_192_gain_89.sh
# sudo ln -s /usr/share/nautilus-scripts/convert_to_mp3_st_192_gain_89.sh ~/.gnome2/nautilus-scripts/convert_to_mp3_st_192_gain_89
#
# dependent on: libav-tools, lame, mp3gain
# if not alraedy on your system, type for example:
# sudo apt-get install mp3gain
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
		msg[4]="x zu mp3: Bearbeite Dateien..."
		msg[5]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine wav Datei:"
		err[3]="Fehler beim enkodieren"
		err[4]="Fehler bei mp3gain"
	else
		msg[1]="installed"
		msg[2]="Encode to mp3..."
		msg[3]="Calculate replayGain..."
		msg[4]="x to mp3: work on files..."
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
		echo "$package_install ${msg[1]}"
	else
		zenity --error --text="$package_install ${err[1]}"
		exit
	fi
}

# switch lang
f_choose_msg_lang
# check for packages
f_check_package "libav-tools"
f_check_package "mp3gain"
f_check_package "lame"

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "mp3gain"
(
	# echo and progress will pulsate
	echo "10"
	filename=$(basename "$file")
	extension="${filename##*.}"
	echo "# ${msg[2]}\n$filename"
	# ffmpeg und mencoder braucht irgendwie als stdin < /dev/null sonst wird nur die erste datei der schleife abgearbeitet 
	avconv -i "$file" < /dev/null -acodec pcm_s16le -ac 2 -ar 44100 "${file%%.*}_.wav" > /dev/null
	
	if [ -f "${file%%.*}_.wav" ]
  		then
		echo "# ${msg[2]}\n$filename"
		# save original file
		if [ "$extension" == "mp3" ]
			then
			mv "$file" "${file%%.mp3}_old.mp3"
		fi

		# set --noreplaygain to prevent lame writing the replaygain tag
		message=$(lame -b 192 -m s -o -S --noreplaygain "${file%%.*}_.wav" "${file%%.*}.mp3" 2>&1 && echo "Success")
		# alle zeichen von rechts nach dem 'S' fuer fehleranalyse extrahieren
		error=${message##*S}
		if [ "$error" != "uccess" ]
			then
			echo "$message" | zenity --title="${err[3]}" --text-info --width=500 --height=200
		fi
	
		#tempfile loeschen	
		rm -f "${file%%.*}_.wav"

		echo "# ${msg[3]}\n${filename%%.*}.mp3"
		# set -r for hardcoded replaygain with undo data
		message=$(mp3gain "${file%%.*}.mp3" 2>&1 && echo "Success")
		# alle zeichen von rechts nach dem 'S' fuer fehleranalyse extrahieren
		error=${message##*S}
		if [ "$error" != "uccess" ]
			then
			echo "$message" | zenity --title="${err[4]}" --text-info --width=500 --height=200
		fi
	fi

) | zenity --progress \
           --title="${msg[4]}" --text="mp3-Gain anpassen..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="${msg[5]}"
fi
done
exit

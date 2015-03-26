#!/bin/bash

## Dieses Skript konvertiert wav-Dateien in mp3
## lame und mp3gain muss installiert sein: sudo apt-get install lame
#
# This script convert wav-files to mp3-files
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
# dependent on: lame, mp3gain
# if not alraedy on your system, type for example:
# sudo apt-get install mp3gain
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge@gmail.com
# 2011-09-01

function f_check_package () {
	package_install=$1
	if dpkg-query -s $1 2>/dev/null|grep -q installed; then
		echo "$package_install installiert"
	else
		zenity --error --text="Paket $package_install ist nicht installiert, Bearbeitung nicht moeglich." 
		exit
	fi
}

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "wavtomp3"
(

	# check for packages
	f_check_package "mp3gain"
	f_check_package "lame"

	filename=$(basename "$file")
	extension="${filename##*.}"
	# echo and progress will pulsate
	echo "10"
	echo "# Konvertierung in mp3...\n$filename"
	
	if [ "$extension" != "wav" ] && [ "$extension" != "WAV" ]; then
		zenity --error --text="Ausgewählte Datei ist keine wav-Datei:\n$filename" 
		exit
	fi
	message=$(lame -b 128 -m m -o -S "$file" "${file%%.*}.mp3" 2>&1 && echo "Ohne_Fehler_beendet")
	# remove all characters right from 'O'
	error=${message##*O}
	if [ "$error" != "hne_Fehler_beendet" ]
		then
		echo "$message" | zenity --title="mp3-Konvertierungs-Fehler " --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="wav to mp3: Datei bearbeiten" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="Bearbeitung abgebrochen"
fi
done
exit

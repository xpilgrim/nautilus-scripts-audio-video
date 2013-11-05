#!/bin/bash

## Dieses Skript entfernt Stille am Anfang und Ende von Audio-Dateien 
## sox mit mp3-Support muss installiert sein: sudo apt-get install sox
#
# This script removes silence from the beginning and the end of mp3-files.
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp mp3_trim_silence.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/mp3_trim_silence_st_192_gain_89.sh
# sudo ln -s /usr/share/nautilus-scripts/mp3_trim_silence.sh ~/.gnome2/nautilus-scripts/mp3_trim_silence
#
# dependent on: sox, libsox-fmt-mp3
# if not alraedy on your system, type for example:
# sudo apt-get install sox libsox-fmt-mp3
# 
# Thanks to Jason Navarrete for his explanation of sox of silence:
# http://digitalcardboard.com/blog/2009/08/25/the-sox-of-silence/
# 
# sox parameters: 
# silence 1 0.1 1%
# 1: 1 -> trim silence to first non silence
# 2: 0.1 -> duration of silence
# 3: 1% -> threshold of sound to stop trimming
#         
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge @ g mail 
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

report "mp3trimmer"
(

	# check for packages
	f_check_package "sox"
	filename=$(basename "$file")
	# echo and progress will pulsate
	echo "10"
	echo "# Bearbeitung ...\n$filename"
	endung=${file##*\.}
	if [ "$endung" != "mp3" ]; then
		zenity --error --text="Ausgewählte Datei ist keine mp3-Datei:\n$file" 
		exit
	fi
	# copy original file in to subfolder
	mkdir -p original
	path_source=$(dirname "$file")
	file_path_orig="$path_source/original/$filename"
	cp "$file" "$file_path_orig"
	echo "# Stille entfernen bei\n$filename"
	meldung=$(sox "$file_path_orig" -C 192.2 "$file" silence 1 0.1 1% reverse silence 1 0.1 1% reverse 2>&1 && echo "Ohne_Fehler_beendet")
	# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
	error=${meldung##*O}
	if [ "$error" != "hne_Fehler_beendet" ]
		then
		echo "$meldung" | zenity --title="Silence-trim-Fehler " --text-info --width=500 --height=200
	fi

	echo "# mp3Gain-Anpassung...\n$filename"
	meldung=$(mp3gain -r "$file" 2>&1 && echo "Ohne_Fehler_beendet")
	# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
	error=${meldung##*O}
	if [ "$error" != "hne_Fehler_beendet" ]
		then
		echo "$meldung" | zenity --title="mp3Gain-Fehler " --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="mp3-Datei bearbeiten" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="Bearbeitung abgebrochen"
fi
done
exit

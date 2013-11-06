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

report "mp3validator"
(

	# check for packages
	f_check_package "mp3val"
	filename=$(basename "$file")
	extension="${filename##*.}"
	# echo and progress will pulsate
	echo "10"
	echo "# Validierung ...\n$filename"

	if [ "$extension" != "mp3" ] && [ "$extension" != "MP3" ]; then
		zenity --error --text="Ausgewählte Datei ist keine mp3-Datei:\n$filename" 
		exit
	fi

	echo "# mp3 validieren...\n${file%%.*}.mp3"
	meldung=$(mp3val -f "${file%%.*}.mp3" 2>&1 && echo "Ohne_Fehler_beendet")
	# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
	error=${meldung##*O}
	if [ "$error" != "hne_Fehler_beendet" ]
		then
		echo "$meldung" | zenity --title="Validierung-Fehler " --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="mp3-Datei bearbeiten" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="Bearbeitung abgebrochen"
fi
done
exit

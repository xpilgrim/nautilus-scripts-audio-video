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
# Copyright (C) Joerg Sorge joergsorge@gmail.com
# 2011-09-01

function f_check_package () {
	package_install=$1
	if dpkg-query -s $1 2>/dev/null|grep -q installed; then
		echo "$package_install installiert"
	else
		zenity --error --text="Paket $package_install ist nicht installiert! Bearbeitung nicht moeglich." 
		exit
	fi
}

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "mp3gain"
(
	# pruefen ob noetige pakete installiert
	f_check_package "mp3gain"

	# echo damit progress beginnt zu pulsieren
	echo "10"
	echo "# mp3-Gain anpassen auf 89 dB SPL:\n$file"

	endung=${file##*\.}
	if [ "$endung" != "mp3" ]; then
		zenity --error --text="Ausgewählte Datei ist keine mp3-Datei:\n$file" 
		exit
	fi
	# mp3gain ausführen	
	# ergebnis durch $(befehle) in meldung schreiben
	meldung=$(mp3gain -r "$file" 2>&1 && echo "Ohne_Fehler_beendet")
	
	# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
	error=${meldung##*O}
	if [ "$error" != "hne_Fehler_beendet" ]
		then
		echo "$meldung" | zenity --title="mp3Gain-Fehler " --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="mp3-Gain: Datei bearbeiten" --text="Gain anpassen..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="mp3-Gain: Bearbeitung abgebrochen"
fi
done
exit

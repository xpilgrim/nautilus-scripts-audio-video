#!/bin/bash

## Dieses Skript konvertiert audio-Dateien (Formate mit denen die ffmpeg-Libs umgehen koennen) in mp3 und passt die Lautheit mit mp3gain an
## ffmpeg lame und mp3gain muss installiert sein z.B.: sudo apt-get install lame/ sudo apt-get install mp3gain
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
# dependent on: ffmpeg, lame, mp3gain
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

report "mp3gain"
(
	# pruefen ob noetige pakete installiert
	f_check_package "mp3gain"
	f_check_package "ffmpeg"
	f_check_package "lame"

	#z = $z+1
	# echo damit progress beginnt zu pulsieren
	echo "10"
	echo "# Konvertierung in wav...\n$file"
	# ffmpeg und mencoder braucht irgendwie als stdin < /dev/null sonst wird nur die erste datei der schleife abgearbeitet 
	ffmpeg -i "$file" < /dev/null -acodec pcm_s16le -ac 2 -ar 44100 "${file%%.*}_.wav" > /dev/null
	
	if [ -f "${file%%.*}_.wav" ]
  		then
		echo "# Konvertierung in mp3...\n$file"
		meldung=$(lame -b 192 -m s -o -S "${file%%.*}_.wav" "${file%%.*}.mp3" 2>&1 && echo "Ohne_Fehler_beendet")
		# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
		error=${meldung##*O}
		if [ "$error" != "hne_Fehler_beendet" ]
			then
			echo "$meldung" | zenity --title="mp3-Konvertierungs-Fehler " --text-info --width=500 --height=200
		fi
	
		#tempfile loeschen	
		rm -f "${file%%.*}_.wav"

		echo "# mp3-Gain-Anpassung...\n${file%%.*}.mp3"
		meldung=$(mp3gain -r "${file%%.*}.mp3" 2>&1 && echo "Ohne_Fehler_beendet")
		# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
		error=${meldung##*O}
		if [ "$error" != "hne_Fehler_beendet" ]
			then
			echo "$meldung" | zenity --title="mp3Gain-Fehler " --text-info --width=500 --height=200
		fi
	fi

) | zenity --progress \
           --title="convert to mp3: Datei bearbeiten" --text="mp3-Gain anpassen..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="Bearbeitung abgebrochen"
fi
done
exit

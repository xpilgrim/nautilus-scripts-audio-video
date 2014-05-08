#!/bin/bash

# Dieses Skript konvertiert Audiokanal 2 aus Video-Dateien in wav Zweikanal, 44,1 kHz.
# So kann leicht der O-Ton bei 2-Kanal-Videoaufnahmen (Kanal-1 Athmo, Kanal-2 O-Ton) 
# fuer die Weiterverarbeitung im Radio extrahiert werden.
#
# This script convert audio-channel 2 
# from videofiles to 2-channel-wav-files
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp video_audio_track_2_to_wav_44_2ch.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/video_audio_track_2_to_wav_44_2ch.sh
# sudo ln -s /usr/share/nautilus-scripts/video_audio_track_2_to_wav_44_2ch.sh ~/.gnome2/nautilus-scripts/video_audio_track_2_to_wav_44_2ch
#
# dependent on: libav-tools
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge@gmail.com
# 2012-08-01

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

report "videotowav"
(

	# check for packages
	f_check_package "libav-tools"
	filename=$(basename "$file")
	# echo and progress will pulsate
	echo "10"
	echo "# Konvertierung in wav...\n$filename"
	message=$(avconv -y -i "$file" -ar 44100 -vn -acodec pcm_s16le -map 0:2 -ac 2 ${file%%.*}.wav 2>&1 && echo "Ohne_Fehler_beendet")
	# remove all characters right from 'O'
	error=${message##*O}
	if [ "$error" != "hne_Fehler_beendet" ]
		then
		echo "$message" | zenity --title="wav-Konvertierungs-Fehler " --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="Video to wav: Datei bearbeiten" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="Bearbeitung abgebrochen"
fi
done
exit

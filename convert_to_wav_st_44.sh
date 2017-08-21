#!/bin/bash

# Dieses Skript konvertiert in wav stereo, 44,1 kHz.
#
# This script convert to wav-files
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


function f_choose_msg_lang () {
	local_locale=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
	if [ $local_locale == "de" ]; then
		msg[1]="installiert"
		msg[2]="Transkodieren zu wav..."
		msg[3]="replayGain berechnen..."
		msg[4]="x zu wav: Bearbeite Dateien..."
		msg[5]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine wav Datei:"
		err[3]="Fehler beim Transkodieren"
		err[4]="Fehler beim Transkodieren"
	else
		msg[1]="installed"
		msg[2]="Transcode to mp3..."
		msg[3]="Calculate replayGain..."
		msg[4]="x to wav: work on files..."
		msg[5]="Canceled..."

		err[1]=" not installed, work not possible."
		err[2]="It's not a wav file:"
		err[3]="Error by transcoding to wav "
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

# this works not properly if multible files are selected
#echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do
# so we use this loop

for file in "$@"; do
report "towav"
(
	filename=$(basename "$file")
	# echo and progress will pulsate
	echo "10"
	echo "# ${msg[2]}\n$filename"
	message=$(avconv -y -i "$file" -acodec pcm_s16le -ac 2 -ar 44100 "${file%%.*}.wav" 2>&1 && echo "Success")
	# remove all characters right from 'S'
	error=${message##*S}
	if [ "$error" != "uccess" ]
		then
		echo "$message" | zenity --title="${err[3]} " --text-info --width=500 --height=200
	fi

) | zenity --progress \
           --title="${msg[4]}" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="${msg[5]}"
fi
done
exit

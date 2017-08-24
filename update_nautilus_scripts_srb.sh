#!/bin/bash

# Dieses kleine Script uebernimmt das Update von nautilus-scripts
# Aufruf in dem Verzeichnis, in dem dieses
# und die zu aktualisierenden Scripts liegen.
#
# Benutzung ab ubuntu 13.04!
#
# This script update nautilus-scripts in the current directory.
# since ubuntu 13.04
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge at googell
# 2012-06-13


echo "Nautilus-Scripts aktualisieren..."
if [ $1 == "admin" ]
	then
	echo "install additional packages"
	sudo apt-get install python-tk python-mutagen mp3splt
fi

echo "Delete old files except avconvert"
find /home/$USER/.local/share/nautilus/scripts -type f -not -name 'avconvert' -print0 | xargs -0 rm --

echo "copy scripts"
for i in *.*
do
   :
	if [ "$i" == "install_nautilus_scripts_ubuntu_13_local.sh" ] 
		then
		continue
	fi
	if [ "$i" == "update_nautilus_scripts.sh" ] 
		then
		continue
	fi
	if [ "$i" == "update_nautilus_scripts_ubuntu_13_local.sh" ] 
		then
		continue
	fi
	if [ "$i" == "update_nautilus_scripts_srb.sh" ] 
		then
		continue
	fi
	if [ "$i" == "wav_to_mp3_m_128.sh" ] 
		then
		continue
	fi
	if [ "$i" == "wav_to_mp3_m_96_gain_89_hard.sh" ] 
		then
		continue
	fi
	if [ "$i" == "mp3_trim_silence_st_192_gain_89.sh" ] 
		then
		continue
	fi
	if [ "$i" == "mp3_gain_89_hard.sh" ] 
		then
		continue
	fi
	if [ "$i" == "README" ] 
		then
		continue
	fi
	echo "$i"
	# keep off extentions
	filename=$(basename "$i")
	filename="${filename%.*}"
	cp $i /home/$USER/.local/share/nautilus/scripts/$filename
	chmod u+x /home/$USER/.local/share/nautilus/scripts/$filename
done

echo "finito"
exit

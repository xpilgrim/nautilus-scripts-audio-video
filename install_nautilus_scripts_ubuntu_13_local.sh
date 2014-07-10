#!/bin/bash

# Dieses kleine Script uebernimmt die Installation von nautilus-scripts
# Aufruf in dem Verzeichnis, in dem das zu installierende Script liegt
#
# This script install nautilus-scripts from the current directory.
# since ubuntu 13.04
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge at googell
# 2013-07-25


echo "Install Nautilus-Scripts..."

for i in *.sh
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

	echo "$i"
	# keep off extentions
	filename=$(basename "$i")
	filename="${filename%.*}"
	cp $i /home/$USER/.local/share/nautilus/scripts/$filename
	chmod +x /home/$USER/.local/share/nautilus/scripts/$filename

done
echo "Install Libs..."
if [ $UID -eq 0 ] ; then
	sudo apt-get install \
	lame mp3val libid3-tools mp3gain mp3info sox libav-tools libsox-fmt-mp3 \
	curl gawk links libtranslate-bin
else
	echo "You are not Admin, Install of Libs uncompleted..."
fi

# nautius reset
nautilus -q

echo "finito"
exit

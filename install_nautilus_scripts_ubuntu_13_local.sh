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


echo "Nautilus-Scripts installieren..."

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
	cp $i /home/$USER/.local/share/nautilus/scripts/
	chmod +x /home/$USER/.local/share/nautilus/scripts/$i

done
echo "Libs installieren..."
sudo apt-get install \
lame mp3val libid3-tools mp3gain mp3info sox libav-tools libsox-fmt-mp3 \
curl gawk links libtranslate-bin

# nautius reset
nautilus -q

echo "finito"
exit

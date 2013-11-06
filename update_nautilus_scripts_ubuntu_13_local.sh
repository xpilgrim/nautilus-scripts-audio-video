#!/bin/bash

# Dieses kleine Script uebernimmt das Update von nautilus-scripts
# Aufruf in dem Verzeichnis, in dem dieses
# und die zu aktualiseirenden Scripts liegen.
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

for i in *.sh
do
   :
	if [ "$i" != "update_nautilus_scripts_ubuntu_13_local.sh" ] 
		then	
		echo "$i"
		cp $i /home/$USER/.local/share/nautilus/scripts/
		chmod +x /home/$USER/.local/share/nautilus/scripts/$i
	fi
done

echo "finito"
exit

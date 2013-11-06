#!/bin/bash

# Dieses kleine Script uebernimmt das Update von nautilus-scripts
# Aufruf in dem Verzeichnis, in dem dieses
# und die zu aktualiseirenden Scripts liegen.
#
# This script update nautilus-scripts in the current directory.
#
# Author: Joerg Sorge
# Distributed under the terms of GNU GPL version 2 or later
# Copyright (C) Joerg Sorge joergsorge at googell
# 2012-06-13


echo "Nautilus-Scripts aktualisieren..."

for i in *.sh
do
   :
	if [ "$i" != "update_nautilus_scripts.sh" ] 
		then	
		echo "$i"
		sudo cp $i /usr/share/nautilus-scripts
		sudo chmod +x /usr/share/nautilus-scripts/$i
	fi
done

echo "finito"
exit

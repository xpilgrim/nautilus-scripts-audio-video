#!/bin/bash

## Dieses Skript ermittelt die Laenge von mp3-Dateien und schlaegt vor, 
## sie in entsprechend viele 60-Minuten lange Dateien zu teilen.
## Es wird eine temp. wav-Datei erzeugt, um Laengenungenauigkeiten zu vermeiden.
## Bei den erzeugten mp3-Dateien wird die Lautheit mit mp3gain angepasst.
## sox, mp3info, lame und mp3gain muss installiert sein 
## z.B.: sudo apt-get install lame/ sudo apt-get install mp3gain.
## Getestet von ubuntu 9.10 bis 11.04.
#
# This script splitt mp3-files, analyses the mp3-gain and write the mp3gain-tag.
# There are two option for splitting: 
# splitt in suggested parts or manually specify the startpoint and lenght of each part
#
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
# Install in ~/.gnome2/nautilus-scripts or ~/Nautilus/scripts
# You need to be running Nautilus 1.0.3+ to use scripts.
#
# To install as nautilus-script, type:
# sudo cp mp3_splitt_st_192_gain_89.sh /usr/share/nautilus-scripts
# sudo chmod +x /usr/share/nautilus-scripts/mp3_splitt_st_192_gain_89.sh
# sudo ln -s /usr/share/nautilus-scripts/mp3_splitt_st_192_gain_89.sh ~/.gnome2/nautilus-scripts/mp3_splitt_st_192_gain_89
#
# dependent on: mp3info, lame, mp3gain
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

function f_check_param () {
	parameters=$1
	# ermitteln ob erster wert (start in minuten) zwei oder dreistellig (":" suchen)
	pos_doppelpunkt=`expr index "$parameters" ":"`
	#zenity --info --text="pos doppel $pos_doppelpunkt"
	case $pos_doppelpunkt in
		3) 
		audio_start=${parameters:0:5}
		temp_param_2=${parameters:6:6}
		if [[ ! "$audio_start" =~ [0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="Eingabe von Startzeit nicht korrekt!"
			abbruch="yes"
		fi
		;;
		4) 
		audio_start=${parameters:0:6}
		temp_param_2=${parameters:7:6}
		if [[ ! "$audio_start" =~ [0-9][0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="Eingabe von Startzeit nicht korrekt!"
			abbruch="yes"
		fi
		;;
		*)
		zenity --error --text="Eingabe von Startzeit nicht korrekt!"
		abbruch="yes"	
	esac
									
	# laenge des zweiten params ermitteln (zwei oder dreistellig)
	pos_doppelpunkt=`expr index "$temp_param_2" ":"`
	#zenity --info --text="temp $temp_param_2"
	case $pos_doppelpunkt in
		3) 
		audio_length=${temp_param_2:0:5}
		if [[ ! "$audio_length" =~ [0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="Eingabe von Laenge nicht korrekt!"
			abbruch="yes"
		fi
		;;
		4) 
		audio_length=${temp_param_2:0:6}
		if [[ ! "$audio_length" =~ [0-9][0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="Eingabe von Laenge nicht korrekt!"
			abbruch="yes"
		fi
		;;
		*)
		zenity --error --text="Eingabe von Laenge nicht korrekt!"
		abbruch="yes"				
	esac

	param_length=$param_1_length$param_2_length
	#zenity --info --text="st $audio_start lae $audio_length par $param_length"	
}


function f_wave_temp () {
	file_source=$1
	file_dest=$2
	#zenity --info --text="s_ $file_source d_ $file_dest"
	ffmpeg -i "$file_source" < /dev/null -acodec pcm_s16le -ac 2 -ar 44100 "$file_dest" > /dev/null
}

function f_wave_to_mp3 () {
	file_source=$1
	file_dest=$2
	meldung=$(lame -b 192 -m s -o -S "$file_source" "$file_dest" 2>&1 && echo "Ohne_Fehler_beendet")
	# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
	error=${meldung##*O}
	if [ "$error" != "hne_Fehler_beendet" ]; then
		echo "$meldung" | zenity --title="mp3-Konvertierungs-Fehler " --text-info --width=500 --height=200
	fi
}

function f_mp3_gain () {
	file_source=$1
	meldung=$(mp3gain -r "$file_source" 2>&1 && echo "Ohne_Fehler_beendet")
	# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
	error=${meldung##*O}
	if [ "$error" != "hne_Fehler_beendet" ]; then
		echo "$meldung" | zenity --title="mp3-Gain-Fehler " --text-info --width=500 --height=200
	fi
}

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "mp3split"
(

	# pruefen ob noetige pakete installiert
	f_check_package "sox"
	f_check_package "mp3gain"
	f_check_package "mp3info"
	f_check_package "lame"
	f_check_package "ffmpeg"
	filename=$(basename "$file")
	# echo damit progress beginnt zu pulsieren
	echo "10"
	echo "# Analyse...\n$filename"
	endung=${file##*\.}
	if [ "$endung" != "mp3" ]; then
		zenity --error --text="Ausgewählte Datei ist keine wav-Datei:\n$filename" 
		exit
	fi
	minutes=$(mp3info -p "%m" "$file" )
	parts_60=$((minutes/60))

	if [ $minutes -gt 60 ] ; then
		# wenn laenger als 60 Minuten, entspr.Anzahl 60-Minuten-Bloecke vorschlagen 
		answer=$(zenity  --width=500 --list  --text "Die Datei hat eine Laenge von $minutes Minuten"\
		 --radiolist  --column "Pick" --column "Auswahl"\
		 TRUE "In $parts_60 gleich lange 60-Minuten Abschnitte teilen! "\
		 FALSE "Manuelle Splittpoints angeben")
	else
		# wenn kuerzer als 60 Minuten immer manuell
		answer="Manuelle Splittpoints angeben"
	fi

	answ=${answer:0:2} 
	#zenity --info --text="$answ"
	
	if [ $answ = "In" ] ; then
		# vorgeschlagene splitts gewaehlt
		#zenity --info --text="in $answer"
		msg="In $parts_60 gleich lange 60-Minuten-Abschnitte teilen: \n"
		echo "# $msg $filename\nTemp-Datei anlegen: ${filename%%.*}_.wav"
		f_wave_temp "$file" "${file%%.*}_.wav"
		
		if [ -f "${file%%.*}_.wav" ] ; then
			audio_start=0
			audio_length=60
			
			# Splitts als wav schreiben
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg Abschnitt $z, $audio_start:00 - $audio_length:00 erzeugen aus:\n${filename%%.*}_.wav"
					sox "${file%%.*}_.wav" "${file%%.*}_$z.wav" trim $audio_start:00 $audio_length:00
					audio_start=$(($audio_start+60))
				done

			# Splitts in mp3 konvertieren
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg Abschnitt $z, Konvertierung in mp3 aus:\n${filename%%.*}_$z.wav"
					f_wave_to_mp3 "${file%%.*}_$z.wav" "${file%%.*}_$z.mp3"
				done

			# Splitts mp3Gain
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg Abschnitt $z, mp3Gain anpassen in:\n${filename%%.*}_$z.mp3"
					meldung=$(mp3gain -r "${file%%.*}_$z.mp3" 2>&1 && echo "Ohne_Fehler_beendet")
					# alle zeichen von rechts nach dem 'O' fuer fehleranalyse extrahieren
					error=${meldung##*O}
					if [ "$error" != "hne_Fehler_beendet" ]
						then
						echo "$meldung" | zenity --title="mp3-Gain-Fehler " --text-info --width=500 --height=200
					fi
				done

			# tempfiles loeschen
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg Temp-Datei loeschen:\n${filename%%.*}_$z.wav"
					rm -f "${file%%.*}_$z.wav"
				done
			rm -f "${file%%.*}_.wav"

		fi
	else # $answ = "In"
		# wenn vorherige radiolist nicht abgebrochen, muss "Ma" in answ stehen
		if [ $answ = "Ma" ] ; then
				
			params=$(zenity\
			 --entry --text \
			"Die mp3-Datei hat eine Laenge von: $minutes Minuten. 
Zum Teilen bitte Startpunkt und Dauer der gewuenschten Abschnitte in [mm:ss-mm:ss] eingeben!
Für mehrere Teile bitte durch Schraegstriche trennen.
z.B. zwei aufeinanderfolgende Teile von 60 Minuten Laenge: [00:00-60:00/60:00-60:00]  " \
			--entry-text "00:00-60:00/60:00-60:00")

			if [ ! "$params" ] ; then
				exit
			fi

			# anzahl der schraegstriche ermitteln, zuerst extrahieren ${params//[^\/]/}" und dann zaehlen ${#anzahl_splits}
			anzahl_splits="${params//[^\/]/}"
			anzahl_splits=${#anzahl_splits}
			anzahl_splits=$(($anzahl_splits + 1))
			#zenity --info --text="$anzahl_splits"				
			#zenity --info --text="${#anzahl_splits}"

			msg="In $anzahl_splits Abschnitte teilen: \n"
			echo "# $msg $filename\nTemp-Datei anlegen: ${filename%%.*}_.wav"
			f_wave_temp "$file" "${file%%.*}_.wav"

			if [ -f "${file%%.*}_.wav" ] ; then
				abbruch="no"
				params_temp="$params"

				for (( z=1; z<=$anzahl_splits; z++ ))
					do
						# Eingabepruefung, bei fehlern nicht erst mit wav-split beginnen
						f_check_param $params_temp
						pos_slash=`expr index "$params_temp" "/"`
						params_temp=${params_temp:$pos_slash}
					done

				if [ $abbruch = "no" ] ; then
					params_temp="$params"
					# Splitts als wav schreiben
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							f_check_param $params_temp
							echo "# $msg Abschnitt $z, $audio_start - $audio_length erzeugen aus:\n${filename%%.*}_.wav"
							sox "${file%%.*}_.wav" "${file%%.*}_$z.wav" trim $audio_start $audio_length
							pos_slash=`expr index "$params_temp" "/"`
							params_temp=${params_temp:$pos_slash}
						done
					
					# Splitts in mp3 konvertieren
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							echo "# $msg Abschnitt $z, Konvertierung in mp3 aus:\n${filename%%.*}_$z.wav"
							f_wave_to_mp3 "${file%%.*}_$z.wav" "${file%%.*}_$z.mp3"
						done

					# Splitts mp3-gain
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							echo "# $msg Abschnitt $z, mp3Gain anpassen in:\n${filename%%.*}_$z.mp3"
							f_mp3_gain "${file%%.*}_$z.mp3" 
						done
					
					# tempfiles loeschen
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							echo "# $msg Temp-Datei loeschen:\n${filename%%.*}_$z.wav"
						rm -f "${file%%.*}_$z.wav"
						done
					rm -f "${file%%.*}_.wav"
				else
					# tempfile loeschen
					rm -f "${file%%.*}_.wav"
				fi # abbruch = no
			fi # if wav-file
		fi # $answ = "Ma"
	fi # $answ = "In"

) | zenity --progress \
           --title="mp3-splitt: Datei bearbeiten" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="mp3-splitt: Bearbeitung abgebrochen"
fi
done
exit

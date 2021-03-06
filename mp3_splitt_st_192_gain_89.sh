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

function f_choose_msg_lang () {
	local_locale=$(locale | grep LANGUAGE | cut -d= -f2 | cut -d_ -f1)
	if [ $local_locale == "de" ]; then
		msg[1]="installiert"
		msg[2]="Analysieren..."
		msg[3]="Die Datei hat eine Laenge in Minuten: "
		msg[4]="Auswahl..."
		msg[5]="In"
		msg[6]="Abschnitte teilen! Erste(r) Abschnitt(e) 60 Min, letzter Abschnitt entspr. der Restzeit"
		msg[7]="Manuelle Splittpoints angeben"
		msg[8]="Abschnitte teilen"
		msg[9]="Temp-Datei anlegen:"
		msg[10]="Abschnitt"
		msg[11]="erzeugen aus:"
		msg[12]="Enkodieren zu mp3"
		msg[13]="replayGain berechnen"
		msg[14]="Temp-Datei loeschen"
		msg[15]="Dateilaenge in Minuten"
		msg[16]="Startpunkt und Dauer der Abschnitte in [mm:ss-mm:ss] eingeben!
Mehrere Teile durch Schraegstriche trennen.\nZ.B. zwei aufeinanderfolgende Teile von 60 Minuten Laenge: \n[00:00-60:00/60:00-60:00]  "
		msg[17]="Abschnitte teilen"
		msg[18]="mp3-splitt: Datei bearbeiten"
		msg[19]="Abgebrochen..."

		err[1]=" ist nicht installiert, Bearbeitung nicht moeglich."
		err[2]="Das ist keine mp3 Datei:"
		err[3]="Fehler beim enkodieren"
		err[4]="Fehler bei mp3gain"
		err[5]="Eingabe von Startzeit nicht korrekt!"
		err[6]="Eingabe von Laenge nicht korrekt!"
		err[7]="Fehler beim Enkodieren"
		err[8]="Fehler bei mp3gain"
	else
		msg[1]="installed"
		msg[2]="Analyse..."
		msg[3]="Length in minutes: "
		msg[4]="Choose..."
		msg[5]="Splitt to"
		msg[6]="pieces! First(s) 60 Min, last with legth of tail"
		msg[7]="Set splitt points manually"
		msg[8]="pieces"
		msg[9]="Temp file:"
		msg[10]="Piece"
		msg[11]="from:"
		msg[12]="Encode to mp3"
		msg[13]="Calculate replayGain"
		msg[14]="Remove temp file"
		msg[15]="Length of file in minutes"
		msg[16]="Type start and lenght [mm:ss-mm:ss]\n Slash for next piece e.g. [00:00-60:00/60:00-60:00]  "
		msg[17]="pieces"
		msg[18]="mp3 splitt: work on files"
		msg[19]="Canceled..."

		err[1]=" not installed, work not possible."
		err[2]="It's not a mp3 file:"
		err[3]="Error by encoding to mp3 "
		err[4]="Error by mp3gain"
		err[5]="Input for start time not valid"
		err[6]="Input for length not valid"
		err[7]="Error by encoding to mp3 "
		err[8]="Error by mp3gain"
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
			zenity --error --text="${err[5]}"
			abbruch="yes"
		fi
		;;
		4) 
		audio_start=${parameters:0:6}
		temp_param_2=${parameters:7:6}
		if [[ ! "$audio_start" =~ [0-9][0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="${err[5]}"
			abbruch="yes"
		fi
		;;
		*)
		zenity --error --text="${err[5]}"
		abbruch="yes"	
	esac
									
	# laenge des zweiten params ermitteln (zwei oder dreistellig)
	pos_doppelpunkt=`expr index "$temp_param_2" ":"`
	#zenity --info --text="temp $temp_param_2"
	case $pos_doppelpunkt in
		3) 
		audio_length=${temp_param_2:0:5}
		if [[ ! "$audio_length" =~ [0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="${err[6]}"
			abbruch="yes"
		fi
		;;
		4) 
		audio_length=${temp_param_2:0:6}
		if [[ ! "$audio_length" =~ [0-9][0-9][0-9]:[0-9][0-9] ]]; then
			zenity --error --text="${err[6]}"
			abbruch="yes"
		fi
		;;
		*)
		zenity --error --text="${err[6]}"
		abbruch="yes"				
	esac

	param_length=$param_1_length$param_2_length
	#zenity --info --text="st $audio_start lae $audio_length par $param_length"	
}


function f_wave_temp () {
	file_source=$1
	file_dest=$2
	#zenity --info --text="s_ $file_source d_ $file_dest"
	avconv -i "$file_source" < /dev/null -acodec pcm_s16le -ac 2 -ar 44100 "$file_dest" > /dev/null
}

function f_wave_to_mp3 () {
	file_source=$1
	file_dest=$2
	meldung=$(lame -b 192 -m j -o -S --noreplaygain "$file_source" "$file_dest" 2>&1 && echo "Success")
	# alle zeichen von rechts nach dem 'S' fuer fehleranalyse extrahieren
	error=${meldung##*S}
	if [ "$error" != "uccess" ]; then
		echo "$meldung" | zenity --title="${err[7]}" --text-info --width=500 --height=200
	fi
}

function f_mp3_gain () {
	file_source=$1
	meldung=$(mp3gain "$file_source" 2>&1 && echo "Success")
	# alle zeichen von rechts nach dem 'S' fuer fehleranalyse extrahieren
	error=${meldung##*S}
	if [ "$error" != "uccess" ]; then
		echo "$meldung" | zenity --title="${err[8]} " --text-info --width=500 --height=200
	fi
}


# switch lang
f_choose_msg_lang
# check for packages
f_check_package "sox"
f_check_package "mp3gain"
f_check_package "mp3info"
f_check_package "lame"
f_check_package "libav-tools"

echo -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS}" | while read file ; do

report "mp3split"
(
	filename=$(basename "$file")
	extension="${filename##*.}"
	# echo damit progress beginnt zu pulsieren
	echo "10"
	echo "# ${msg[2]}\n$filename"

	if [ "$extension" != "mp3" ] && [ "$extension" != "MP3" ]; then
		zenity --error --text="${err[2]}\n$filename" 
		exit
	fi
	minutes=$(mp3info -p "%m" "$file" )
	#parts_60=$((minutes/60))

	# calc amount of 60 minute pieces
	parts_60=0
	for (( z=0; z<$minutes; z+=60 ))
		do
			echo $z
			echo $((parts_60+=1))
		done
	echo $zz

	if [ $minutes -gt 60 ] ; then
		# wenn laenger als 60 Minuten, entspr. Anzahl 60-Minuten-Bloecke vorschlagen 
		answer=$(zenity --height=200 --width=700 --list --text "${msg[3]}$minutes"\
		 --radiolist --column "Pick" --column "${msg[4]}"\
		 TRUE "1. ${msg[5]} $parts_60 ${msg[6]} "\
		 FALSE "2. ${msg[7]}")
	else
		# wenn kuerzer als 60 Minuten immer manuell
		answer="${msg[7]}"
	fi

	answ=${answer:0:2} 
	#zenity --info --text="$answ"
	
	if [ $answ = "1." ] ; then
		# vorgeschlagene splitts gewaehlt
		#zenity --info --text="in $answer"
		msg="${msg[5]} $parts_60 ${msg[8]}: \n"
		echo "# $msg $filename\n${msg[9]} ${filename%%.*}_.wav"
		f_wave_temp "$file" "${file%%.*}_.wav"
		
		if [ -f "${file%%.*}_.wav" ] ; then
			audio_start=0
			audio_length=60
			
			# Splitts als wav schreiben
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg ${msg[10]} $z, $audio_start:00 - $audio_length:00 ${msg[11]}\n${filename%%.*}_.wav"
					sox "${file%%.*}_.wav" "${file%%.*}_$z.wav" trim $audio_start:00 $audio_length:00
					audio_start=$(($audio_start+60))
				done

			# Splitts in mp3 konvertieren
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg ${msg[10]} $z, ${msg[12]}:\n${filename%%.*}_$z.wav"
					f_wave_to_mp3 "${file%%.*}_$z.wav" "${file%%.*}_$z.mp3"
				done

			# Splitts mp3Gain
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg ${msg[10]} $z, ${msg[13]}:\n${filename%%.*}_$z.mp3"
					f_mp3_gain "${file%%.*}_$z.mp3"
				done

			# tempfiles loeschen
			for (( z=1; z<=$parts_60; z++ ))
				do
					echo "# $msg ${msg[14]}:\n${filename%%.*}_$z.wav"
					rm -f "${file%%.*}_$z.wav"
				done
			rm -f "${file%%.*}_.wav"

		fi
	else # $answ = "1."
		# wenn vorherige radiolist nicht abgebrochen, muss "Ma" in answ stehen
		if [ $answ = "2." ] ; then
				
			params=$(zenity\
			 --entry --text \
			"${msg[15]}: $minutes\n ${msg[16]}" \
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

			msg="${msg[5]} $anzahl_splits ${msg[17]}: \n"
			echo "# $msg $filename\n${msg[9]}: ${filename%%.*}_.wav"
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
							echo "# $msg ${msg[10]} $z, $audio_start - $audio_length ${msg[11]}\n${filename%%.*}_.wav"
							sox "${file%%.*}_.wav" "${file%%.*}_$z.wav" trim $audio_start $audio_length
							pos_slash=`expr index "$params_temp" "/"`
							params_temp=${params_temp:$pos_slash}
						done
					
					# Splitts in mp3 konvertieren
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							echo "# $msg ${msg[10]} $z, ${msg[12]}:\n${filename%%.*}_$z.wav"
							f_wave_to_mp3 "${file%%.*}_$z.wav" "${file%%.*}_$z.mp3"
						done

					# Splitts mp3-gain
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							echo "# $msg ${msg[10]} $z, ${msg[13]}:\n${filename%%.*}_$z.mp3"
							f_mp3_gain "${file%%.*}_$z.mp3"
						done
					
					# tempfiles loeschen
					for (( z=1; z<=$anzahl_splits; z++ ))
						do
							echo "# $msg ${msg[14]}:\n${filename%%.*}_$z.wav"
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
           --title="${msg[18]}" --text="..." --width=500 --pulsate --auto-close

if [ "$?" = -1 ] ; then
	zenity --error --text="${msg[19]}"
fi
done
exit

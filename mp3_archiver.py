#!/usr/bin/env python
# -*- coding: utf-8 -*-
# pylint: disable-msg=C0103

"""

Autor: Joerg Sorge

Distributed under the terms of GNU GPL version 2 or later
Copyright (C) Joerg Sorge joergsorge at ggooogl
2017-07-18

This script is a so called "nautilus script".

This script performs the follow actions on the selected files:
    - Backup the unchanged files in the subfolder ...orig
    - Rename filenames with non-asccii characters
    - Check for at least bitrate according to app_mp3_bitrate value
    - Trim silence on the beginning and the end of a mp3
    - Reduce ID3V2-Tags to author and title, remove ID3V1 Tags, write ID3V2.4
    - register mp3Gain in the APE-Tag

If the file has a bitrate grater then set in app_mp3_bitrate,
then the file will be recoded. Otherwise a lossless trimm will be done.

Depends on:
    Python, Tkinter, python-mutagen, sox, mp3gain, mp3splt, easytag
Install additional packages with:
    sudo apt-get install python-tk python-mutagen sox mp3gain mp3splt easytag
"""

import os
import sys
import subprocess
from ScrolledText import ScrolledText
import shutil
import string
import re
import datetime
import math
#from Tkinter import Button, Frame, END
try:
    from Tkinter import Button, Frame, END
except ImportError:
    print "ImportError Tkinter"
    try:
        message = ("ImportError Tkinter!\nPlease install it with:\n"
                + "sudo apt-get install python-tk")
        subprocess.Popen(["zenity", "--info", "--text", message],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        print e
    sys.exit()

try:
    import mutagen
    from mutagen.id3 import ID3, TPE1, TIT2
    from mutagen.id3 import ID3NoHeaderError
    from mutagen.apev2 import APEv2
    from mutagen.mp3 import MP3
except ImportError:
    print "ImportError mutagen"
    try:
        message = ("ImportError mutagen!\nPlease install it with:\n"
                + "sudo apt-get install python-mutagen")
        subprocess.Popen(["zenity", "--info", "--text", message],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        print e
    sys.exit()


class app_config(object):
    """Application-Config"""
    def __init__(self):
        """Settings"""
        # app_config
        self.app_desc = u"Audio Archiver"
        # Bitrate for mp3 (192, 256 or 320) in kBit/s
        self.app_mp3_bitrate = 192
        # Lame mp3 encoding quality level from 0 to 9
        # if you want to set the quality to the highest level (value 0),
        # you must use 99 instead,
        # see the man soxformat option -C for the reason!
        self.app_mp3_encode_quality = 2
        # show warning when trimmed file is more then x seconds shorter:
        self.app_max_length_diff = 5
        self.log_message_summary_bitrate = []
        self.log_message_summary_id3tag = []
        self.log_message_summary_no_silence = []
        self.log_message_summary_max_length_diff = []
        self.log_message_summary_not_moved = None
        # for normal usage set to no!!!!!!
        self.app_windows = "no"


def switch_lang(self):
    """switch lang for msgs"""
    self.msg = ["lang"]
    self.err = ["lang"]
    if os.getenv('LANG')[0:2] == "de":
        self.msg.append(
            "Es kann eine Weile dauern, "
            + "vielleicht eine Tasse Kaffee geniessen...")  # 1
        self.msg.append("\nArbeitsverzeichnis:")  # 2
        self.msg.append("\nDateien:")
        self.msg.append("\nWir sind fertig, sorry, "
            + "wahrscheinlich nicht genung Zeit fuer einen Kaffee...")  # 4
        self.msg.append("\nStille trimmen, ID3-Tags bearbeiten, "
            + "das dauert etwas...")
        self.msg.append("\nmp3Gain berechnen...")  # 6
        self.msg.append("\nTemp Verzeichnis geloescht...")
        self.msg.append("Mod Verzeichnis geloescht...")  # 8
        self.msg.append("\nBitte Folgendes beachten!")
        self.msg.append("Diese Dateien konnten nicht bearbeitet werden, "
            + "sie haben eine zu niedrige Bitrate")  # 10
        self.msg.append("\nDiese Dateien haben keine ID3 Tags Version 2")
        self.msg.append("\nDiese Dateien mussten nicht getrimmt werden, "
            + "bitte manuell kontrollieren: lame replaygain, xing header etc.:")
        self.msg.append("\nEine oder mehrere Dateien konnten nicht aus dem "
            + "Mod-Verzeichnis verschoben werden, bitte manuell erledigen!")
        self.msg.append("\nGeschafft, "
            + "ich hoffe der Kaffee war gut?")  # 14
        self.msg.append("\nOriginale werden gespeichert in:")
        self.msg.append("\nTemporaere Dateien werden gespeichert in:")  # 16
        self.msg.append("\nBearbeitete Dateien werden gespeichert in:")
        self.msg.append("\nOriginale sichern, Dateinamen bearbeiten...")  # 18
        self.msg.append("\nDateiname geaendert:")
        self.msg.append("Bitrate zu niedrig, Datei uebersprungen...")  # 20
        self.msg.append("Verlustfrei getrimmt: ")
        self.msg.append("\nDiese Dateien sind nach dem Trimmen um mehr als ")
        self.msg.append(" Sekunden kuerzer, bitte manuell kontrollieren:")

        self.err.append("Fehlendes Paket ")
        self.err.append(" Bitte installieren durch\n sudo apt-get install ")
        self.err.append("\nUngueltige Bitrate: ")  # 3
        self.err.append("Gueltige Bitraten sind: 192, 256 oder 320! "
            + "Bitte den Wert von app_mp3_bitrate aendern.")  # 4
        self.err.append("\nUngueltige Qualitaetsstufe fuer Encodierung: ")
        self.err.append("\nDie Empfohlene Stufe ist 2. \n"
            + "Moeglich sind Werte zw. 1 und 6, hoeher ist geringere Qualitaet,"
            + " 99 fuer beste."
            + "\nBitte Wert aendern in: app_mp3_encode_quality")
        self.err.append("Dies ist ein Nautilus Script, "
            + "zum Bearbeiten muessen Dateien ausgewaehlt sein.")  # 7
        self.err.append("Keine mp3 Dateien gefunden...")  # 8
    else:
        self.msg.append(
            "Working, this can take a while, enjoy a cup of coffee...\n")  # 1
        self.msg.append("\nDirectory to work in:")  # 2
        self.msg.append("\nFiles to work on:")
        self.msg.append("\nNow we are finished, "
            + "sorry, I think it was not enough time for coffee...")  # 4
        self.msg.append("\nTrim silence, edit Tags, this can take a while...")
        self.msg.append("\nmp3Gain, this can take a while...")  # 6
        self.msg.append("\nTemp Directory removed...")
        self.msg.append("Mod Directory removed...")  # 8
        self.msg.append("\nPlease take care about the following issues!")
        self.msg.append("This files are not editable, "
            + "while they have to low bitrate:")  # 10
        self.msg.append("\nThis files hasn't ID3 Tags Version 2, "
            + "please use an ID3-Tagger:")
        self.msg.append("\nThis files wasn't trimmed, "
            + "please analyse manually lame replaygain, xing header etc.:")
        self.msg.append("\nOne or more files couldn't moved out "
            + "from mod directory, please do it manually!")
        self.msg.append("\nNow we are finished, "
            + "I hope the coffee was fine?")  # 14
        self.msg.append("\nOriginal files will be saved in:")
        self.msg.append("\nTemp files will be saved in:")  # 16
        self.msg.append("\nModified files will be saved in:")
        self.msg.append("\nBackup files, check filenames...")  # 18
        self.msg.append("\nModified filename:")
        self.msg.append("Bitrate to low, file will be skipped...")  # 20
        self.msg.append("Lossless trimmed: ")
        self.msg.append("\nThis files are more then ")
        self.msg.append(" seconds shorter, please analyse manually:")

        self.err.append("Missing package ")  # 1
        self.err.append("!\nPlease install it with:\n sudo apt-get install ")
        self.err.append("\nThe current bitrate is set to a wrong value: ")  # 3
        self.err.append("The bitrate option must be 192, 256 or 320! "
            + "Please correct your entry in: app_mp3_bitrate")
        self.err.append(
            "\nThe current encode quality is set to a wrong value: ")  # 5
        self.err.append(
            "The encode quality option must be 99 for best quality, "
                    + "or a value between 1 and 6, higher is lower quality! "
                    + "\nPlease correct your entry in: app_mp3_encode_quality")
        self.err.append("This is a nautilus script "
            + "that need one or more selected files for working on")
        self.err.append("No mp3 files found...")  # 8


def check_packages(self, package_list):
    """check_packages"""
    try:
        for package in package_list:
            print package
            p = subprocess.Popen(["dpkg-query", "-s", package,
                "2>/dev/null|grep"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
            #print p
            #print string.find(p[0], "installed")
            if string.find(p[0], "installed") == -1:
                message = (self.err[1] + package + self.err[2] + package)
                self.display_logging(message, "r")
                return None
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")
        return None
    return True


def extract_filename(path_filename):
    """extract filename right from slash"""
    if ac.app_windows == "no":
        filename = path_filename[string.rfind(path_filename, "/") + 1:]
    else:
        filename = path_filename[string.rfind(path_filename, "\\") + 1:]
    return filename


def remove_forbidden_characters(my_string):
    """remove_forbidden_characters"""
    x = my_string.replace(u"'", "")
    x = x.replace(u"/", "")
    x = x.replace(u"&", "")
    x = x.replace(u"?", "")
    x = x.replace(u":", "")
    x = x.replace(u",", "")
    x = x.replace(u";", "")
    x = x.replace(u"+", "")
    x = x.replace(u"*", "")
    x = x.replace(u"=", "")
    x = x.replace(u"[", "")
    x = x.replace(u"]", "")
    x = x.replace(u"{", "")
    x = x.replace(u"}", "")
    x = x.replace(u"(", "")
    x = x.replace(u")", "")
    x = x.replace(u"%", "")
    x = x.replace(u"$", "")
    x = x.replace(u"§", "")
    x = x.replace(u"!", "")
    x = x.replace(u"#", "")
    x = x.replace(u"′", "")
    x = x.replace(u"^", "")
    x = x.replace(u"°", "")
    x = x.replace(u"~", "")
    return x


def remove_points(my_mp3):
    """remove additionally points in filename"""
    n = string.find(my_mp3, ".mp3")
    x = my_mp3[0:n]
    x = x.replace(u".", "")
    my_mp3_mod = x + ".mp3"
    return my_mp3_mod


def check_and_mod_filenames(self, mp3_files):
    """search for forbidden charakters in filenames, if found rename"""
    mp3_files_temp = []
    mp3_files_mod = []
    self.display_logging(self.msg[15], None)
    #dir_orig = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
    # take the tail of filepath in the name of backup dir
    dir_orig = (os.path.dirname(mp3_files[0]) + "/"
        + os.path.basename(os.path.dirname(mp3_files[0])) + "_"
        + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_original")
    self.display_logging(dir_orig, None)

    self.display_logging(self.msg[16], None)
    #self.display_logging(datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S"))
    dir_temp = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_temp")
    self.display_logging(dir_temp, None)

    self.display_logging(self.msg[17], None)
    dir_mod = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_mod")
    self.display_logging(dir_mod, None)
    try:
        os.mkdir(dir_orig)
        os.mkdir(dir_temp)
        os.mkdir(dir_mod)
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")

    self.display_logging(self.msg[18], None)
    # backup in orig
    for item in mp3_files:
        file_destination = dir_orig + "/" + extract_filename(item)
        try:
            #self.display_logging(item + "\n", None)
            shutil.copy(item, file_destination)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")

        # filename hacks
        # remove non ascii
        filename_mod = re.sub(r'[^\x00-\x7f]', r'', extract_filename(item))
        # remove forbidden characters
        filename_mod = remove_forbidden_characters(filename_mod)
        # remove points
        filename_mod = remove_points(filename_mod)

        if extract_filename(item) != filename_mod:
            self.display_logging(self.msg[19], None)
            self.display_logging(filename_mod, "b")

        #self.display_logging(item, "b")
        # concatenate path and filename
        try:
            # decode needed for pathnames with non ascii
            path_file_temp = (dir_temp.decode(sys.getfilesystemencoding())
                                    + "/" + filename_mod)
            #self.display_logging(path_file_temp, "b")
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")

        # decode needed for pathnames with non ascii
        path_file_mod = (dir_mod.decode(sys.getfilesystemencoding())
                                        + "/" + filename_mod)

        # move in temp
        try:
            #for production, change from copy to move
            #shutil.copy(item, path_file_temp)
            shutil.move(item, path_file_temp)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")
            continue
        # new file list
        mp3_files_temp.append(path_file_temp)
        mp3_files_mod.append(path_file_mod)
    return mp3_files_temp, mp3_files_mod, dir_temp, dir_mod


def mp3gain(self, mp3_file):
    """mp3-gain"""
    print u"mp3-File Gainanpassung"
    #self.display_logging("\nmp3gain for: ", None)
    self.display_logging(extract_filename(mp3_file), None)
    # start subprocess
    try:
        p = subprocess.Popen(["mp3gain", mp3_file],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")

        return None

    # search for success msg, if not found: -1
    mp3gain_no_file = string.find(p[1], "Can't open")
    #mp3gain_output_2 = string.find(p[1], "99%")
    #mp3gain_output_1 = string.find(p[1], "written")
    #self.display_logging(p[1], None)
    #self.display_logging(mp3gain_output_1)
    # wenn gefunden, position, sonst -1
    if mp3gain_no_file != -1:
        self.display_logging("File skipped...", "r")


def trim_and_recode(self, mp3_file_temp, mp3_file_mod):
    """trim silence and recode with sox"""
    compression_and_quality = (str(ac.app_mp3_bitrate) + "."
                                + str(ac.app_mp3_encode_quality))
    try:
        #subprocess.Popen(["sox", mp3_file_temp, "-C", "192.2", mp3_file_mod,
        subprocess.Popen(["sox", mp3_file_temp,
                "-C", compression_and_quality, mp3_file_mod,
                "silence", "1", "0.1", "1%", "reverse",
                "silence", "1", "0.1", "1%", "reverse"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
        return True
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")
        return None


def trim_silence(self, mp3_file_temp, dir_mod):
    """trim_silence and save and rewrite ID3Tags

    Info about rewriting id3tags:
    After editing the file with sox,
    the present id3tags are written in id3v2.3 with wrong encodings
    therefor we save and rewrite the necessary tags in v2.4
    by this action we trash all additional tags"""

    print u"mp3-File trim silence"
    #self.display_logging("\nTrim silence and editing tags for:", None)
    self.display_logging(extract_filename(mp3_file_temp), None)
    try:
        audio = MP3(mp3_file_temp)
        mp3_length = audio.info.length
        mp3_bitrate = audio.info.bitrate / 1000
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")

    if mp3_bitrate < ac.app_mp3_bitrate:
        self.display_logging(self.msg[20], "r")
        ac.log_message_summary_bitrate.append(
                                extract_filename(mp3_file_temp))
        return None

    # store id3 tags in ac for later restore in file
    author, title = save_id3_tags(self, mp3_file_temp)
    # decode needed for pathnames with non ascii
    mp3_file_mod = (dir_mod.decode(sys.getfilesystemencoding())
                            + "/" + extract_filename(mp3_file_temp))
    #self.display_logging(mp3_file)
    #self.display_logging(mp3_file_mod)
    #sox "$file_path_orig" -C 192.2 "$file" silence 1 0.1 1% reverse
    #silence 1 0.1 1% reverse

    # start subprocesses
    if mp3_bitrate > ac.app_mp3_bitrate:
        # trim silence with recode to bitrate
        success = trim_and_recode(self, mp3_file_temp, mp3_file_mod)
        if success is not True:
            return None
    else:
        # trim silence lossless without recode
        subprocess.Popen(["mp3splt", mp3_file_temp, "-r"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
        filename_trimmed = os.path.basename(mp3_file_temp)
        filename_trimmed = (filename_trimmed[:
                    string.rfind(filename_trimmed, ".mp3")] + "_trimmed.mp3")
        mp3_file_temp = os.path.dirname(mp3_file_temp) + "/" + filename_trimmed
        shutil.copy(mp3_file_temp, mp3_file_mod)
        self.display_logging(self.msg[21] +
                                extract_filename(mp3_file_mod), None)

    # check if length is different between orig and edited file
    try:
        audio = MP3(mp3_file_mod)
        mp3_length_trimmed = audio.info.length
        #self.display_logging(str(math.modf(mp3_length)[1]))
        #self.display_logging(str(math.modf(mp3_length_trimmed)[1]))
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")
        return None

    # compare length with full seconds, no milliseconds
    if math.modf(mp3_length)[1] == math.modf(mp3_length_trimmed)[1]:
        #self.display_logging("No trimming necessary...", None)
        # no change in length, copy audio from orig to mod
        try:
            shutil.copy(mp3_file_temp, mp3_file_mod)
            ac.log_message_summary_no_silence.append(
                                extract_filename(mp3_file_temp))
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")
    else:
        if ((math.modf(mp3_length)[1] - ac.app_max_length_diff) >
            math.modf(mp3_length_trimmed)[1]):
            ac.log_message_summary_max_length_diff.append(
                                extract_filename(mp3_file_temp))

    write_id3_tags(self, mp3_file_mod, author, title)
    #self.display_logging(p)


def save_id3_tags(self, mp3_file):
    """read_id3_tag"""
    author = None
    title = None
    #self.display_logging("Save tags...")
    try:
        mp3_meta = ID3(mp3_file)
        tags = mp3_meta.pprint().splitlines()

        for tag in tags:
            #print tag
            if tag[:4] == "TPE1":
                author = tag[5:]
                #print author
            if tag[:4] == "TIT2":
                title = tag[5:]
                #print title

    except ID3NoHeaderError:
        self.display_logging("No ID3V2 tag present...", "r")
        ac.log_message_summary_id3tag.append(
                                extract_filename(mp3_file))
    return author, title


def write_id3_tags(self, mp3_file, author, title):
    """read_id3_tag"""
    if author is None and title is None:
        # add empty tags
        author = "unknown author"
        title = "unknown title"

    #self.display_logging("Write tags...")
    try:
        mp3_meta = ID3(mp3_file)
        mp3_meta.delete()
        mp3_meta.add(TPE1(encoding=3, text=author))
        mp3_meta.add(TIT2(encoding=3, text=title))
        mp3_meta.save()
    except ID3NoHeaderError:
        self.display_logging("No tag present...", "r")
        try:
            mp3_meta = mutagen.File(mp3_file, easy=True)
            mp3_meta.add_tags()
            mp3_meta.save()

            try:
                mp3_meta = ID3(mp3_file)
                mp3_meta.add(TPE1(encoding=3, text=author))
                mp3_meta.add(TIT2(encoding=3, text=title))
                mp3_meta.save()
            except Exception, e:
                self.display_logging("%s" % str(e), None)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")

    try:
        ape_meta = APEv2(mp3_file)
        ape_meta.delete()
    except Exception, e:
            self.display_logging("%s" % str(e), None)


class my_form(Frame):
    """Form"""
    def __init__(self, master=None):
        """create elements of form"""
        Frame.__init__(self, master)
        self.pack()
        #self.createWidgets()

        self.textBox = ScrolledText(self, height=15, width=100)
        self.textBox.pack()
        self.textBox.tag_config("b", foreground="blue")
        self.textBox.tag_config("r", foreground="red")
        # insert the msg from lets_rock will display when finished,
        # that's to late
        if os.getenv('LANG')[0:2] == "de":
            self.textBox.insert(END,
                "Es kann eine Weile dauern, "
                + "vielleicht eine Tasse Kaffee geniessen...")
        else:
            self.textBox.insert(END,
            "Working, this can take a while, enjoy a cup of coffee...\n")
        self.pressButton = Button(self,
                text="ID3 easyTAG Editor", command=self.call_id3_editor)
        # the button will appear when finished
        #self.pressButton.pack()

        # registering callback
        self.listenID = self.after(400, self.lets_rock)
        #self.listenID = self.lets_rock

    def display_logging(self, log_message, text_format):
        """display messages in form, loading periodically """
        if text_format is None:
            self.textBox.insert(END, log_message + "\n")
        else:
            self.textBox.insert(END, log_message + "\n", text_format)

    def call_id3_editor(self):
        self.textBox.insert(END, "Click" + "\n")
        # start subprocess
        try:
            subprocess.Popen(["easytag", ac.app_workin_path],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")

        return None

    def lets_rock(self):
        """man funktion"""
        print "lets rock"
        switch_lang(self)
        #self.display_logging(self.msg[1], None)

        # check packages
        check_package = True
        check_package = check_packages(self,
                                ["sox", "mp3gain", "mp3splt", "easytag"])
        if check_package is None:
            return

        # check options
        mp3_bitrate_options = [192, 256, 320]
        mp3_bitrate_option_valid = None

        for b in mp3_bitrate_options:
            if ac.app_mp3_bitrate == b:
                mp3_bitrate_option_valid = True

        if mp3_bitrate_option_valid is None:
            self.display_logging(self.err[3] + str(ac.app_mp3_bitrate), "r")
            self.display_logging(self.err[4], None)
            return

        mp3_encode_quality_options = [99, 1, 2, 3, 4, 5, 6]
        mp3_encode_quality_option_valid = None

        for b in mp3_encode_quality_options:
            if ac.app_mp3_encode_quality == b:
                mp3_encode_quality_option_valid = True

        if mp3_encode_quality_option_valid is None:
            self.display_logging(self.err[5] + str(ac.app_mp3_encode_quality),
                                    "r")
            self.display_logging(self.err[6], None)
            return

        try:
            path_files = (
                os.environ['NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'].splitlines())
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")
            self.display_logging(self.err[7], None)
            return

        workin_path = os.path.dirname(path_files[0])
        ac.app_workin_path = os.path.dirname(path_files[0])
        #for char in workin_path:
        #    if ord(char) > 128:
        #        self.display_logging(
        #            "\nThe filepath contains non ASCII charakters. "
        #            + "Sorry, until now, we can not proceed here. "
        #            + "But you can rename the filepath an try again..",
        #                            "r")
        #        return

        self.display_logging(self.msg[2], None)
        self.display_logging(os.path.dirname(path_files[0]), None)
        self.display_logging(self.msg[3], None)
        mp3_files = []
        for item in path_files:
            if string.rfind(item, ".mp3") == -1:
                # no mp3:
                continue
            mp3_files.append(item)
            self.display_logging(extract_filename(item), "b")
        #    if os.path.isdir(p):
        #        print p
        #        self.display_logging(p, "")

        # check for mp3 files
        if len(mp3_files) == 0:
            self.display_logging(self.err[8], "r")
            self.display_logging(self.msg[4], None)
            return

        # filename hack
        mp3_filenames_temp, mp3_filenames_mod, dir_temp, dir_mod = (
                            check_and_mod_filenames(self, mp3_files))
        #return
        # trim silence, save tags
        self.display_logging(self.msg[5], None)
        for item in mp3_filenames_temp:
            trim_silence(self, item, dir_mod)

        # mp3Gain
        self.display_logging(self.msg[6], None)
        for item in mp3_filenames_mod:
            mp3gain(self, item)
            #self.display_logging(extract_filename(item), None)
            #self.display_logging(item)

        # ID3
        #self.display_logging("\nID3Tags editing, this will be fast...")
        #for item in mp3_filenames_mod:
        #    delete_id3tag_v1(self, item)
        #    self.display_logging(extract_filename(item))

        # remove dir_temp
        try:
            shutil.rmtree(dir_temp)
            self.display_logging(self.msg[7], None)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), None)

        # move audio files in root, remove dir_mod
        try:
            for _file in os.listdir(dir_mod):
                shutil.move(dir_mod + "/" + _file, workin_path)
            shutil.rmtree(dir_mod)
            self.display_logging(self.msg[8], None)
        except Exception, e:
            ac.log_message_summary_not_moved = True
            self.display_logging("Error: %s" % str(e), "r")

        # display summary if necessary
        if (len(ac.log_message_summary_bitrate) != 0
            or len(ac.log_message_summary_id3tag) != 0
            or len(ac.log_message_summary_no_silence) != 0):
                self.display_logging(self.msg[9], "b")

        if len(ac.log_message_summary_bitrate) != 0:
            self.display_logging(self.msg[10], "r")
            for item in ac.log_message_summary_bitrate:
                self.display_logging(item, None)

        if len(ac.log_message_summary_id3tag) != 0:
            self.display_logging(self.msg[11], "r")
            for item in ac.log_message_summary_id3tag:
                self.display_logging(item, None)

        if len(ac.log_message_summary_no_silence) != 0:
            self.display_logging(self.msg[12], "r")
            for item in ac.log_message_summary_no_silence:
                self.display_logging(item, None)

        if len(ac.log_message_summary_max_length_diff) != 0:
            msg = self.msg[22] + str(ac.app_max_length_diff) + self.msg[23]
            self.display_logging(msg, "r")
            for item in ac.log_message_summary_max_length_diff:
                self.display_logging(item, None)

        if ac.log_message_summary_not_moved is True:
            self.display_logging(self.msg[13], "r")

        self.display_logging(self.msg[14], None)
        self.textBox.see(END)

        # Button for calling easyTAG editor
        #self.pressButton.pack()


if __name__ == "__main__":
    print "audio archiver started"
    #check_libs()
    ac = app_config()
    mything = my_form()
    mything.master.title("Audio Archiver")
    mything.mainloop()
    print "lets_lay_down"
    sys.exit()

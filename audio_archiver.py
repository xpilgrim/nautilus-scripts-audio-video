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
    - Trim silence on the beginning and the end of a mp3
    - Reduce ID3V2-Tags to author an title, remove ID3V1 Tags, write ID3V2.4
    - register mp3Gain in the APE-Tag

Depends on:
    Python, Tkinter, sox, mp3gain, python-mutagen
Install additional packages with:
    sudo apt-get install python-tk sox mp3gain python-mutagen
"""

from Tkinter import Frame, END
from ScrolledText import ScrolledText
import os
import shutil
import sys
import subprocess
import string
import re
import datetime
import math
from mutagen.id3 import ID3, TPE1, TIT2
from mutagen.id3 import ID3NoHeaderError
from mutagen.apev2 import APEv2
from mutagen.mp3 import MP3


class app_config(object):
    """Application-Config"""
    def __init__(self):
        """Settings"""
        # app_config
        self.app_desc = u"Audio Archiver"
        # for normal usage set to no!!!!!!
        self.app_windows = "no"
        self.app_errorfile = "error_audio_archiver.log"


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
    self.display_logging("\nOriginal files will be saved in:", None)
    #self.display_logging(datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S"))
    dir_orig = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_orig")
    self.display_logging(dir_orig, None)

    self.display_logging("\nTemp files will be saved in:", None)
    #self.display_logging(datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S"))
    dir_temp = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_temp")
    self.display_logging(dir_temp, None)

    self.display_logging("\nModified files will be saved in:", None)
    dir_mod = (os.path.dirname(mp3_files[0]) + "/audio_archiver_"
            + datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S") + "_mod")
    self.display_logging(dir_mod, None)
    try:
        os.mkdir(dir_orig)
        os.mkdir(dir_temp)
        os.mkdir(dir_mod)
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")

    self.display_logging("\nBackup files, check filenames...", None)
    # backup in orig
    for item in mp3_files:
        file_destination = dir_orig + "/" + extract_filename(item)
        #self.display_logging(extract_filename(item) + "\n")
        try:
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
            self.display_logging("\nModified filename:", None)
            self.display_logging(filename_mod, "b")

        # concatenate path and filename
        path_file_temp = dir_temp + "/" + filename_mod
        path_file_mod = dir_mod + "/" + filename_mod
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
    # start subprocess
    try:
        subprocess.Popen(["mp3gain", "-r", mp3_file],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")

        return None

    # search for success msg, if not found: -1
    #mp3gain_output = string.find(p[1], "98%")
    #mp3gain_output_2 = string.find(p[1], "99%")
    #mp3gain_output_1 = string.find(p[1], "written")
    #self.display_logging(p[1])
    #self.display_logging(mp3gain_output_1)
    # wenn gefunden, position, sonst -1
    #if (mp3gain_output != -1 and mp3gain_output_1 != -1
    #and mp3gain_output_2 != -1):
    self.display_logging("\nmp3gain for: ", None)


def trim_silence(self, mp3_file_temp, dir_mod):
    """trim_silence and save and rewrite ID3Tags

    Info about rewriteing id3tags:
    After editing the file with sox,
    the present id3tags are written in id3v2.3 with wrong encodings
    therefor we save and rewrite the necessary tags in v2.4
    by this action we trash all additional tags"""

    print u"mp3-File trim silence"
    self.display_logging("\nTrim silence and editing tags for:", None)
    self.display_logging(extract_filename(mp3_file_temp), None)
    try:
        audio = MP3(mp3_file_temp)
        mp3_length = audio.info.length
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")

    author, title = save_id3_tags(self, mp3_file_temp)
    mp3_file_mod = dir_mod + "/" + extract_filename(mp3_file_temp)
    #self.display_logging(mp3_file)
    #self.display_logging(mp3_file_mod)
    #sox "$file_path_orig" -C 192.2 "$file" silence 1 0.1 1% reverse
    #silence 1 0.1 1% reverse
    # start subprocess
    try:
        subprocess.Popen(["sox", mp3_file_temp, "-C", "192.2", mp3_file_mod,
        "silence", "1", "0.1", "1%", "reverse",
        "silence", "1", "0.1", "1%", "reverse"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")
        return None

    try:
        audio = MP3(mp3_file_mod)
        mp3_length_trimmed = audio.info.length
        #self.display_logging(str(math.modf(mp3_length)[1]))
        #self.display_logging(str(math.modf(mp3_length_trimmed)[1]))
    except Exception, e:
        self.display_logging("Error: %s" % str(e), "r")
        return None

    if math.modf(mp3_length)[1] == math.modf(mp3_length_trimmed)[1]:
        self.display_logging("No trimming necessary...", None)
        # no change in length, copy audio from orig to mod
        try:
            shutil.copy(mp3_file_temp, mp3_file_mod)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")

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
    return author, title


def write_id3_tags(self, mp3_file, author, title):
    """read_id3_tag"""
    if author is None and title is None:
        return
    #self.display_logging("Write tags...")
    try:
        try:
            mp3_meta = ID3(mp3_file)
            mp3_meta.delete()

            mp3_meta.add(TPE1(encoding=3, text=author))
            mp3_meta.add(TIT2(encoding=3, text=title))
            mp3_meta.save()
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")
    except ID3NoHeaderError:
        self.display_logging("No tag present...", "r")

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
        self.textBox.insert(END,
        "Work on audio files, this can take a while, take a cup of coffee...\n")

        # registering callback
        self.listenID = self.after(400, self.lets_rock)
        #self.listenID = self.lets_rock

    def display_logging(self, log_message, text_format):
        """display messages in form, loading periodically """
        if text_format is None:
            self.textBox.insert(END, log_message + "\n")
        else:
            self.textBox.insert(END, log_message + "\n", text_format)

    def lets_rock(self):
        """man funktion"""
        print "lets rock"
        #log_data = None
        try:
            path_files = (
                os.environ['NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'].splitlines())
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")
        self.display_logging("\nDirectory to work in:", None)
        workin_path = os.path.dirname(path_files[0])
        self.display_logging(os.path.dirname(path_files[0]), None)
        self.display_logging("\nFiles to work on:", None)
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

        # filename hack
        mp3_filenames_temp, mp3_filenames_mod, dir_temp, dir_mod = (
                            check_and_mod_filenames(self, mp3_files))

        # trim silence, save tags
        self.display_logging("\nTrim silence, this can take a while...", None)
        for item in mp3_filenames_temp:
            trim_silence(self, item, dir_mod)

        # mp3Gain
        self.display_logging("\nmp3Gain, this can take a while...", None)
        for item in mp3_filenames_mod:
            mp3gain(self, item)
            self.display_logging(extract_filename(item), None)
            #self.display_logging(item)

        # ID3
        #self.display_logging("\nID3Tags editing, this will be fast...")
        #for item in mp3_filenames_mod:
        #    delete_id3tag_v1(self, item)
        #    self.display_logging(extract_filename(item))

        # remove dir_temp
        try:
            shutil.rmtree(dir_temp)
            self.display_logging("\nTemp Directory removed...", None)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), None)

        # move audio files in root, remove dir_mod
        try:
            for _file in os.listdir(dir_mod):
                shutil.move(dir_mod + "/" + _file, workin_path)
            shutil.rmtree(dir_mod)
            self.display_logging("\nMod Directory removed...", None)
        except Exception, e:
            self.display_logging("Error: %s" % str(e), "r")

        self.display_logging(
            "\nNow we are finished, I hope the coffee was fine?", None)

if __name__ == "__main__":
    print "audio archiver started"
    ac = app_config()
    mything = my_form()
    mything.master.title("Audio Archiver")
    mything.mainloop()
    print "lets_lay_down"
    sys.exit()
